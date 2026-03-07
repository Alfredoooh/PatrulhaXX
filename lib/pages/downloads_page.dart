import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/download_service.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});
  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _svc = DownloadService.instance;

  @override
  Widget build(BuildContext context) {
    final items = _svc.items;
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Downloads',
            style: TextStyle(color: Colors.white, fontSize: 17,
                fontWeight: FontWeight.w600)),
      ),
      body: items.isEmpty
          ? _empty()
          : MasonryGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 3,
              crossAxisSpacing: 3,
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
              itemCount: items.length,
              itemBuilder: (_, i) => _Tile(
                item: items[i],
                onTap: () => _view(items[i]),
                onLongPress: () => _options(items[i]),
              ),
            ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.download_outlined,
          color: Colors.white.withOpacity(0.15), size: 56),
      const SizedBox(height: 12),
      Text('Sem downloads',
          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15)),
    ]),
  );

  void _view(DownloadedItem item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => _Viewer(item: item)));
  }

  void _options(DownloadedItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1C),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          _SheetBtn(icon: Icons.visibility_outlined, label: 'Ver',
              onTap: () { Navigator.pop(context); _view(item); }),
          const SizedBox(height: 8),
          _SheetBtn(icon: Icons.delete_outline_rounded, label: 'Apagar',
              destructive: true,
              onTap: () async {
                Navigator.pop(context);
                await _svc.delete(item.id);
                if (mounted) setState(() {});
              }),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final DownloadedItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _Tile({required this.item, required this.onTap, required this.onLongPress});

  double get _ratio {
    final h = item.id.hashCode.abs() % 3;
    if (h == 0) return 3 / 4;
    if (h == 1) return 2 / 3;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: isVideo ? 9 / 16 : _ratio,
          child: Stack(fit: StackFit.expand, children: [
            Container(color: Colors.white.withOpacity(0.05)),
            if (!isVideo && file.existsSync())
              Image.file(file, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _ph(isVideo)),
            if (isVideo)
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.55)),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
              )),
            Positioned(bottom: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4)),
                child: Icon(isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    color: Colors.white70, size: 12),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _ph(bool isVideo) => Container(
    color: Colors.white.withOpacity(0.05),
    child: Center(child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white24, size: 24)),
  );
}

class _Viewer extends StatelessWidget {
  final DownloadedItem item;
  const _Viewer({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black, elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(item.name, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
      ),
      body: Center(
        child: isVideo
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.videocam_rounded,
                    color: Colors.white.withOpacity(0.2), size: 64),
                const SizedBox(height: 16),
                Text('Vídeo guardado',
                    style: TextStyle(color: Colors.white.withOpacity(0.4))),
              ])
            : InteractiveViewer(
                child: Image.file(file,
                    errorBuilder: (_, __, ___) => Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white.withOpacity(0.2), size: 64)),
              ),
      ),
    );
  }
}

class _SheetBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  const _SheetBtn({required this.icon, required this.label,
      required this.onTap, this.destructive = false});

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, height: 52,
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color, fontSize: 15,
              fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
