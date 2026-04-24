import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'models.dart';
import 'scraper.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const NuxxApp());
}

class NuxxApp extends StatelessWidget {
  const NuxxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NUXX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9000),
          surface: Color(0xFF1A1A1A),
        ),
        fontFamily: 'system-ui',
      ),
      home: const FeedPage(),
    );
  }
}

// ─── FEED PAGE ───────────────────────────────────────────────────────────────

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<VideoItem> _items = [];
  bool _loading = true;
  bool _empty = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _loadMore() {
    setState(() { _loading = true; _empty = false; });
    fetchAllStream().listen(
      (batch) {
        if (mounted) setState(() => _items.addAll(batch));
      },
      onDone: () {
        if (mounted) setState(() {
          _loading = false;
          _empty = _items.isEmpty;
        });
      },
      onError: (_) {
        if (mounted) setState(() { _loading = false; _empty = _items.isEmpty; });
      },
    );
  }

  void _openPlayer(VideoItem v) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PlayerPage(video: v),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      body: Column(
        children: [
          // AppBar
          Container(
            color: const Color(0xFF111111),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 14,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF222222))),
            ),
            child: const Text(
              'NUXX',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFF9000),
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
              ),
            ),
          ),
          // Feed
          Expanded(
            child: _items.isEmpty && !_loading
                ? const Center(
                    child: Text(
                      'Sem videos disponiveis',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.all(12),
                    itemCount: _items.length + (_loading ? 1 : 0),
                    itemBuilder: (ctx, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: _Spinner()),
                        );
                      }
                      return _VideoCard(
                        item: _items[i],
                        onTap: () => _openPlayer(_items[i]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── VIDEO CARD ──────────────────────────────────────────────────────────────

class _VideoCard extends StatelessWidget {
  final VideoItem item;
  final VoidCallback onTap;

  const _VideoCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final badge = kBadges[item.source] ?? item.source.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.thumb,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: const Color(0xFF222222)),
                      errorWidget: (_, __, ___) => Container(color: const Color(0xFF222222)),
                    ),
                    // Play overlay
                    Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill_rounded,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Title + meta
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          if (item.views.isNotEmpty || item.duration.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                [if (item.views.isNotEmpty) '${item.views} views', if (item.duration.isNotEmpty) item.duration].join(' · '),
                                style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── PLAYER PAGE ─────────────────────────────────────────────────────────────

class PlayerPage extends StatefulWidget {
  final VideoItem video;
  const PlayerPage({super.key, required this.video});

  @override
  State<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends State<PlayerPage> {
  VideoPlayerController? _ctrl;
  String _status = 'A extrair video...';
  bool _extracting = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _extract();
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  Future<void> _extract() async {
    setState(() { _extracting = true; _error = false; _status = 'A extrair video...'; });
    try {
      final url = await extractVideoUrl(widget.video.videoUrl);
      if (!mounted) return;
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(url));
      await ctrl.initialize();
      if (!mounted) { ctrl.dispose(); return; }
      setState(() { _ctrl = ctrl; _extracting = false; });
      ctrl.play();
    } catch (e) {
      if (mounted) setState(() { _extracting = false; _error = true; _status = 'Erro: $e'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = kLabels[widget.video.source] ?? widget.video.source;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          // Video area
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _ctrl != null && _ctrl!.value.isInitialized
                    ? VideoPlayer(_ctrl!)
                    : Container(color: Colors.black),
              ),
              // Status overlay
              if (_extracting || _error)
                Positioned.fill(
                  child: Container(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_extracting) const _Spinner(),
                        const SizedBox(height: 12),
                        Text(
                          _status,
                          style: const TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
                        ),
                        if (_error) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _extract,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFFF9000)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Tentar novamente',
                                style: TextStyle(color: Color(0xFFFF9000), fontSize: 13),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 8,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  ),
                ),
              ),
              // Video controls tap area
              if (_ctrl != null && _ctrl!.value.isInitialized)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _ctrl!.value.isPlaying ? _ctrl!.pause() : _ctrl!.play();
                      });
                    },
                  ),
                ),
            ],
          ),
          // Video controls bar
          if (_ctrl != null && _ctrl!.value.isInitialized)
            VideoProgressIndicator(
              _ctrl!,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Color(0xFFFF9000),
                bufferedColor: Color(0xFF444444),
                backgroundColor: Color(0xFF222222),
              ),
            ),
          // Info
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title.isEmpty ? 'Sem titulo' : widget.video.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: const TextStyle(
                            color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      if (widget.video.views.isNotEmpty)
                        Text(
                          '${widget.video.views} views',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                        ),
                      if (widget.video.duration.isNotEmpty)
                        Text(
                          widget.video.duration,
                          style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SPINNER ─────────────────────────────────────────────────────────────────

class _Spinner extends StatefulWidget {
  const _Spinner();

  @override
  State<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends State<_Spinner> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _ctrl,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF333333), width: 3),
        ),
        child: CustomPaint(painter: _ArcPainter()),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF9000)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromLTWH(0, 0, size.width, size.height),
      -1.57,
      1.2,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}