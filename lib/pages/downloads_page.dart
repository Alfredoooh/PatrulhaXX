import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/download_service.dart';
import '../models/download_item.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _svc = DownloadService.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _BlurBar(),
      body: AnimatedBuilder(
        animation: _svc,
        builder: (_, __) {
          final items = _svc.items;
          if (items.isEmpty) return _empty();
          return MasonryGridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            padding: EdgeInsets.only(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 4,
              bottom: 24,
            ),
            itemCount: items.length,
            itemBuilder: (_, i) => _Tile(
              item: items[i],
              onTap: () => _view(items[i]),
              onLongPress: () => _options(items[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.download_outlined,
          color: Colors.white.withOpacity(0.15), size: 56),
      const SizedBox(height: 12),
      Text('Sem downloads',
          style: TextStyle(color: Colors.white.withOpacity(0.3),
              fontSize: 15)),
    ]),
  );

  void _view(DownloadItem item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => _Viewer(item: item),
    ));
  }

  void _options(DownloadItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(22)),
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.white12,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          _SheetBtn(
            icon: Icons.visibility_outlined,
            label: 'Ver',
            onTap: () { Navigator.pop(context); _view(item); },
          ),
          const SizedBox(height: 8),
          _SheetBtn(
            icon: Icons.delete_outline_rounded,
            label: 'Apagar',
            destructive: true,
            onTap: () async {
              Navigator.pop(context);
              await _svc.delete(item.id);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final DownloadItem item;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _Tile({required this.item, required this.onTap, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);
    final exists = file.existsSync();

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AspectRatio(
          aspectRatio: isVideo ? 9 / 16 : _ratio(item.id),
          child: Stack(fit: StackFit.expand, children: [
            // Background
            Container(color: Colors.white.withOpacity(0.04)),

            // Image preview (only for images)
            if (!isVideo && exists)
              Image.file(file, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(isVideo)),

            // Video — show play icon overlay
            if (isVideo)
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withOpacity(0.5),
                ),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
              )),

            // Type badge
            Positioned(
              bottom: 4, right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(4)),
                child: Icon(
                    isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                    color: Colors.white70, size: 12),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder(bool isVideo) => Container(
    color: Colors.white.withOpacity(0.04),
    child: Center(child: Icon(
        isVideo ? Icons.videocam_outlined : Icons.image_outlined,
        color: Colors.white24, size: 24)),
  );

  // Staggered — alternate between ratios for visual interest
  double _ratio(String id) {
    final h = id.hashCode.abs() % 3;
    if (h == 0) return 3 / 4;
    if (h == 1) return 2 / 3;
    return 1;
  }
}

// ─── Full-screen viewer ───────────────────────────────────────────────────────
class _Viewer extends StatelessWidget {
  final DownloadItem item;
  const _Viewer({required this.item});

  @override
  Widget build(BuildContext context) {
    final isVideo = item.type == 'video';
    final file = File(item.localPath);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: isVideo
            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.videocam_rounded,
                    color: Colors.white38, size: 64),
                const SizedBox(height: 16),
                Text('Vídeo guardado',
                    style: TextStyle(color: Colors.white.withOpacity(0.4))),
                const SizedBox(height: 8),
                Text(item.localPath.split('/').last,
                    style: TextStyle(color: Colors.white.withOpacity(0.2),
                        fontSize: 11)),
              ])
            : InteractiveViewer(
                child: Image.file(file,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white24, size: 64)),
              ),
      ),
    );
  }
}

// ─── Blur AppBar ──────────────────────────────────────────────────────────────
class _BlurBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: const Color(0xFF0C0C0C).withOpacity(0.7),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Downloads',
                style: TextStyle(color: Colors.white,
                    fontSize: 17, fontWeight: FontWeight.w600)),
          ),
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

  const _SheetBtn({
    required this.icon, required this.label,
    required this.onTap, this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Colors.redAccent : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(color: color,
              fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
