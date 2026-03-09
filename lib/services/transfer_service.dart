import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'size': sizeBytes,
      };
}

class TransferProgress {
  final String fileName;
  final int totalBytes;
  final int sentBytes;
  final bool done;
  final bool error;

  const TransferProgress({
    required this.fileName,
    required this.totalBytes,
    required this.sentBytes,
    this.done = false,
    this.error = false,
  });

  double get fraction => totalBytes == 0 ? 0 : sentBytes / totalBytes;

  String get speedLabel {
    // calculado externamente
    return '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TransferService  —  TCP puro, sem internet, só Wi-Fi / hotspot local
// ─────────────────────────────────────────────────────────────────────────────
class TransferService {
  static final TransferService instance = TransferService._();
  TransferService._();

  static const int port = 49317;
  static const int _chunkSize = 65536; // 64 KB

  ServerSocket? _server;
  final StreamController<TransferProgress> _progressCtrl =
      StreamController<TransferProgress>.broadcast();

  Stream<TransferProgress> get progress => _progressCtrl.stream;

  // ── IP local (Wi-Fi / hotspot) ────────────────────────────────────────────
  static Future<String> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      // Prioridade: wlan, en, ap (hotspot)
      for (final priority in ['wlan', 'en0', 'en1', 'ap', 'eth']) {
        for (final iface in interfaces) {
          if (iface.name.toLowerCase().startsWith(priority)) {
            for (final addr in iface.addresses) {
              if (!addr.isLoopback) return addr.address;
            }
          }
        }
      }
      // fallback
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback) return addr.address;
        }
      }
    } catch (_) {}
    return '0.0.0.0';
  }

  // ── RECEPTOR: abre servidor TCP ───────────────────────────────────────────
  Future<String> startServer() async {
    await stopServer();
    _server = await ServerSocket.bind(
      InternetAddress.anyIPv4,
      port,
      shared: true,
    );
    _server!.listen(_handleConnection);
    return getLocalIp();
  }

  Future<void> stopServer() async {
    await _server?.close();
    _server = null;
  }

  // ── Recebe ficheiro de um socket ──────────────────────────────────────────
  Future<void> _handleConnection(Socket socket) async {
    final dir = await getApplicationDocumentsDirectory();
    final saveDir = Directory('${dir.path}/transfers');
    await saveDir.create(recursive: true);

    IOSink? sink;
    String fileName = '';
    int totalSize = 0;
    int received = 0;
    bool headerDone = false;
    final headerBuf = BytesBuilder(copy: true);

    try {
      await for (final chunk in socket) {
        if (!headerDone) {
          headerBuf.add(chunk);
          final raw = headerBuf.toBytes();
          final nlIdx = raw.indexOf(10); // '\n'
          if (nlIdx == -1) continue;

          // parse header
          final headerJson =
              json.decode(utf8.decode(raw.sublist(0, nlIdx))) as Map;
          fileName = headerJson['name'] as String;
          totalSize = headerJson['size'] as int;
          headerDone = true;

          final safe = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
          sink = File('${saveDir.path}/$safe').openWrite();

          final rest = raw.sublist(nlIdx + 1);
          if (rest.isNotEmpty) {
            sink.add(rest);
            received += rest.length;
          }
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
        fileName: fileName,
        totalBytes: totalSize,
        sentBytes: totalSize,
        done: true,
      ));
    } catch (_) {
      await sink?.close();
      _progressCtrl.add(TransferProgress(
        fileName: fileName,
        totalBytes: totalSize,
        sentBytes: received,
        error: true,
      ));
    } finally {
      socket.destroy();
    }
  }

  // ── EMISSOR: envia ficheiros para IP do receptor ──────────────────────────
  Stream<TransferProgress> sendFiles({
    required List<TransferFile> files,
    required String targetIp,
  }) async* {
    for (final tf in files) {
      final file = File(tf.localPath);
      if (!await file.exists()) continue;

      Socket? socket;
      int sent = 0;

      try {
        socket = await Socket.connect(targetIp, port,
            timeout: const Duration(seconds: 8));

        // Envia header JSON terminado com '\n'
        final header = '${json.encode(tf.toJson())}\n';
        socket.add(utf8.encode(header));

        // Envia ficheiro em chunks de 64 KB — máxima velocidade
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
        );
      } finally {
        await socket?.close();
        socket?.destroy();
      }
    }
  }

  // ── Helpers QR ────────────────────────────────────────────────────────────
  // Payload: "pxx:192.168.1.10:49317"
  static String buildQrPayload(String ip) => 'pxx:$ip:$port';

  static ({String ip, int port})? parseQrPayload(String raw) {
    try {
      final p = raw.split(':');
      if (p.length < 3 || p[0] != 'pxx') return null;
      return (ip: p[1], port: int.parse(p[2]));
    } catch (_) {
      return null;
    }
  }

  // ── Formata bytes em unidade legível ──────────────────────────────────────
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
