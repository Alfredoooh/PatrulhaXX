import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Modelo de item descarregado ──────────────────────────────────────────────
class DownloadedItem {
  final String id;
  final String name;       // título legível
  final String localPath;
  final String type;       // 'video' | 'image'
  final DateTime downloadedAt;
  final int sizeBytes;
  final String? thumbUrl;  // thumbnail remota para preview
  final String? sourceUrl; // URL de origem

  DownloadedItem({
    required this.id,
    required this.name,
    required this.localPath,
    required this.type,
    required this.downloadedAt,
    required this.sizeBytes,
    this.thumbUrl,
    this.sourceUrl,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'localPath': localPath,
    'type': type, 'downloadedAt': downloadedAt.toIso8601String(),
    'sizeBytes': sizeBytes,
    if (thumbUrl != null) 'thumbUrl': thumbUrl,
    if (sourceUrl != null) 'sourceUrl': sourceUrl,
  };

  factory DownloadedItem.fromJson(Map<String, dynamic> j) => DownloadedItem(
    id: j['id'], name: j['name'], localPath: j['localPath'],
    type: j['type'], downloadedAt: DateTime.parse(j['downloadedAt']),
    sizeBytes: j['sizeBytes'] ?? 0,
    thumbUrl: j['thumbUrl'],
    sourceUrl: j['sourceUrl'],
  );
}

// ─── Modelo de download em curso ─────────────────────────────────────────────
class ActiveDownload {
  final String id;
  final String title;
  final String? thumbUrl;
  final ValueNotifier<double> progress; // 0.0 → 1.0
  final ValueNotifier<DownloadStatus> status;
  final CancelToken cancelToken;

  ActiveDownload({
    required this.id,
    required this.title,
    this.thumbUrl,
    required this.cancelToken,
  })  : progress = ValueNotifier(0.0),
        status = ValueNotifier(DownloadStatus.downloading);
}

enum DownloadStatus { downloading, done, error, cancelled }

// ─────────────────────────────────────────────────────────────────────────────
// DownloadService — singleton
// ─────────────────────────────────────────────────────────────────────────────
class DownloadService extends ChangeNotifier {
  static final DownloadService instance = DownloadService._internal();
  DownloadService._internal();

  final _dio = Dio();

  // Downloads em curso — usados pela lista de downloads activos
  final Map<String, ActiveDownload> _active = {};
  List<ActiveDownload> get activeList =>
      List.unmodifiable(_active.values.toList());
  int get activeCount => _active.length;

  // Itens já descarregados — mostrados na DownloadsPage
  List<DownloadedItem> _items = [];
  List<DownloadedItem> get items => List.unmodifiable(_items);

  // Vídeos guardados para assistir offline
  final List<String> _savedIds = []; // IDs de DownloadedItem marcados como guardados
  List<DownloadedItem> get savedVideos =>
      _items.where((i) => _savedIds.contains(i.id)).toList();

  // Notifier legado — compatibilidade com browser badge
  ValueNotifier<double> progressOf(String id) =>
      _active[id]?.progress ?? ValueNotifier(0.0);

  // ── Inicialização ──────────────────────────────────────────────────────────
  Future<void> loadSaved() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString('downloads_index');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _items = list
            .map((e) => DownloadedItem.fromJson(e as Map<String, dynamic>))
            .where((d) => File(d.localPath).existsSync())
            .toList();
      } catch (_) {}
    }
    final saved = p.getStringList('saved_ids') ?? [];
    _savedIds
      ..clear()
      ..addAll(saved);
    notifyListeners();
  }

  Future<void> _saveIndex() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('downloads_index',
        jsonEncode(_items.map((e) => e.toJson()).toList()));
    await p.setStringList('saved_ids', _savedIds);
  }

  Future<Directory> _downloadsDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/downloads');
    await dir.create(recursive: true);
    return dir;
  }

  // ── Download principal — chamado pela ExibicaoPage ─────────────────────────
  Future<void> startDownload({
    required String url,
    required String title,
    String type = 'video',
    String? thumbUrl,
    String? sourceUrl,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final cancel = CancelToken();
    final active = ActiveDownload(
      id: id, title: title, thumbUrl: thumbUrl, cancelToken: cancel);
    _active[id] = active;
    notifyListeners(); // actualiza badge imediatamente

    final dir = await _downloadsDir();
    final ext = _guessExtension(url, type);
    final safeName = title
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '_')
        .substring(0, title.length.clamp(0, 40));
    final fileName = '${safeName}_$id.$ext';
    final path = '${dir.path}/$fileName';

    try {
      await _dio.download(
        url, path,
        cancelToken: cancel,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            active.progress.value = received / total;
          }
        },
        options: Options(headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
          'Referer': sourceUrl ?? url,
        }),
      );

      final file = File(path);
      final item = DownloadedItem(
        id: id,
        name: title,
        localPath: path,
        type: type,
        downloadedAt: DateTime.now(),
        sizeBytes: file.existsSync() ? file.lengthSync() : 0,
        thumbUrl: thumbUrl,
        sourceUrl: sourceUrl,
      );
      _items.insert(0, item);
      await _saveIndex();
      active.status.value = DownloadStatus.done;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        active.status.value = DownloadStatus.cancelled;
      } else {
        active.status.value = DownloadStatus.error;
      }
      if (File(path).existsSync()) File(path).deleteSync();
    } catch (_) {
      active.status.value = DownloadStatus.error;
      if (File(path).existsSync()) File(path).deleteSync();
    } finally {
      // Remove dos activos após 3s para o utilizador ver o estado final
      await Future.delayed(const Duration(seconds: 3));
      _active.remove(id);
      notifyListeners();
    }
  }

  // ── Guardar para assistir offline (marca um item existente) ───────────────
  void toggleSaved(String id) {
    if (_savedIds.contains(id)) {
      _savedIds.remove(id);
    } else {
      _savedIds.add(id);
    }
    _saveIndex();
    notifyListeners();
  }

  bool isSaved(String id) => _savedIds.contains(id);

  // ── Apagar item descarregado ───────────────────────────────────────────────
  Future<void> delete(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) return;
    final item = _items[idx];
    if (File(item.localPath).existsSync()) File(item.localPath).deleteSync();
    _items.removeAt(idx);
    _savedIds.remove(id);
    await _saveIndex();
    notifyListeners();
  }

  // ── Remover item completado ────────────────────────────────────────────────
  Future<void> removeCompleted(String id) => delete(id);

  // ── Cancelar download activo ───────────────────────────────────────────────
  void cancel(String id) {
    _active[id]?.cancelToken.cancel('user cancelled');
  }

  // ── Legado — compatibilidade com browser_page ──────────────────────────────
  Future<DownloadedItem?> download({
    required String url,
    required String type,
    required dynamic context,
  }) async {
    await startDownload(url: url, title: url.split('/').last, type: type);
    return _items.isNotEmpty ? _items.first : null;
  }

  String _guessExtension(String url, String type) {
    final lower = url.toLowerCase().split('?').first;
    for (final ext in ['mp4', 'webm', 'ogg', 'mov', 'mkv']) {
      if (lower.endsWith('.$ext')) return ext;
    }
    for (final ext in ['jpg', 'jpeg', 'png', 'gif', 'webp']) {
      if (lower.endsWith('.$ext')) return ext;
    }
    return type == 'video' ? 'mp4' : 'jpg';
  }
}
