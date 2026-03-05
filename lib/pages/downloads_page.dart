import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import '../services/download_service.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final Map<String, String?> _thumbCache = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    DownloadService.instance.loadSaved().then((_) async {
      await _generateThumbs();
      if (mounted) setState(() => _loading = false);
    });
  }

  Future<void> _generateThumbs() async {
    final tmpDir = await getTemporaryDirectory();
    for (final item in DownloadService.instance.items) {
      if (_thumbCache.containsKey(item.id)) continue;
      if (item.type == 'video') {
        try {
          final path = await VideoThumbnail.thumbnailFile(
            video: item.localPath,
            thumbnailPath: tmpDir.path,
            imageFormat: ImageFormat.JPEG,
            quality: 70,
            timeMs: 1000,
          );
          _thumbCache[item.id] = path;
        } catch (_) {
          _thumbCache[item.id] = null;
        }
      } else {
        _thumbCache[item.id] = item.localPath;
      }
    }
  }

  Future<void> _delete(String id) async {
    await DownloadService.instance.delete(id);
    _thumbCache.remove(id);
    if (mounted) setState(() {});
  }

  String _formatSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final items = DownloadService.instance.items;

    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C0C0C),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Baixados',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600)),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context),
              child: Text('Limpar tudo',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.white24)))
          : items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.folder_open_rounded, color: Colors.white12, size: 52),
                  const SizedBox(height: 14),
                  Text('Nenhum ficheiro baixado',
                      style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14)),
                ]))
              : MasonryGridView.count(
                  crossAxisCount: 3,
                  mainAxisSpacing: 3,
                  crossAxisSpacing: 3,
                  padding: const EdgeInsets.all(3),
                  itemCount: items.length,
                  itemBuilder: (_, i) => _GalleryCell(
                    item: items[i],
                    thumbPath: _thumbCache[items[i].id],
                    onDelete: () => _delete(items[i].id),
                    onTap: () => _openViewer(context, items[i]),
                  ),
                ),
    );
  }

  void _openViewer(BuildContext context, DownloadedItem item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _MediaViewer(item: item),
    ));
  }

  void _confirmClearAll(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Limpar tudo?',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(height: 46,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(23)),
                child: const Center(child: Text('Cancelar',
                    style: TextStyle(color: Colors.white70)))),
            )),
            const SizedBox(width: 12),
            Expanded(child: GestureDetector(
              onTap: () async {
                Navigator.pop(context);
                for (final item in DownloadService.instance.items.toList()) {
                  await _delete(item.id);
                }
              },
              child: Container(height: 46,
                decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(23)),
                child: const Center(child: Text('Apagar tudo',
                    style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)))),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ── Gallery cell ──────────────────────────────────────────────────────────────
class _GalleryCell extends StatelessWidget {
  final DownloadedItem item;
  final String? thumbPath;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _GalleryCell({
    required this.item, required this.thumbPath,
    required this.onDelete, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget preview;

    if (thumbPath != null && File(thumbPath!).existsSync()) {
      preview = Image.file(File(thumbPath!), fit: BoxFit.cover);
    } else {
      preview = Container(
        color: Colors.white.withOpacity(0.05),
        child: Center(child: Icon(
            item.type == 'video' ? Icons.videocam_outlined : Icons.image_outlined,
            color: Colors.white24, size: 28)),
      );
    }

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(children: [
          AspectRatio(aspectRatio: item.type == 'video' ? 16 / 9 : _aspectRatio(), child: preview),
          if (item.type == 'video')
            Positioned(bottom: 4, left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 14),
              ),
            ),
        ]),
      ),
    );
  }

  double _aspectRatio() {
    // Vary aspect ratios for staggered effect
    final hash = item.id.hashCode.abs() % 3;
    return hash == 0 ? 1.0 : hash == 1 ? 0.75 : 1.33;
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
            title: const Text('Apagar', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); onDelete(); },
          ),
          ListTile(
            leading: const Icon(Icons.fullscreen_rounded, color: Colors.white60),
            title: const Text('Ver em ecrã cheio', style: TextStyle(color: Colors.white)),
            onTap: () { Navigator.pop(context); onTap(); },
          ),
        ]),
      ),
    );
  }
}

// ── Full-screen media viewer ──────────────────────────────────────────────────
class _MediaViewer extends StatelessWidget {
  final DownloadedItem item;
  const _MediaViewer({required this.item});

  @override
  Widget build(BuildContext context) {
    final file = File(item.localPath);
    final exists = file.existsSync();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Center(
        child: !exists
            ? Text('Ficheiro não encontrado',
                style: TextStyle(color: Colors.white.withOpacity(0.3)))
            : item.type == 'image'
                ? InteractiveViewer(
                    child: Image.file(file, fit: BoxFit.contain),
                  )
                : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.videocam_outlined, color: Colors.white24, size: 64),
                    const SizedBox(height: 16),
                    Text(item.name,
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('Usa um player externo para ver o vídeo',
                        style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12)),
                  ]),
      ),
    );
  }
}
