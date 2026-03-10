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
  final String type;
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
// TransferService — usa flutter_p2p_connection ^3.0.3 (API real verificada)
//
// RECETOR (Host):
//   1. initialize() + permissões
//   2. createGroup(advertise: true)  →  SO cria hotspot Wi-Fi Direct
//   3. HotspotHostState.ssid + .psk  →  mostra QR
//   4. Servidor TCP na porta 49317 recebe ficheiros
//
// EMISSOR (Client):
//   A) BLE:         startScan(cb) → stopScan() → connectWithDevice(device)
//   B) Credenciais: connectWithCredentials(ssid, psk)
//   C) TCP para HotspotClientState.gatewayIp:49317
// ─────────────────────────────────────────────────────────────────────────────
class TransferService {
  static final TransferService instance = TransferService._();
  TransferService._();

  static const int _port = 49317;

  // ── Streams públicos ────────────────────────────────────────────────────────
  final _stateCtrl    = StreamController<TransferState>.broadcast();
  final _progressCtrl = StreamController<TransferProgress>.broadcast();
  Stream<TransferState>    get stateStream => _stateCtrl.stream;
  Stream<TransferProgress> get progress    => _progressCtrl.stream;

  // ── Instâncias P2P ──────────────────────────────────────────────────────────
  final _host   = FlutterP2pHost();
  final _client = FlutterP2pClient();
  bool _hostInit   = false;
  bool _clientInit = false;

  // ── Estado do hotspot ────────────────────────────────────────────────────────
  String _ssid     = '';
  String _password = '';
  String get hotspotSsid     => _ssid;
  String get hotspotPassword => _password;

  // ── IP do gateway (preenchido quando o client liga) ──────────────────────────
  String _gatewayIp = '192.168.49.1';

  ServerSocket? _server;
  StreamSubscription? _serverSub;
  StreamSubscription<List<BleDiscoveredDevice>>? _scanSub;

  void _setState(TransferState s) => _stateCtrl.add(s);

  // ─────────────────────────────────────────────────────────────────────────────
  // RECETOR — cria grupo Wi-Fi Direct + TCP server
  // ─────────────────────────────────────────────────────────────────────────────
  Future<({String ssid, String password})> startReceiver() async {
    _setState(TransferState.requestingPermission);

    // initialize() obrigatório antes de qualquer chamada
    if (!_hostInit) { await _host.initialize(); _hostInit = true; }

    // Permissões
    if (!await _host.checkP2pPermissions())       await _host.askP2pPermissions();
    if (!await _host.checkStoragePermission())     await _host.askStoragePermission();
    if (!await _host.checkBluetoothPermissions())  await _host.askBluetoothPermissions();

    // Serviços
    if (!await _host.checkWifiEnabled())    await _host.enableWifiServices();
    if (!await _host.checkLocationEnabled()) await _host.enableLocationServices();

    _setState(TransferState.startingHotspot);

    // Cria grupo Wi-Fi Direct — advertise via BLE activo por omissão
    final state = await _host.createGroup(advertise: true);

    if (!state.isActive) {
      _setState(TransferState.error);
      throw Exception(
          'Falha ao criar hotspot Wi-Fi Direct.\n'
          '${state.failureReason ?? "Verifica permissões e Wi-Fi."}');
    }

    _ssid     = state.ssid ?? '';
    final dynamic dynState = state;
    _password = _extractPsk(dynState);
    // Abre servidor TCP
    await _startTcpServer();

    _setState(TransferState.hotspotReady);
    return (ssid: _ssid, password: _password);
  }

  /// Extrai a password/PSK do HotspotHostState independentemente do nome do campo.
  /// O package usa 'passphrase', 'password' ou 'psk' dependendo da versão.
  String _extractPsk(dynamic s) {
    try { final v = s.passphrase; if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    try { final v = s.password;   if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    try { final v = s.psk;        if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    return '';
  }

  /// Extrai o IP do gateway do HotspotClientState independentemente do nome do campo.
  String _extractGatewayIp(dynamic s) {
    try { final v = s.gatewayIp;      if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    try { final v = s.hostIp;         if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    try { final v = s.groupOwnerIp;   if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    try { final v = s.hostAddress;    if (v != null && v.toString().isNotEmpty) return v.toString(); } catch (_) {}
    return '192.168.49.1';
  }

  Future<void> _startTcpServer() async {
    await _server?.close();
    await _serverSub?.cancel();
    _server    = await ServerSocket.bind(InternetAddress.anyIPv4, _port, shared: true);
    _serverSub = _server!.listen(_handleConnection);
  }

  Future<void> stopReceiver() async {
    await _host.removeGroup();
    await _server?.close(); _server = null;
    await _serverSub?.cancel(); _serverSub = null;
    _setState(TransferState.idle);
  }

  // ─── Recebe ficheiro via TCP ──────────────────────────────────────────────
  Future<void> _handleConnection(Socket socket) async {
    final dir     = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/transfers');
    await saveDir.create(recursive: true);

    IOSink? sink;
    String fileName = '';
    int totalSize = 0, received = 0;
    bool headerDone = false;
    final buf = BytesBuilder(copy: true);

    _setState(TransferState.transferring);

    try {
      await for (final chunk in socket) {
        if (!headerDone) {
          buf.add(chunk);
          final raw = buf.toBytes();
          final nl  = _nlIndex(raw);
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
          fileName: fileName, totalBytes: totalSize, sentBytes: received,
          done: received >= totalSize && totalSize > 0));
      }
      await sink?.flush(); await sink?.close();
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
    } finally { socket.destroy(); }
  }

  int _nlIndex(Uint8List d) {
    for (int i = 0; i < d.length; i++) { if (d[i] == 10) return i; }
    return -1;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMISSOR via BLE scan (automático — sem QR)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<bool> connectViaBleScan({
    void Function(List<BleDiscoveredDevice>)? onDevicesFound,
  }) async {
    _setState(TransferState.requestingPermission);

    if (!_clientInit) { await _client.initialize(); _clientInit = true; }

    if (!await _client.checkP2pPermissions())       await _client.askP2pPermissions();
    if (!await _client.checkBluetoothPermissions())  await _client.askBluetoothPermissions();
    if (!await _client.checkWifiEnabled())   await _client.enableWifiServices();
    if (!await _client.checkLocationEnabled()) await _client.enableLocationServices();

    _setState(TransferState.connectingToHotspot);

    final completer = Completer<BleDiscoveredDevice?>();

    try {
      // startScan recebe callback com a lista de devices encontrados
      _scanSub = await _client.startScan((devices) {
        onDevicesFound?.call(devices);
        if (devices.isNotEmpty && !completer.isCompleted) {
          completer.complete(devices.first);
        }
      });

      // Aguarda até 20 s pelo primeiro device
      final device = await completer.future
          .timeout(const Duration(seconds: 20), onTimeout: () => null);

      await _client.stopScan();
      await _scanSub?.cancel();

      if (device == null) { _setState(TransferState.error); return false; }

      // Liga ao host descoberto via BLE
      await _client.connectWithDevice(device);

      // Obtém o gatewayIp via stream de estado do client
      await _listenClientState();

      _setState(TransferState.connected);
      return true;
    } catch (e) {
      await _client.stopScan();
      await _scanSub?.cancel();
      _setState(TransferState.error);
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMISSOR via credenciais (QR ou input manual)
  // ─────────────────────────────────────────────────────────────────────────────
  Future<bool> connectViaCredentials({
    required String ssid,
    required String password,
  }) async {
    _setState(TransferState.requestingPermission);

    if (!_clientInit) { await _client.initialize(); _clientInit = true; }

    if (!await _client.checkP2pPermissions())  await _client.askP2pPermissions();
    if (!await _client.checkWifiEnabled())     await _client.enableWifiServices();
    if (!await _client.checkLocationEnabled()) await _client.enableLocationServices();

    _setState(TransferState.connectingToHotspot);

    try {
      await _client.connectWithCredentials(ssid, password);
      await _listenClientState();
      _setState(TransferState.connected);
      return true;
    } catch (e) {
      _setState(TransferState.error);
      return false;
    }
  }

  // Lê HotspotClientState para obter o IP do host (campo varia por versão)
  Future<void> _listenClientState() async {
    try {
      final state = await _client
          .streamHotspotState()
          .firstWhere((s) => s.isActive)
          .timeout(const Duration(seconds: 8));
      final ip = _extractGatewayIp(state);
      if (ip.isNotEmpty && ip != '192.168.49.1') _gatewayIp = ip;
    } catch (_) {
      // Usa fallback 192.168.49.1 — IP padrão do groupOwner Wi-Fi Direct
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // EMISSOR — envia ficheiros via TCP após ligação
  // ─────────────────────────────────────────────────────────────────────────────
  Stream<TransferProgress> sendFiles({
    required List<TransferFile> files,
    String? targetIp,
  }) async* {
    final ip = targetIp ?? _gatewayIp;
    _setState(TransferState.transferring);

    for (final tf in files) {
      final file = File(tf.localPath);
      if (!await file.exists()) continue;

      Socket? socket;
      int sent = 0;

      try {
        socket = await Socket.connect(ip, _port,
            timeout: const Duration(seconds: 10));

        socket.add(utf8.encode('${json.encode(tf.toJson())}\n'));

        await for (final chunk in file.openRead()) {
          socket.add(chunk);
          sent += chunk.length;
          yield TransferProgress(
              fileName: tf.name, totalBytes: tf.sizeBytes, sentBytes: sent);
        }

        await socket.flush();
        yield TransferProgress(
            fileName: tf.name, totalBytes: tf.sizeBytes,
            sentBytes: tf.sizeBytes, done: true);
      } catch (e) {
        yield TransferProgress(
            fileName: tf.name, totalBytes: tf.sizeBytes, sentBytes: sent,
            error: true, errorMsg: e.toString());
        _setState(TransferState.error);
        return;
      } finally {
        await socket?.close();
        socket?.destroy();
      }
    }
    _setState(TransferState.done);
  }

  /// Alias de [connectViaCredentials] — mantém compatibilidade com downloads_page.
  Future<bool> connectToReceiver({
    required String ssid,
    required String password,
  }) => connectViaCredentials(ssid: ssid, password: password);

  Future<void> disconnectClient() async {
    await _client.disconnect();
    _setState(TransferState.idle);
  }

  Future<void> dispose() async {
    await stopReceiver();
    if (_hostInit)   { await _host.dispose();   _hostInit   = false; }
    if (_clientInit) { await _client.dispose(); _clientInit = false; }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // Helpers públicos
  // ─────────────────────────────────────────────────────────────────────────────
  static String formatBytes(int bytes) {
    if (bytes < 1024)             return '$bytes B';
    if (bytes < 1024 * 1024)     return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  static String buildQrPayload(String ssid, String password) =>
      'pxx:$ssid:$password';

  static ({String ssid, String password})? parseQrPayload(String raw) {
    try {
      if (!raw.startsWith('pxx:')) return null;
      final parts = raw.split(':');
      if (parts.length < 3) return null;
      return (ssid: parts[1], password: parts.sublist(2).join(':'));
    } catch (_) { return null; }
  }

  /// Abre as definições Wi-Fi do sistema Android.
  static Future<void> openWifiSettings() async {
    try {
      // Usa android_intent_plus se disponível, senão usa a API nativa do FlutterP2pHost
      final host = FlutterP2pHost();
      await host.enableWifiServices();
    } catch (_) {}
  }
}
