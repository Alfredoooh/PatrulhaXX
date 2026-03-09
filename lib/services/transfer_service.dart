import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_p2p_connection/flutter_p2p_connection.dart';

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
  double get fraction =>
      totalBytes == 0 ? 0 : (sentBytes / totalBytes).clamp(0.0, 1.0);
}

enum TransferState {
  idle,
  requestingPermission,
  startingHotspot,
  hotspotReady,
  connectingToHotspot,
  connected,
  transferring,
  done,
  error,
}

// ─────────────────────────────────────────────────────────────────────────────
// TransferService
//
// Usa flutter_p2p_connection (Wi-Fi Direct nativo Android API 26+)
// — substitui wifi_iot que está descontinuado
//
// RECETOR  (Host):
//   1. Pede permissões P2P + storage + bluetooth
//   2. FlutterP2pHost cria grupo Wi-Fi Direct (hotspot automático pelo SO)
//   3. Obtém SSID + PSK do grupo e expõe via BLE advertising
//   4. Abre servidor TCP na porta 49317, recebe ficheiros
//
// EMISSOR (Client):
//   1. FlutterP2pClient descobre o host via BLE  OU  usa SSID+PSK do QR
//   2. Liga-se ao grupo Wi-Fi Direct
//   3. Conecta TCP ao groupOwnerAddress e envia ficheiros em chunks 64 KB
// ─────────────────────────────────────────────────────────────────────────────
class TransferService {
  static final TransferService instance = TransferService._();
  TransferService._();

  static const int _port = 49317;
  static const int _chunkSize = 65536; // 64 KB

  // ── Streams públicos ────────────────────────────────────────────────────────
  final _stateCtrl    = StreamController<TransferState>.broadcast();
  final _progressCtrl = StreamController<TransferProgress>.broadcast();
  Stream<TransferState>    get stateStream => _stateCtrl.stream;
  Stream<TransferProgress> get progress    => _progressCtrl.stream;

  TransferState _state = TransferState.idle;

  // ── Instâncias P2P ──────────────────────────────────────────────────────────
  final _host   = FlutterP2pHost();
  final _client = FlutterP2pClient();

  // ── Estado do hotspot ────────────────────────────────────────────────────────
  String _ssid     = '';
  String _password = '';
  String get hotspotSsid     => _ssid;
  String get hotspotPassword => _password;

  ServerSocket? _server;
  StreamSubscription? _serverSub;

  void _setState(TransferState s) { _state = s; _stateCtrl.add(s); }

  // ─────────────────────────────────────────────────────────────────────────────
  // RECETOR — cria grupo Wi-Fi Direct e servidor TCP
  // ─────────────────────────────────────────────────────────────────────────────
  Future<({String ssid, String password})> startReceiver() async {
    _setState(TransferState.requestingPermission);

    // Pede todas as permissões necessárias
    if (!await _host.checkP2pPermissions())     await _host.askP2pPermissions();
    if (!await _host.checkStoragePermission())  await _host.askStoragePermission();
    if (!await _host.checkBluetoothPermissions()) await _host.askBluetoothPermissions();

    // Garante Wi-Fi e localização ativos
    if (!await _host.checkWifiEnabled())       await _host.enableWifiServices();
    if (!await _host.checkLocationEnabled())   await _host.enableLocationServices();

    _setState(TransferState.startingHotspot);

    // Cria o grupo Wi-Fi Direct — o SO gera SSID e PSK automaticamente
    final hotspotInfo = await _host.createGroup();

    if (hotspotInfo == null) {
      _setState(TransferState.error);
      throw Exception(
          'Não foi possível criar o grupo Wi-Fi Direct.\n'
          'Verifica se o Wi-Fi está ativo e as permissões concedidas.');
    }

    _ssid     = hotspotInfo.ssid;
    _password = hotspotInfo.passphrase;

    // Inicia servidor TCP
    await _startServer();

    // Anuncia credenciais via BLE para que o emissor descubra sem QR
    await _host.startBleAdvertising();

    _setState(TransferState.hotspotReady);
    return (ssid: _ssid, password: _password);
  }

  Future<void> _startServer() async {
    await _server?.close();
    await _serverSub?.cancel();
    _server    = await ServerSocket.bind(InternetAddress.anyIPv4, _port, shared: true);
    _serverSub = _server!.listen(_handleConnection);
  }

  Future<void> stopReceiver() async {
    await _host.stopBleAdvertising();
    await _host.removeGroup();
    await _server?.close();
    _server = null;
    await _serverSub?.cancel();
    _serverSub = null;
    _setState(TransferState.idle);
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // RECETOR — processa ligação TCP e grava ficheiro
  // ─────────────────────────────────────────────────────────────────────────────
  Future<void> _handleConnection(Socket socket) async {
    final dir     = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/transfers');
    await saveDir.create(recursive: true);

    IOSink? sink;
    String fileName  = '';
    int totalSize    = 0;
    int received     = 0;
    bool headerDone  = false;
    final buf        = BytesBuilder(copy: true);

    _setState(TransferState.transferring);

    try {
      await for (final chunk in socket) {
        if (!headerDone) {
          buf.add(chunk);
          final raw = buf.toBytes();
          final nl  = _indexOfNewline(raw);
          if (nl == -1) continue;

          final header = json.decode(utf8.decode(raw.sublist(0, nl))) as Map;
          fileName  = header['name'] as String;
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
          fileName:   fileName,
          totalBytes: totalSize,
          sentBytes:  received,
          done:       received >= totalSize && totalSize > 0,
        ));
      }

      await sink?.flush();
      await sink?.close();
      _progressCtrl.add(TransferProgress(
        fileName: fileName, totalBytes: totalSize,
        sentBytes: totalSize, done: true));
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

  // ─────────────────────────────────────────────────────────────────────────────
  // EMISSOR — descobre host e envia ficheiros
  // ─────────────────────────────────────────────────────────────────────────────

  /// Liga ao host via BLE discovery (automático, sem QR).
  /// O utilizador só precisa de estar perto — o plugin descobre o host via BLE.
  Future<bool> connectViaBleScan() async {
    _setState(TransferState.requestingPermission);

    if (!await _client.checkP2pPermissions())       await _client.askP2pPermissions();
    if (!await _client.checkBluetoothPermissions()) await _client.askBluetoothPermissions();
    if (!await _client.checkWifiEnabled())          await _client.enableWifiServices();
    if (!await _client.checkLocationEnabled())      await _client.enableLocationServices();

    _setState(TransferState.connectingToHotspot);

    try {
      // Inicia scan BLE — o stream emite cada host encontrado
      await _client.startBleScan();

      // Espera até 15 s pelo primeiro host
      final hostInfo = await _client.bleDiscoveredHosts
          .firstWhere((_) => true)
          .timeout(const Duration(seconds: 15));

      await _client.stopBleScan();

      // Liga ao grupo Wi-Fi Direct do host com as credenciais recebidas via BLE
      final ok = await _client.connectToHost(
        ssid:       hostInfo.ssid,
        passphrase: hostInfo.passphrase,
      );

      if (!ok) { _setState(TransferState.error); return false; }
      _setState(TransferState.connected);
      return true;
    } catch (e) {
      await _client.stopBleScan();
      _setState(TransferState.error);
      return false;
    }
  }

  /// Liga ao host via SSID + password (lidos do QR ou inseridos manualmente).
  Future<bool> connectViaCredentials({
    required String ssid,
    required String password,
  }) async {
    _setState(TransferState.requestingPermission);

    if (!await _client.checkP2pPermissions())  await _client.askP2pPermissions();
    if (!await _client.checkWifiEnabled())     await _client.enableWifiServices();
    if (!await _client.checkLocationEnabled()) await _client.enableLocationServices();

    _setState(TransferState.connectingToHotspot);

    try {
      final ok = await _client.connectToHost(
        ssid:       ssid,
        passphrase: password,
      );

      if (!ok) { _setState(TransferState.error); return false; }
      _setState(TransferState.connected);
      return true;
    } catch (e) {
      _setState(TransferState.error);
      return false;
    }
  }

  /// Envia ficheiros para o host depois de conectado.
  /// O IP do owner do grupo Wi-Fi Direct é obtido via [_client.groupOwnerAddress].
  Stream<TransferProgress> sendFiles({
    required List<TransferFile> files,
    String? targetIp,
  }) async* {
    // Resolve o IP do host (groupOwner do Wi-Fi Direct)
    String ip = targetIp ?? await _resolveGroupOwnerIp();

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
            fileName:   tf.name,
            totalBytes: tf.sizeBytes,
            sentBytes:  sent,
          );
        }

        await socket.flush();
        yield TransferProgress(
          fileName:   tf.name,
          totalBytes: tf.sizeBytes,
          sentBytes:  tf.sizeBytes,
          done: true,
        );
      } catch (e) {
        yield TransferProgress(
          fileName:   tf.name,
          totalBytes: tf.sizeBytes,
          sentBytes:  sent,
          error:      true,
          errorMsg:   e.toString(),
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

  Future<void> disconnectClient() async {
    await _client.disconnect();
    _setState(TransferState.idle);
  }

  /// Resolve o IP do groupOwner — num grupo Wi-Fi Direct é o IP do recetor (host)
  Future<String> _resolveGroupOwnerIp() async {
    try {
      final addr = await _client.groupOwnerAddress;
      if (addr != null && addr.isNotEmpty && addr != '0.0.0.0') return addr;
    } catch (_) {}
    // Fallback: IP típico do groupOwner em Wi-Fi Direct
    return '192.168.49.1';
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers públicos
  // ─────────────────────────────────────────────────────────────────────────────

  /// Formata bytes em unidade legível
  static String formatBytes(int bytes) {
    if (bytes < 1024)             return '$bytes B';
    if (bytes < 1024 * 1024)     return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Payload do QR — formato: "pxx:SSID:PASSWORD"
  static String buildQrPayload(String ssid, String password) =>
      'pxx:$ssid:$password';

  /// Parse do QR payload
  static ({String ssid, String password})? parseQrPayload(String raw) {
    try {
      if (!raw.startsWith('pxx:')) return null;
      final parts = raw.split(':');
      if (parts.length < 3) return null;
      return (ssid: parts[1], password: parts.sublist(2).join(':'));
    } catch (_) { return null; }
  }
}
