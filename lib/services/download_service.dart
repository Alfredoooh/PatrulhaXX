import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadedItem {
  final String id;
  final String name;
  final String localPath;
  final String type;
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
    'id': id, 'name': name, 'localPath': localPath,
    'type': type, 'downloadedAt': downloadedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
  };

  factory DownloadedItem.fromJson(Map<String, dynamic> j) => DownloadedItem(
    id: j['id'], name: j['name'], localPath: j['localPath'],
    type: j['type'], downloadedAt: DateTime.parse(j['downloadedAt']),
    sizeBytes: j['sizeBytes'] ?? 0,
  );
}

class DownloadService {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final _dio = Dio();
  final _active = <String, CancelToken>{};
  List<DownloadedItem> _items = [];
  List<DownloadedItem> get items => List.unmodifiable(_items);

  final _progressNotifiers = <String, ValueNotifier<double>>{};
  ValueNotifier<double> progressOf(String id) =>
      _progressNotifiers.putIfAbsent(id, () => ValueNotifier(0));

  Future<void> loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('downloads_index');
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
    final p = await SharedPreferences.getInstance();
    await p.setString('downloads_index',
        jsonEncode(_items.map((e) => e.toJson()).toList()));
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
      await _dio.download(url, path,
        cancelToken: cancel,
        onReceiveProgress: (r, t) {
          if (t > 0) progressOf(id).value = r / t;
        },
        options: Options(headers: {
          'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
        }),
      );
      final file = File(path);
      final item = DownloadedItem(
        id: id, name: fileName, localPath: path, type: type,
        downloadedAt: DateTime.now(),
        sizeBytes: file.existsSync() ? file.lengthSync() : 0,
      );
      _items.insert(0, item);
      await _saveIndex();
      return item;
    } catch (_) {
      if (File(path).existsSync()) File(path).deleteSync();
      return null;
    } finally {
      _active.remove(id);
    }
  }

  Future<void> delete(String id) async {
    final item = _items.firstWhere((e) => e.id == id,
        orElse: () => throw Exception('not found'));
    if (File(item.localPath).existsSync()) File(item.localPath).deleteSync();
    _items.removeWhere((e) => e.id == id);
    await _saveIndex();
  }

  void cancel(String id) {
    _active[id]?.cancel();
    _active.remove(id);
  }

  String _guessExtension(String url, String type) {
    final lower = url.toLowerCase();
    final videoExts = ['mp4', 'webm', 'ogg', 'mov', 'mkv'];
    final imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    final exts = type == 'video' ? videoExts : imageExts;
    for (final ext in exts) { if (lower.contains('.$ext')) return ext; }
    return type == 'video' ? 'mp4' : 'jpg';
  }
}
