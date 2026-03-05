import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class DownloadedItem {
  final String id;
  final String name;
  final String localPath;
  final String type; // 'video' | 'image'
  final DateTime downloadedAt;
  final int sizeBytes;

  DownloadedItem({
    required this.id,
    required this.name,
    required this.localPath,
    required this.type,
    required this.downloadedAt,
    required this.sizeBytes,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'localPath': localPath,
        'type': type,
        'downloadedAt': downloadedAt.toIso8601String(),
        'sizeBytes': sizeBytes,
      };

  factory DownloadedItem.fromJson(Map<String, dynamic> j) => DownloadedItem(
        id: j['id'],
        name: j['name'],
        localPath: j['localPath'],
        type: j['type'],
        downloadedAt: DateTime.parse(j['downloadedAt']),
        sizeBytes: j['sizeBytes'] ?? 0,
      );
}

class DownloadService {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final _storage = const FlutterSecureStorage();
  final _dio = Dio();
  final _active = <String, CancelToken>{};

  List<DownloadedItem> _items = [];
  List<DownloadedItem> get items => List.unmodifiable(_items);

  final _progressNotifiers = <String, ValueNotifier<double>>{};
  ValueNotifier<double> progressOf(String id) =>
      _progressNotifiers.putIfAbsent(id, () => ValueNotifier(0));

  Future<void> loadSaved() async {
    final raw = await _storage.read(key: 'downloads_index');
    if (raw == null) return;
    try {
      final list = jsonDecode(raw) as List;
      _items = list
          .map((e) => DownloadedItem.fromJson(e as Map<String, dynamic>))
          .where((d) => File(d.localPath).existsSync())
          .toList();
    } catch (_) {}
  }

  Future<void> _saveIndex() async {
    final raw = jsonEncode(_items.map((e) => e.toJson()).toList());
    await _storage.write(key: 'downloads_index', value: raw);
  }

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads');
    await dir.create(recursive: true);
    return dir;
  }

  Future<DownloadedItem?> download({
    required String url,
    required String type,
    required BuildContext context,
  }) async {
    final cancel = CancelToken();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    _active[id] = cancel;

    final dir = await _downloadsDir();
    final ext = _guessExtension(url, type);
    final fileName = '${type}_$id.$ext';
    final path = '${dir.path}/$fileName';

    try {
      await _dio.download(
        url,
        path,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            progressOf(id).value = received / total;
          }
        },
        options: Options(
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      final file = File(path);
      final size = file.existsSync() ? file.lengthSync() : 0;

      final item = DownloadedItem(
        id: id,
        name: fileName,
        localPath: path,
        type: type,
        downloadedAt: DateTime.now(),
        sizeBytes: size,
      );

      _items.insert(0, item);
      await _saveIndex();
      return item;
    } catch (e) {
      if (File(path).existsSync()) File(path).deleteSync();
      return null;
    } finally {
      _active.remove(id);
    }
  }

  Future<void> delete(String id) async {
    final item = _items.firstWhere((e) => e.id == id, orElse: () => throw Exception());
    final file = File(item.localPath);
    if (file.existsSync()) file.deleteSync();
    _items.removeWhere((e) => e.id == id);
    await _saveIndex();
  }

  void cancel(String id) {
    _active[id]?.cancel();
    _active.remove(id);
  }

  String _guessExtension(String url, String type) {
    final lower = url.toLowerCase();
    final videoExts = ['mp4', 'webm', 'ogg', 'mov', 'mkv', 'avi', 'm4v'];
    final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'avif'];
    final exts = type == 'video' ? videoExts : imageExts;
    for (final ext in exts) {
      if (lower.contains('.$ext')) return ext;
    }
    return type == 'video' ? 'mp4' : 'jpg';
  }
}
