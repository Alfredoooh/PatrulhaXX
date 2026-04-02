import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:animations/animations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_video_model.dart';
import 'home_page.dart' show iosRoute;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// ─── Detecta se o URL é um link directo de vídeo (mp4/m3u8/etc.)
// em vez de uma página de embed
bool _isDirectVideoUrl(String url) {
  if (url.isEmpty) return false;
  final lower = url.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.m3u8') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.flv') ||
      lower.endsWith('.ts');
}

// ─── SVGs ─────────────────────────────────────────────────────────────────────
const _svgSaveLater =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m14.181.207a1 1 0 0 0 -1.181.983v2.879a8.053 8.053 0 1 0 6.931 6.931h2.886'
    'a1 1 0 0 0 .983-1.181 12.047 12.047 0 0 0 -9.619-9.612zm1.819 12.793h-2.277'
    'a1.994 1.994 0 1 1 -2.723-2.723v-3.277a1 1 0 0 1 2 0v3.277a2 2 0 0 1 .723.723h2.277'
    'a1 1 0 0 1 0 2zm-13.014-8.032a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm-1.6 3.987a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.167-.8z'
    'm8.742 12.868a1 1 0 1 1 -1.17.794 1 1 0 0 1 1.167-.794z'
    'm-4.12-19.923a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm4.174-1.691a1 1 0 1 1 -1.182.771 1 1 0 0 1 1.182-.771z'
    'm-9.948 13.837a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm1.681 3.963a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm3.052 2.991a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm16.047-1.967a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.799z'
    'm-3.022 3.067a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.8z'
    'm-3.939 1.656a1 1 0 1 1 1.17-.795 1 1 0 0 1 -1.17.791z'
    'm9.659-9.756a1 1 0 1 1 -1-1 1 1 0 0 1 1 1z"/></svg>';
const _svgPlaylist =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M1,6H23a1,1,0,0,0,0-2H1A1,1,0,0,0,1,6Z"/>'
    '<path d="M23,9H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,19H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,14H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M1.707,16.245l2.974-2.974a1.092,1.092,0,0,0,0-1.542L1.707,8.755'
    'A1,1,0,0,0,0,9.463v6.074A1,1,0,0,0,1.707,16.245Z"/></svg>';
const _svgPlayNext =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M5,20c0,1.381-1.119,2.5-2.5,2.5S0,21.381,0,20s1.119-2.5,2.5-2.5S5,18.619,5,20Z"/>'
    '<path d="M20.5,14H7a2.5,2.5,0,0,1,0-5H16.728l-1.293,1.293a1,1,0,0,0,1.414,1.414'
    'l1.972-1.972a2.5,2.5,0,0,0,0-3.535L16.849.793A1,1,0,0,0,15.435,2.207L16.728,3.5H7'
    'a4.5,4.5,0,0,0,0,9H20.5a2.5,2.5,0,0,1,0,5H18a1,1,0,0,0,0,2h2.5a4.5,4.5,0,0,0,0-9Z"/></svg>';
const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M9.878,18.122a3,3,0,0,0,4.244,0l3.211-3.211A1,1,0,0,0,15.919,13.5'
    'l-2.926,2.927L13,1a1,1,0,0,0-1-1h0a1,1,0,0,0-1,1l-.009,15.408L8.081,13.5'
    'a1,1,0,0,0-1.414,1.415Z"/>'
    '<path d="M23,16h0a1,1,0,0,0-1,1v4a1,1,0,0,1-1,1H3a1,1,0,0,1-1-1V17a1,1,0,0,0-1-1H1'
    'a1,1,0,0,0-1,1v4a3,3,0,0,0,3,3H21a3,3,0,0,0,3-3V17A1,1,0,0,0,23,16Z"/></svg>';
const _svgPlay =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.492,7.969,8.967.8A4.322,4.322,0,0,0,2.735,4.344V19.667A4.294,4.294,0,0,0,7,24'
    'a4.357,4.357,0,0,0,2.232-.62l11.526-7.165a4.321,4.321,0,0,0-.266-8.246Z"/></svg>';
const _svgPause =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M6.5,0A3.5,3.5,0,0,0,3,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,6.5,0Z"/>'
    '<path d="M17.5,0A3.5,3.5,0,0,0,14,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,17.5,0Z"/></svg>';
const _svgVolOn =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.807,4.29a1,1,0,0,0-1.415,1.415,8.913,8.913,0,0,1,0,12.59'
    'a1,1,0,0,0,1.415,1.415A10.916,10.916,0,0,0,20.807,4.29Z"/>'
    '<path d="M18.1,7.291A1,1,0,0,0,16.68,8.706a4.662,4.662,0,0,1,0,6.588'
    'A1,1,0,0,0,18.1,16.709,6.666,6.666,0,0,0,18.1,7.291Z"/>'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2ZM13,21.535a10.083,10.083,0,0,1-5.371-4.08'
    'A1,1,0,0,0,6.792,17H5a3,3,0,0,1-3-3V10A3,3,0,0,1,5,7h1.8'
    'a1,1,0,0,0,.837-.453A10.079,10.079,0,0,1,13,2.465Z"/></svg>';
const _svgVolOff =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2Z"/>'
    '<path d="M22.707,8.293a1,1,0,0,0-1.414,0L20,9.586l-1.293-1.293a1,1,0,0,0-1.414,1.414'
    'L18.586,11l-1.293,1.293a1,1,0,1,0,1.414,1.414L20,12.414l1.293,1.293a1,1,0,0,0,1.414-1.414'
    'L21.414,11l1.293-1.293A1,1,0,0,0,22.707,8.293Z"/></svg>';


// ─────────────────────────────────────────────────────────────────────────────
// Shimmer unificado
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const _Shimmer({this.width, this.height, this.radius = 6});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );
}

List<Widget> _skeletonCards(int n) => List.generate(n, (_) =>
  Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
    child: Row(children: [
      _Shimmer(width: 160, height: 90, radius: 6),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Shimmer(width: double.infinity, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 120, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 80, height: 11),
      ])),
    ]),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// SVGs usados no empty state
// ─────────────────────────────────────────────────────────────────────────────
const _svgChevronLeft =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M15.5 19l-7-7 7-7" stroke="currentColor" stroke-width="2.2" '
    'stroke-linecap="round" stroke-linejoin="round" fill="none"/></svg>';

const _svgGlobe =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M12 2a10 10 0 1 0 0 20A10 10 0 0 0 12 2z" stroke="currentColor" '
    'stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M2 12h20M12 2c-2.76 3.45-4 6.9-4 10s1.24 6.55 4 10c2.76-3.45 4-6.9 4-10S14.76 5.45 12 2z" '
    'stroke="currentColor" stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

const _svgStorefront =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M3 9l1.5-6h15L21 9" stroke="currentColor" stroke-width="1.8" '
    'fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M3 9h18v1a3 3 0 0 1-6 0 3 3 0 0 1-6 0 3 3 0 0 1-6 0V9z" '
    'stroke="currentColor" stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M5 13v8h14v-8" stroke="currentColor" stroke-width="1.8" '
    'fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '</svg>';

const _svgImageBroken =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<rect x="3" y="3" width="18" height="18" rx="2" stroke="currentColor" '
    'stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<path d="M3 15l5-5 4 4 3-3 6 6" stroke="currentColor" stroke-width="1.8" '
    'fill="none" stroke-linecap="round" stroke-linejoin="round"/>'
    '<circle cx="8.5" cy="8.5" r="1.5" fill="currentColor"/>'
    '</svg>';

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — slideshow com TODAS as imagens de assets/images/ (carregamento
// dinâmico via AssetManifest — não depende de nomes hardcoded)
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyStoryViewer extends StatefulWidget {
  const _EmptyStoryViewer();
  @override State<_EmptyStoryViewer> createState() => _EmptyStoryViewerState();
}

class _EmptyStoryViewerState extends State<_EmptyStoryViewer>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  List<String> _images = [];
  late final PageController _pageCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _loadImages();
  }

  Future<void> _loadImages() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final keys = manifest.listAssets()
        .where((k) {
          final lower = k.toLowerCase();
          return k.startsWith('assets/images/') &&
              (lower.endsWith('.jpg') ||
               lower.endsWith('.jpeg') ||
               lower.endsWith('.png') ||
               lower.endsWith('.webp'));
        })
        .toList()
      ..sort();
    if (mounted) {
      setState(() => _images = keys);
      _fadeCtrl.forward();
    }
  }

  @override void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (_images.isEmpty || index < 0 || index >= _images.length) return;
    _fadeCtrl.forward(from: 0.0);
    setState(() => _current = index);
    _pageCtrl.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (_images.isEmpty) {
      return ColoredBox(
        color: t.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
        child: Center(child: SvgPicture.string(_svgImageBroken,
            width: 40, height: 40,
            colorFilter: ColorFilter.mode(
                t.isDark ? Colors.white24 : Colors.black26, BlendMode.srcIn))),
      );
    }

    return GestureDetector(
      onTapUp: (d) {
        final half = context.size!.width / 2;
        d.localPosition.dx < half ? _goTo(_current - 1) : _goTo(_current + 1);
      },
      child: Stack(fit: StackFit.expand, children: [

        // ── PageView de imagens de assets/images/ ────────────────────────────
        PageView.builder(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _images.length,
          itemBuilder: (_, i) => FadeTransition(
            opacity: i == _current ? _fadeAnim : const AlwaysStoppedAnimation(1.0),
            child: Image.asset(
              _images[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => ColoredBox(
                color: t.isDark ? const Color(0xFF1A1A1A) : const Color(0xFFEEEEEE),
                child: Center(child: SvgPicture.string(_svgImageBroken,
                    width: 36, height: 36,
                    colorFilter: ColorFilter.mode(
                        t.isDark ? Colors.white24 : Colors.black26,
                        BlendMode.srcIn))),
              ),
            ),
          ),
        ),

        // ── Gradiente superior ───────────────────────────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: Container(height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xBB000000), Colors.transparent]),
            ),
          ),
        ),

        // ── Gradiente inferior ───────────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
            ),
          ),
        ),

        // ── Indicadores (dots estilo Pinterest) ──────────────────────────────
        Positioned(bottom: 14, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_images.length, (i) {
              final active = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? Colors.white : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // ── Contador (ex: 1 / 5) ─────────────────────────────────────────────
        Positioned(top: 14, right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.52),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_current + 1} / ${_images.length}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),
        ),

      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Play/Pause overlay — auto-hide, não bloqueia WebView
// ─────────────────────────────────────────────────────────────────────────────
class _PlayPauseOverlay extends StatefulWidget {
  final bool playing;
  final VoidCallback onTap;
  const _PlayPauseOverlay({required this.playing, required this.onTap});
  @override State<_PlayPauseOverlay> createState() => _PlayPauseOverlayState();
}
class _PlayPauseOverlayState extends State<_PlayPauseOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  Timer? _hideTimer;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
    _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _showTemporarily();
  }

  void _showTemporarily() {
    _hideTimer?.cancel();
    _ac.forward();
    if (widget.playing) {
      _hideTimer = Timer(const Duration(milliseconds: 2500), () {
        if (mounted) _ac.reverse();
      });
    }
  }

  void _handleTap() { widget.onTap(); _showTemporarily(); }

  @override void didUpdateWidget(_PlayPauseOverlay old) {
    super.didUpdateWidget(old);
    if (!widget.playing && old.playing) { _hideTimer?.cancel(); _ac.forward(); }
    if (widget.playing && !old.playing) _showTemporarily();
  }

  @override void dispose() { _hideTimer?.cancel(); _ac.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onTap: _handleTap,
    child: FadeTransition(
      opacity: _opacity,
      child: Center(
        child: Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.72),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, spreadRadius: 4)],
          ),
          child: Center(child: SvgPicture.string(
            widget.playing ? _svgPause : _svgPlay, width: 28, height: 28,
            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
        ),
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão flutuante do player (mute + download)
// ─────────────────────────────────────────────────────────────────────────────
class _PlayerBtn extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  const _PlayerBtn({required this.svg, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7), shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8)]),
      child: Center(child: SvgPicture.string(svg, width: 18, height: 18,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))));
}

// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// Estado vazio — animado, com pulso e fade escalonado
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  final int index;

  // ✅ FIX: adicionado {super.key} para aceitar o parâmetro key (ex: ValueKey)
  const _RelatedCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onMenuTap,
    this.index = 0,
  });

  static Map<String, String> _headers(VideoSource src) {
    const ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    final origins = {
      VideoSource.eporner:'https://www.eporner.com/', VideoSource.pornhub:'https://www.pornhub.com/',
      VideoSource.redtube:'https://www.redtube.com/', VideoSource.youporn:'https://www.youporn.com/',
      VideoSource.xvideos:'https://www.xvideos.com/', VideoSource.xhamster:'https://xhamster.com/',
      VideoSource.spankbang:'https://spankbang.com/', VideoSource.bravotube:'https://www.bravotube.net/',
      VideoSource.drtuber:'https://www.drtuber.com/', VideoSource.txxx:'https://www.txxx.com/',
      VideoSource.gotporn:'https://www.gotporn.com/', VideoSource.porndig:'https://www.porndig.com/',
    };
    return {'User-Agent':ua,'Accept':'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language':'pt-PT,pt;q=0.9,en;q=0.8',
        if(origins[src]!=null)'Referer':origins[src]!};
  }

  @override State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _slide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);

    // Stagger por índice
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 15)), () {
      if (mounted) _ac.forward();
    });
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: GestureDetector(
        onTap: widget.onTap, behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 160, height: 90,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: _ThumbCompact(
                    url: widget.video.thumb,
                    headers: _RelatedCard._headers(widget.video.source),
                    bg: t.thumbBg)),
                if (widget.video.duration.isNotEmpty)
                  Positioned(bottom:4, right:5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal:4, vertical:1),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                      child: Text(widget.video.duration, style: const TextStyle(
                          color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
              ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.video.title, style: TextStyle(color: t.text, fontSize: 13,
                  fontWeight: FontWeight.w500, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${widget.video.sourceLabel}${widget.video.views.isNotEmpty?"  ·  ${widget.video.views} vis.":""}',
                  style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
            ])),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => widget.onMenuTap(d.globalPosition),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal:4, vertical:4),
                  child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 20))),
          ])),
      ),
    );
  }
}

class _ThumbCompact extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final Color bg;
  const _ThumbCompact({required this.url, required this.headers, required this.bg});
  @override State<_ThumbCompact> createState() => _ThumbCompactState();
}
class _ThumbCompactState extends State<_ThumbCompact> {
  int _attempt = 0; bool _failed = false;
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (widget.url.isEmpty || _failed)
      return Container(color: widget.bg,
          child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover, headers: widget.headers,
      errorBuilder: (_, __, ___) {
        if (_attempt < 1) WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState(()=>_attempt++);});
        else WidgetsBinding.instance.addPostFrameCallback((_){if(mounted)setState(()=>_failed=true);});
        return Container(color: widget.bg,
            child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
      },
      loadingBuilder: (_, child, p) => p == null ? child : _Shimmer(radius: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExibicaoPage
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;
  final bool isActive;
  const ExibicaoPage({super.key, this.embedUrl, this.currentVideo,
      required this.onVideoTap, this.isActive = true});
  @override State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool   _loadingRelated = false;
  InAppWebViewController? _webCtrl;
  VideoPlayerController? _localCtrl; // mantido para não quebrar refs futuras — não usado no empty state
  bool   _muted          = false;
  bool   _playing        = true;
  bool   _playerLoading  = true;
  FeedVideo? _nextVideo;
  String _detectedEngine = '—';

  // Animação de troca de vídeo (descrição fixa anima internamente)
  late final AnimationController _descAnim;
  late final AnimationController _playerEnterAnim;

  // ScrollController para a lista de sugestões apenas
  final ScrollController _suggestionsScroll = ScrollController();

  bool get _isEmpty => widget.embedUrl == null || widget.currentVideo == null;
  bool get _isDirect => !_isEmpty && _isDirectVideoUrl(widget.embedUrl!);
  VideoPlayerController? _directCtrl;
  bool _directInitialized = false;

  @override void initState() {
    super.initState();
    _descAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
    _playerEnterAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    if (!_isEmpty) { _loadRelated(); _startPlayerTimeout(); }
    if (_isDirect) _initDirectPlayer(widget.embedUrl!);
  }

  // FIX: usa _directCtrl diretamente após setState para evitar ambiguidade
  // de resolução de 'ctrl' no compilador de release (tree-shaking/AOT)
  void _initDirectPlayer(String url) {
    _directCtrl?.dispose();
    _directCtrl = null;
    _directInitialized = false;
    final pending = VideoPlayerController.networkUrl(Uri.parse(url));
    pending.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _directCtrl = pending;
        _directInitialized = true;
        _playerLoading = false;
      });
      _directCtrl!.setLooping(true);
      _directCtrl!.setVolume(_muted ? 0.0 : 1.0);
      if (_playing) _directCtrl!.play();
    }).catchError((_) {
      if (mounted) setState(() => _playerLoading = false);
    });
  }

  void _startPlayerTimeout() {
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && _playerLoading) setState(() => _playerLoading = false);
    });
  }

  @override void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      _descAnim.forward(from: 0.0);
      _playerEnterAnim.forward(from: 0.0);
      setState(() { _playerLoading = true; _playing = true; _detectedEngine = '—';
                    _directInitialized = false; });
      // Trocar player directo se necessário
      if (_isDirect) {
        _initDirectPlayer(widget.embedUrl!);
      } else {
        _directCtrl?.dispose();
        _directCtrl = null;
      }
      _loadRelated();
      _startPlayerTimeout();
    }
    if (widget.isActive != old.isActive) {
      if (_isDirect) {
        widget.isActive ? _directCtrl?.play() : _directCtrl?.pause();
      } else {
        _webSend(widget.isActive ? 'px:play' : 'px:pause');
      }
      setState(() => _playing = widget.isActive);
    }
  }

  @override void dispose() {
    _descAnim.dispose();
    _playerEnterAnim.dispose();
    _suggestionsScroll.dispose();
    _directCtrl?.dispose();
    super.dispose();
  }

  void _webSend(String msg) =>
      _webCtrl?.evaluateJavascript(source: "window.postMessage('$msg','*')");

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    setState(() {
      _related..clear()..addAll(videos.where((v) => v.embedUrl != widget.embedUrl).take(20));
      _loadingRelated = false;
    });
  }

  void _snack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: t.toastText)),
      backgroundColor: t.toastBg, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2)));
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = widget.currentVideo; if (video == null) return;
    _snack('A capturar link do vídeo...');
    try {
      final result = await _webCtrl!.evaluateJavascript(source: r'''
        (function(){
          var E=window.__pxEngine;
          var v=(E&&E.videoEl)||document.querySelector('video');
          if(!v)return '__none__';
          var s=v.currentSrc||v.src||'';
          if(s&&s.startsWith('http'))return s;
          var src=document.querySelector('source[src]');
          return src&&src.src&&src.src.startsWith('http')?src.src:'__none__';
        })()''');
      final src = result?.toString().replaceAll('"', '').trim() ?? '__none__';
      if (!mounted) return;
      if (src == '__none__' || src.isEmpty) { _snack('Inicia a reprodução antes.'); return; }
      DownloadService.instance.startDownload(url: src, title: video.title,
          type: 'video', thumbUrl: video.thumb, sourceUrl: video.embedUrl);
      _snack('Download iniciado');
    } catch (_) { if (mounted) _snack('Erro ao capturar o vídeo.'); }
  }

  void _togglePlay() {
    final np = !_playing;
    setState(() => _playing = np);
    if (_isDirect) {
      np ? _directCtrl?.play() : _directCtrl?.pause();
    } else if (!_isEmpty) {
      _webSend(np ? 'px:play' : 'px:pause');
    }
  }

  void _toggleMute() {
    final nm = !_muted;
    setState(() => _muted = nm);
    if (_isDirect) {
      _directCtrl?.setVolume(nm ? 0.0 : 1.0);
    } else if (!_isEmpty) {
      _webSend(nm ? 'px:mute' : 'px:unmute');
    }
  }

  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset pos) {
    final t = AppTheme.current;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx, color: t.popup, elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(pos & const Size(1,1), Offset.zero & overlay.size),
      items: [
        _popItem('save',     _svgSaveLater, 'Guardar para assistir mais tarde', t),
        _popItem('playlist', _svgPlaylist,  'Adicionar na minha playlist',      t),
        _popItem('next',     _svgPlayNext,  'Exibir como próximo vídeo',        t),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      switch (val) {
        case 'save':     _snack('Guardado para assistir mais tarde'); break;
        case 'playlist': _snack('Adicionado à playlist'); break;
        case 'next':     setState(() => _nextVideo = v); _snack('Será exibido a seguir'); break;
      }
    });
  }

  PopupMenuItem<String> _popItem(String val, String svg, String label, AppTheme t) =>
    PopupMenuItem<String>(value: val, height: 46,
      child: Row(children: [
        SvgPicture.string(svg, width: 18, height: 18,
            colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: t.text, fontSize: 13.5))),
      ]));

  @override Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark,
    );
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video   = widget.currentVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          bottom: false,
          child: Column(children: [

            // ── Player ────────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _playerEnterAnim,
              builder: (_, child) => FadeTransition(
                opacity: _playerEnterAnim,
                child: Transform.translate(
                  offset: Offset(0, (1 - _playerEnterAnim.value) * -20),
                  child: child,
                ),
              ),
              child: ClipRRect(
                borderRadius: _isEmpty
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20))
                    : BorderRadius.zero,
                child: SizedBox(
                width: screenW,
                height: playerH,
                child: ColoredBox(
                  color: _isEmpty ? Colors.transparent : Colors.black,
                  child: Stack(children: [

                    // ── DIRECT: VideoPlayer nativo ────────────────────────
                    if (!_isEmpty && _isDirect) ...[
                      Positioned.fill(
                        child: _directInitialized && _directCtrl != null
                            ? FittedBox(fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _directCtrl!.value.size.width,
                                  height: _directCtrl!.value.size.height,
                                  child: VideoPlayer(_directCtrl!)))
                            : const ColoredBox(color: Colors.black),
                      ),
                      // Thumbnail enquanto inicializa
                      if (_playerLoading)
                        Positioned.fill(child: Stack(children: [
                          if (video?.thumb != null && video!.thumb.isNotEmpty)
                            Image.network(video.thumb, fit: BoxFit.cover,
                              width: double.infinity, height: double.infinity,
                              headers: const {'User-Agent': 'Mozilla/5.0'},
                              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
                          Container(color: Colors.black54),
                          const Center(child: CircularProgressIndicator(
                              color: Colors.white70, strokeWidth: 1.5)),
                        ])),
                      // Play/Pause overlay
                      Positioned.fill(child: _PlayPauseOverlay(
                          playing: _playing, onTap: _togglePlay)),
                      // Gradiente inferior
                      Positioned(left:0, right:0, bottom:0,
                        child: Container(height: 72,
                          decoration: const BoxDecoration(gradient: LinearGradient(
                            begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            colors: [Color(0xCC000000), Colors.transparent])))),
                      // Botões: mute + download (link directo tem download)
                      Positioned(bottom:8, right:8,
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          _PlayerBtn(svg: _muted ? _svgVolOff : _svgVolOn, onTap: _toggleMute),
                          const SizedBox(height: 8),
                          _PlayerBtn(svg: _svgDl, onTap: _forceDownload),
                        ])),
                    ],

                    // ── EMBED: WebView puro sem controlos do app ──────────
                    if (!_isEmpty && !_isDirect) ...[
                      Positioned.fill(
                        child: InAppWebView(
                          key: ValueKey(widget.embedUrl),
                          initialUrlRequest: URLRequest(url: WebUri(widget.embedUrl!)),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            transparentBackground: true,
                            disableDefaultErrorPage: true,
                            disableHorizontalScroll: true,
                            disableVerticalScroll: true,
                            supportZoom: false,
                            builtInZoomControls: false,
                            displayZoomControls: false,
                            horizontalScrollBarEnabled: false,
                            verticalScrollBarEnabled: false,
                            mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                            allowFileAccessFromFileURLs: true,
                            allowUniversalAccessFromFileURLs: true,
                            safeBrowsingEnabled: false,
                            thirdPartyCookiesEnabled: true,
                            domStorageEnabled: true,
                            databaseEnabled: true,
                            useOnLoadResource: true,
                            useShouldInterceptRequest: false,
                            userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
                                'AppleWebKit/537.36 (KHTML, like Gecko) '
                                'Chrome/124.0.0.0 Safari/537.36',
                          ),
                          onWebViewCreated: (ctrl) {
                            _webCtrl = ctrl;
                            ctrl.addJavaScriptHandler(
                              handlerName: 'pxFingerprint',
                              callback: (args) {
                                if (!mounted || args.isEmpty) return;
                                try {
                                  String eng = '?';
                                  if (args[0] is String) {
                                    eng = RegExp(r'"engine":"([^"]+)"')
                                        .firstMatch(args[0] as String)?.group(1) ?? '?';
                                  } else {
                                    eng = (args[0] as Map)['engine']?.toString() ?? '?';
                                  }
                                  setState(() => _detectedEngine = eng);
                                } catch (_) {}
                              },
                            );
                            ctrl.addJavaScriptHandler(
                              handlerName: 'pxState',
                              callback: (args) {
                                if (!mounted || args.isEmpty) return;
                                try {
                                  final raw = args[0];
                                  bool paused = false;
                                  if (raw is String) {
                                    paused = raw.contains('"paused":true');
                                  } else if (raw is Map) {
                                    paused = raw['paused'] == true;
                                  }
                                  if (mounted && _playing == paused) {
                                    setState(() => _playing = !paused);
                                  }
                                } catch (_) {}
                              },
                            );
                          },
                          onLoadStop: (ctrl, _) async {
                            if (mounted) setState(() => _playerLoading = false);
                          },
                          onLoadError: (ctrl, url, code, msg) async {
                            if (mounted) setState(() => _playerLoading = false);
                          },
                          shouldOverrideUrlLoading: (ctrl, action) async {
                            final url = action.request.url?.toString() ?? '';
                            // Domínios permitidos dentro do WebView — apenas os embeds
                            const embedDomains = [
                              'eporner.com', 'pornhub.com', 'redtube.com',
                              'embed.redtube.com', 'youporn.com', 'xvideos.com',
                              'xhamster.com', 'spankbang.com', 'bravotube.net',
                              'drtuber.com', 'txxx.com', 'gotporn.com',
                              'porndig.com', 'xnxx.com', 'xvideos2.com',
                            ];
                            // Bloquear QUALQUER navegação que saia dos domínios de embed,
                            // independentemente do tipo (clique, redirect, form, etc.)
                            if (url.startsWith('http') &&
                                !embedDomains.any((d) => url.contains(d))) {
                              return NavigationActionPolicy.CANCEL;
                            }
                            return NavigationActionPolicy.ALLOW;
                          },
                        ),
                      ),
                      // Thumbnail enquanto carrega
                      if (_playerLoading)
                        Positioned.fill(child: Stack(children: [
                          if (video?.thumb != null && video!.thumb.isNotEmpty)
                            Image.network(video.thumb, fit: BoxFit.cover,
                              width: double.infinity, height: double.infinity,
                              headers: const {'User-Agent': 'Mozilla/5.0'},
                              errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
                          Container(color: Colors.black54),
                          const Center(child: CircularProgressIndicator(
                              color: Colors.white70, strokeWidth: 1.5)),
                        ])),
                      // Embeds: SEM play/pause overlay, SEM botão de download
                      // Apenas botão de mute para não interferir com o player nativo
                      Positioned(bottom:8, right:8,
                        child: _PlayerBtn(svg: _muted ? _svgVolOff : _svgVolOn, onTap: _toggleMute)),
                    ],

                    // ── Empty state: story viewer com imagens de assets/images/ ──
                    if (_isEmpty)
                      const Positioned.fill(child: _EmptyStoryViewer()),
                  ]),
                ),
              )), // fecha ClipRRect
            ),

            // ── Descrição FIXA (não rola) com gradiente em baixo ─────────────
            if (!_isEmpty && video != null)
              AnimatedBuilder(
                animation: _descAnim,
                builder: (_, child) => FadeTransition(
                  opacity: _descAnim,
                  child: Transform.translate(
                    offset: Offset(0, (1 - _descAnim.value) * 16),
                    child: child,
                  ),
                ),
                child: _VideoDescription(
                  video: video,
                  detectedEngine: _detectedEngine,
                  nextVideo: _nextVideo,
                  onNextVideoTap: () {
                    if (_nextVideo != null) {
                      widget.onVideoTap(_nextVideo!);
                      setState(() => _nextVideo = null);
                    }
                  },
                  onNextVideoClose: () => setState(() => _nextVideo = null),
                ),
              ),

            // ── Sugestões (rola independentemente) ───────────────────────────
            Expanded(
              child: _isEmpty
                  ? _EmptyStateBody(t: t)
                  : _SuggestionsSection(
                      loading: _loadingRelated,
                      related: _related,
                      onVideoTap: (v) {
                        if (_nextVideo?.embedUrl == v.embedUrl) {
                          setState(() => _nextVideo = null);
                        }
                        // Animação iOS nativa: push de nova ExibicaoPage
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (_) => ExibicaoPage(
                              embedUrl: v.embedUrl,
                              currentVideo: v,
                              onVideoTap: widget.onVideoTap,
                              isActive: true,
                            ),
                          ),
                        );
                      },
                      onMenuTap: (v, pos) => _showVideoMenu(context, v, pos),
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

// URL do site a publicitar no empty state
const String _brandSiteUrl = 'https://www.teusite.pt'; // ← substitui pelo teu URL real

// ─────────────────────────────────────────────────────────────────────────────
// Corpo do empty state — estilo Pinterest: badge da marca + botão visitar site
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyStateBody extends StatelessWidget {
  final AppTheme t;
  const _EmptyStateBody({required this.t});

  Future<void> _launch() async {
    final uri = Uri.parse(_brandSiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Badge do autor / marca ──────────────────────────────────────────
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: t.isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF2F2F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: t.isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE0E0E0)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                SvgPicture.string(_svgStorefront, width: 14, height: 14,
                    colorFilter: ColorFilter.mode(t.textSecondary, BlendMode.srcIn)),
                const SizedBox(width: 6),
                Text(
                  'Scalixa Studio', // ← o nome da tua marca
                  style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
              ]),
            ),
          ]),

          const SizedBox(height: 12),

          // ── Título ──────────────────────────────────────────────────────────
          Text(
            'Descobre mais conteúdo',
            style: TextStyle(
                color: t.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.3),
          ),
          const SizedBox(height: 6),
          Text(
            'Explora a nossa colecção e visita o site para saber mais.',
            style: TextStyle(
                color: t.textSecondary, fontSize: 13.5, height: 1.4),
          ),

          const SizedBox(height: 20),

          // ── Botão "Visitar o site" ───────────────────────────────────────────
          GestureDetector(
            onTap: _launch,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: t.isDark
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFFF0F0F0),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: t.isDark
                      ? const Color(0xFF2C2C2E)
                      : const Color(0xFFDDDDDD),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.string(_svgGlobe, width: 18, height: 18,
                      colorFilter: ColorFilter.mode(
                          t.isDark ? Colors.white70 : Colors.black87,
                          BlendMode.srcIn)),
                  const SizedBox(width: 8),
                  Text(
                    'Visitar o site',
                    style: TextStyle(
                        color: t.isDark ? Colors.white : Colors.black,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1),
                  ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Descrição fixa do vídeo — com gradiente de fundo dependente do tema
// ─────────────────────────────────────────────────────────────────────────────
class _VideoDescription extends StatelessWidget {
  final FeedVideo video;
  final String detectedEngine;
  final FeedVideo? nextVideo;
  final VoidCallback onNextVideoTap;
  final VoidCallback onNextVideoClose;

  const _VideoDescription({
    required this.video,
    required this.detectedEngine,
    required this.nextVideo,
    required this.onNextVideoTap,
    required this.onNextVideoClose,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    final gradientColors = t.isDark
        ? [t.bg, t.bg.withOpacity(0.96), t.bg.withOpacity(0.0)]
        : [t.bg, t.bg.withOpacity(0.96), t.bg.withOpacity(0.0)];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradientColors,
          stops: const [0.0, 0.75, 1.0],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Título
        Text(video.title, style: TextStyle(color: t.text, fontSize: 14.5,
            fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 6),

        // Fonte + views + engine badge
        Row(children: [
          Text(video.sourceLabel, style: TextStyle(
              color: t.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w500)),
          if (video.views.isNotEmpty)
            Text('  ·  ${video.views} vis.',
                style: TextStyle(color: t.textHint, fontSize: 11.5)),
          if (detectedEngine != '—') ...[
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppTheme.ytRed.withOpacity(0.12),
                borderRadius: BorderRadius.circular(4)),
              child: Text(detectedEngine, style: TextStyle(
                  color: AppTheme.ytRed, fontSize: 10, fontWeight: FontWeight.w700))),
          ],
        ]),

        const SizedBox(height: 10),
        Divider(color: t.divider, thickness: 1, height: 1),
        const SizedBox(height: 8),

        // Banner "próximo vídeo"
        if (nextVideo != null) ...[
          GestureDetector(
            onTap: onNextVideoTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: t.isDark ? const Color(0xFF2A1A1A) : const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: t.isDark ? const Color(0xFF5A2020) : const Color(0xFFFFCCCC))),
              child: Row(children: [
                SvgPicture.string(_svgPlaylist, width: 15, height: 15,
                    colorFilter: ColorFilter.mode(AppTheme.ytRed, BlendMode.srcIn)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Seguinte:', style: TextStyle(color: AppTheme.ytRed,
                      fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(nextVideo!.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.text, fontSize: 12.5, fontWeight: FontWeight.w600)),
                  Text(nextVideo!.sourceLabel,
                      style: TextStyle(color: t.textSecondary, fontSize: 11)),
                ])),
                GestureDetector(
                  onTap: onNextVideoClose,
                  child: Padding(padding: const EdgeInsets.only(left: 8),
                      child: Icon(Icons.close_rounded, color: t.iconTertiary, size: 18))),
              ]),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Secção de sugestões — rola de forma independente
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionsSection extends StatefulWidget {
  final bool loading;
  final List<FeedVideo> related;
  final void Function(FeedVideo) onVideoTap;
  final void Function(FeedVideo, Offset) onMenuTap;

  const _SuggestionsSection({
    required this.loading,
    required this.related,
    required this.onVideoTap,
    required this.onMenuTap,
  });

  @override
  State<_SuggestionsSection> createState() => _SuggestionsSectionState();
}

class _SuggestionsSectionState extends State<_SuggestionsSection> {
  final ScrollController _scroll = ScrollController();

  @override void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text('Relacionados', style: TextStyle(
                color: t.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
        if (widget.loading)
          SliverList(
            delegate: SliverChildListDelegate(_skeletonCards(5)),
          )
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i >= widget.related.length) {
                  return const SizedBox(height: 32);
                }
                final v = widget.related[i];
                return _RelatedCard(
                  key: ValueKey(v.embedUrl),
                  video: v,
                  index: i,
                  onTap: () => widget.onVideoTap(v),
                  onMenuTap: (pos) => widget.onMenuTap(v, pos),
                );
              },
              childCount: widget.related.length + 1,
            ),
          ),
      ],
    );
  }
}
