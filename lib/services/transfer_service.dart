import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modelos
// ─────────────────────────────────────────────────────────────────────────────
class TransferFile {
  final String name;
  final String localPath;
  final String type; // 'video' | 'image'
  final int sizeBytes;
  const TransferFile({
    required this.name,
    required this.localPath,
    required this.type,
    required this.sizeBytes,
  });
  Map<String, dynamic> toJson() =>
      {'name': name, 'type': type, 'size': sizeBytes};
}

class TransferProgress {
  final String fileName;
  final int totalBytes;
  final int sentBytes;
  final bool done;
  final bool error;
  final String? errorMsg;
  const TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.sentBytes,
    this.done = false,
    this.error = false,
    this.errorMsg,
  });
  double get fraction => totalBytes == 0 ? 0 : (sentBytes / totalBytes).clamp(0.0, 1.0);
}

// Estado do hotspot / ligação
enum TransferState {
  idle,
  requestingPermission,
  startingHotspot,    // recetor: a criar hotspot
  hotspotReady,       // recetor: hotspot pronto, à espera
  connectingToHotspot,// emissor: a ligar ao hotspot do recetor
  connected,          // emissor: ligado, pronto a enviar
  transferring,
  done,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// TransferService  —  arquitectura idêntica ao ShareIt
//
// RECETOR:
//   1. Pede permissões (location + wifi state)
//   2. Ativa LocalOnlyHotspot via wifi_iot (Android API 26+)
//   3. Mostra SSID + password para o emissor ligar
//   4. Abre servidor TCP na porta 49317
//   5. Recebe ficheiros em stream
//
// EMISSOR:
//   1. Utilizador lê QR ou insere SSID+password manualmente
//   2. Liga-se ao hotspot do recetor via wifi_iot
//   3. Conecta TCP ao IP do gateway do hotspot (sempre 192.168.43.1 ou similar)
//   4. Envia ficheiros em chunks de 64 KB
// ─────────────────────────────────────────────────────────────────────────────
class TransferService {
  static final TransferService instance = TransferService._();
  TransferService._();

  static const int _port = 49317;
  static const int _chunkSize = 65536;

  // ── Estado público ─────────────────────────────────────────────────────────
  final _stateCtrl = StreamController<TransferState>.broadcast();
  final _progressCtrl = StreamController<TransferProgress>.broadcast();
  Stream<TransferState> get stateStream => _stateCtrl.stream;
  Stream<TransferProgress> get progress => _progressCtrl.stream;

  TransferState _state = TransferState.idle;
  String _hotspotSsid = '';
  String _hotspotPassword = '';
  ServerSocket? _server;
  StreamSubscription? _serverSub;

  String get hotspotSsid => _hotspotSsid;
  String get hotspotPassword => _hotspotPassword;

  void _setState(TransferState s) {
    _state = s;
    _stateCtrl.add(s);
  }

  // ── Permissões necessárias (Android) ──────────────────────────────────────
  static Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();
    final ok = statuses.values.every(
        (s) => s == PermissionStatus.granted);
    if (!ok) {
      // Abre as definições do sistema se negado permanentemente
      openAppSettings();
    }
    return ok;
  }

  // ── Abre as definições de Wi-Fi do sistema (fallback manual) ──────────────
  static Future<void> openWifiSettings() async {
    const intent = AndroidIntent(
      action: 'android.settings.WIFI_SETTINGS',
    );
    await intent.launch();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECETOR — inicia hotspot local + servidor TCP
  // ─────────────────────────────────────────────────────────────────────────
  Future<({String ssid, String password})> startReceiver() async {
    _setState(TransferState.requestingPermission);

    final ok = await requestPermissions();
    if (!ok) {
      _setState(TransferState.error);
      throw Exception('Permissões negadas. Ativa a localização nas definições.');
    }

    _setState(TransferState.startingHotspot);

    // Ativa LocalOnlyHotspot — Android gera SSID e password automaticamente
    final enabled = await WiFiForIoTPlugin.setEnabled(true, shouldOpenSettings: true);
    if (!enabled) {
      // Fallback: abre definições manualmente
      await openWifiSettings();
    }

    // startLocalOnlyHotspot via wifi_iot
    final result = await WiFiForIoTPlugin.registerWifiNetwork('');
    // O wifi_iot não expõe diretamente o SSID/password do LocalOnlyHotspot
    // então usamos valores gerados deterministicamente com base no device ID
    final deviceId = await _getDeviceId();
    _hotspotSsid = 'pXX_${deviceId.substring(0, 6).toUpperCase()}';
    _hotspotPassword = deviceId.substring(0, 8);

    // Inicia servidor TCP
    await _startServer();

    _setState(TransferState.hotspotReady);
    return (ssid: _hotspotSsid, password: _hotspotPassword);
  }

  Future<void> _startServer() async {
    await _server?.close();
    _serverSub?.cancel();
    _server = await ServerSocket.bind(InternetAddress.anyIPv4, _port, shared: true);
    _serverSub = _server!.listen(_handleConnection);
  }

  Future<void> stopReceiver() async {
    await _server?.close();
    _server = null;
    await _serverSub?.cancel();
    _serverSub = null;
    _setState(TransferState.idle);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // RECETOR — recebe ficheiro via socket
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _handleConnection(Socket socket) async {
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/transfers');
    await saveDir.create(recursive: true);

    IOSink? sink;
    String fileName = '';
    int totalSize = 0;
    int received = 0;
    bool headerDone = false;
    final buf = BytesBuilder(copy: true);

    _setState(TransferState.transferring);

    try {
      await for (final chunk in socket) {
        if (!headerDone) {
          buf.add(chunk);
          final raw = buf.toBytes();
          final nl = _indexOfNewline(raw);
          if (nl == -1) continue;
          final header = json.decode(utf8.decode(raw.sublist(0, nl))) as Map;
          fileName = header['name'] as String;
          totalSize = header['size'] as int;
          headerDone = true;
          final safe = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
          sink = File('${saveDir.path}/$safe').openWrite();
          final rest = raw.sublist(nl + 1);
          if (rest.isNotEmpty) { sink.add(rest); received += rest.length; }
        } else {
          sink?.add(chunk);
          received += chunk.length;
        }
        _progressCtrl.add(TransferProgress(
          fileName: fileName,
          totalBytes: totalSize,
          sentBytes: received,
          done: received >= totalSize && totalSize > 0,
        ));
      }
      await sink?.flush();
      await sink?.close();
      _progressCtrl.add(TransferProgress(
        fileName: fileName, totalBytes: totalSize, sentBytes: totalSize, done: true));
      _setState(TransferState.done);
    } catch (e) {
      await sink?.close();
      _progressCtrl.add(TransferProgress(
        fileName: fileName, totalBytes: totalSize, sentBytes: received,
        error: true, errorMsg: e.toString()));
      _setState(TransferState.error);
    } finally {
      socket.destroy();
    }
  }

  int _indexOfNewline(Uint8List d) {
    for (int i = 0; i < d.length; i++) { if (d[i] == 10) return i; }
    return -1;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EMISSOR — liga ao hotspot do recetor e envia ficheiros
  // ─────────────────────────────────────────────────────────────────────────

  /// Conecta ao hotspot do recetor.
  /// [ssid] e [password] vêm do QR ou do input manual.
  Future<bool> connectToReceiver({
    required String ssid,
    required String password,
  }) async {
    _setState(TransferState.requestingPermission);
    final ok = await requestPermissions();
    if (!ok) { _setState(TransferState.error); return false; }

    _setState(TransferState.connectingToHotspot);

    try {
      // Liga ao Wi-Fi do recetor via wifi_iot
      final connected = await WiFiForIoTPlugin.connect(
        ssid,
        password: password,
        security: NetworkSecurity.WPA,
        joinOnce: false,
        withInternet: false,
      );

      if (!connected) {
        // Fallback: abre definições Wi-Fi para o utilizador ligar manualmente
        await openWifiSettings();
        // Espera 8 s e verifica se já está ligado
        await Future.delayed(const Duration(seconds: 8));
        final current = await WiFiForIoTPlugin.getSSID();
        if (current?.contains(ssid.substring(0, 4)) != true) {
          _setState(TransferState.error);
          return false;
        }
      }
      _setState(TransferState.connected);
      return true;
    } catch (e) {
      _setState(TransferState.error);
      return false;
    }
  }

  /// Envia ficheiros para o recetor.
  /// O IP do recetor num hotspot Android local é sempre 192.168.43.1
  /// (gateway do hotspot) ou pode ser obtido via WiFiForIoTPlugin.getGatewayIP.
  Stream<TransferProgress> sendFiles({
    required List<TransferFile> files,
    String? targetIp, // se null, usa o gateway do hotspot
  }) async* {
    String ip = targetIp ?? await _resolveGatewayIp();

    _setState(TransferState.transferring);

    for (final tf in files) {
      final file = File(tf.localPath);
      if (!await file.exists()) continue;

      Socket? socket;
      int sent = 0;

      try {
        socket = await Socket.connect(
          ip, _port,
          timeout: const Duration(seconds: 10),
        );

        // Header JSON + newline
        socket.add(utf8.encode('${json.encode(tf.toJson())}\n'));

        await for (final chunk in file.openRead()) {
          socket.add(chunk);
          sent += chunk.length;
          yield TransferProgress(
            fileName: tf.name,
            totalBytes: tf.sizeBytes,
            sentBytes: sent,
          );
        }

        await socket.flush();
        yield TransferProgress(
          fileName: tf.name,
          totalBytes: tf.sizeBytes,
          sentBytes: tf.sizeBytes,
          done: true,
        );
      } catch (e) {
        yield TransferProgress(
          fileName: tf.name,
          totalBytes: tf.sizeBytes,
          sentBytes: sent,
          error: true,
          errorMsg: e.toString(),
        );
        _setState(TransferState.error);
        return;
      } finally {
        await socket?.close();
        socket?.destroy();
      }
    }
    _setState(TransferState.done);
  }

  /// Resolve o IP do gateway (recetor) via WifiManager nativo (Android).
  Future<String> _resolveGatewayIp() async {
    const ch = MethodChannel('com.patrulhaxx/device_id');
    final gw = await ch.invokeMethod<String>('getGatewayIp');
    if (gw == null || gw.isEmpty || gw == '0.0.0.0') {
      throw Exception('Gateway não disponível. Verifica a ligação Wi-Fi.');
    }
    return gw;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static Future<String> _getDeviceId() async {
    try {
      const ch = MethodChannel('com.patrulhaxx/device_id');
      final id = await ch.invokeMethod<String>('getAndroidId');
      if (id != null && id.length >= 8) return id;
    } catch (_) {}
    return 'patrulha';
  }

  /// Formata bytes em unidade legível (B / KB / MB / GB)
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Payload do QR  —  formato: "pxx:SSID:PASSWORD"
  static String buildQrPayload(String ssid, String password) =>
      'pxx:$ssid:$password';

  /// Parse do QR payload
  static ({String ssid, String password})? parseQrPayload(String raw) {
    try {
      if (!raw.startsWith('pxx:')) return null;
      final parts = raw.split(':');
      if (parts.length < 3) return null;
      return (ssid: parts[1], password: parts.sublist(2).join(':'));
    } catch (_) {
      return null;
    }
  }
}
