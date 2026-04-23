import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

import '../models/feed_video_model.dart';
import '../services/download_service.dart';
import '../services/theme_service.dart';
import '../theme/app_theme.dart';

// ─── APIs de conversão ────────────────────────────────────────────────────────
const List<String> _convertApis = [
  'https://nuxxconvert1.onrender.com',
  'https://nuxxconvert2.onrender.com',
  'https://nuxxconvert3.onrender.com',
  'https://nuxxconvert4.onrender.com',
  'https://nuxxconvert5.onrender.com',
];

Future<String?> _extractDirectLink(String pageUrl) async {
  final completer = Completer<String?>();
  int failed = 0;

  for (final api in _convertApis) {
    () async {
      try {
        final uri = Uri.parse('$api/extract?url=${Uri.encodeComponent(pageUrl)}');
        final resp = await http.get(uri).timeout(const Duration(seconds: 90));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          final link = data['link'] as String?;
          if (link != null && link.isNotEmpty && !completer.isCompleted) {
            completer.complete(link);
          } else {
            failed++;
            if (failed == _convertApis.length && !completer.isCompleted) completer.complete(null);
          }
        } else {
          failed++;
          if (failed == _convertApis.length && !completer.isCompleted) completer.complete(null);
        }
      } catch (_) {
        failed++;
        if (failed == _convertApis.length && !completer.isCompleted) completer.complete(null);
      }
    }();
  }

  return completer.future;
}

bool _isDirectVideoUrl(String url) {
  if (url.isEmpty) return false;
  final lower = url.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') || lower.endsWith('.m3u8') || lower.endsWith('.webm') ||
      lower.endsWith('.mkv') || lower.endsWith('.mov') || lower.endsWith('.avi') ||
      lower.endsWith('.flv') || lower.endsWith('.ts');
}

// ─── SVGs ─────────────────────────────────────────────────────────────────────
const _svgSaveLater =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m14.181.207a1 1 0 0 0 -1.181.983v2.879a8.053 8.053 0 1 0 6.931 6.931h2.886'
    'a1 1 0 0 0 .983-1.181 12.047 12.047 0 0 0 -9.619-9.612zm1.819 12.793h-2.277'
    'a1.994 1.994 0 1 1 -2.723-2.723v-3.277a1 1 0 0 1 2 0v3.277a2 2 0 0 1 .723.723h2.277'
    'a1 1 0 0 1 0 2zm-13.014-8.032a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z"/></svg>';

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
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2Z"/>'
    '<path d="M20.807,4.29a1,1,0,0,0-1.415,1.415,8.913,8.913,0,0,1,0,12.59'
    'a1,1,0,0,0,1.415,1.415A10.916,10.916,0,0,0,20.807,4.29Z"/></svg>';

const _svgVolOff =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2Z"/>'
    '<path d="M22.707,8.293a1,1,0,0,0-1.414,0L20,9.586l-1.293-1.293a1,1,0,0,0-1.414,1.414'
    'L18.586,11l-1.293,1.293a1,1,0,1,0,1.414,1.414L20,12.414l1.293,1.293a1,1,0,0,0,1.414-1.414'
    'L21.414,11l1.293-1.293A1,1,0,0,0,22.707,8.293Z"/></svg>';

// ─── Shimmer ──────────────────────────────────────────────────────────────────
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
          colors: AppTheme.current.shimmer),
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
    ])));

// ─── Player Controls com auto-hide ───────────────────────────────────────────
class _PlayerControls extends StatefulWidget {
  final bool playing;
  final bool muted;
  final Duration position;
  final Duration duration;
  final VoidCallback onPlayPause;
  final VoidCallback onMute;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final bool hasPrev;
  final bool hasNext;
  final ValueChanged<double> onSeek;
  final VoidCallback onDownload;

  const _PlayerControls({
    super.key,
    required this.playing, required this.muted,
    required this.position, required this.duration,
    required this.onPlayPause, required this.onMute,
    required this.onNext, required this.onPrev,
    required this.hasPrev, required this.hasNext,
    required this.onSeek, required this.onDownload,
  });

  @override State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _opacity;
  Timer? _hideTimer;

  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 250), value: 1.0);
    _opacity = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (widget.playing) {
      _hideTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) _ac.reverse();
      });
    }
  }

  void show() {
    _ac.forward();
    _scheduleHide();
  }

  @override void didUpdateWidget(_PlayerControls old) {
    super.didUpdateWidget(old);
    if (!widget.playing) { _hideTimer?.cancel(); _ac.forward(); }
    if (widget.playing && !old.playing) _scheduleHide();
  }

  @override void dispose() { _hideTimer?.cancel(); _ac.dispose(); super.dispose(); }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override Widget build(BuildContext context) {
    final total = widget.duration.inMilliseconds.toDouble();
    final pos = widget.position.inMilliseconds.toDouble().clamp(0.0, total > 0 ? total : 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: show,
      child: FadeTransition(
        opacity: _opacity,
        child: Stack(children: [
          Positioned(left: 0, right: 0, bottom: 0,
            child: Container(height: 120,
              decoration: const BoxDecoration(gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0xDD000000), Colors.transparent])))),

          Positioned(top: 8, right: 8,
            child: Row(children: [
              _SmallBtn(svg: _svgVolOff, active: widget.muted, activeSvg: _svgVolOn, onTap: widget.onMute),
              const SizedBox(width: 6),
              _SmallBtn(svg: _svgDl, onTap: widget.onDownload),
            ])),

          Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Opacity(opacity: widget.hasPrev ? 1.0 : 0.3,
              child: GestureDetector(
                onTap: widget.hasPrev ? widget.onPrev : null,
                child: Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 28)))),
            const SizedBox(width: 20),
            GestureDetector(
              onTap: widget.onPlayPause,
              child: Container(width: 68, height: 68,
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)]),
                child: Center(child: SvgPicture.string(
                  widget.playing ? _svgPause : _svgPlay, width: 26, height: 26,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))))),
            const SizedBox(width: 20),
            Opacity(opacity: widget.hasNext ? 1.0 : 0.3,
              child: GestureDetector(
                onTap: widget.hasNext ? widget.onNext : null,
                child: Container(width: 48, height: 48,
                  decoration: BoxDecoration(color: Colors.black.withOpacity(0.6), shape: BoxShape.circle),
                  child: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 28)))),
          ])),

          Positioned(left: 12, right: 12, bottom: 8,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Text(_fmt(widget.position), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                const Spacer(),
                Text(_fmt(widget.duration), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
              const SizedBox(height: 2),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 2.5,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: Colors.white,
                  inactiveTrackColor: Colors.white30,
                  thumbColor: Colors.white,
                  overlayColor: Colors.white24,
                ),
                child: Slider(value: pos, min: 0, max: total > 0 ? total : 1.0, onChanged: widget.onSeek)),
            ])),
        ]),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String svg;
  final String? activeSvg;
  final bool active;
  final VoidCallback onTap;
  const _SmallBtn({required this.svg, required this.onTap, this.activeSvg, this.active = false});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
      child: Center(child: SvgPicture.string(
        (active && activeSvg != null) ? activeSvg! : svg, width: 17, height: 17,
        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)))));
}

// ─── _RelatedCard ─────────────────────────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  final int index;
  const _RelatedCard({super.key, required this.video, required this.onTap,
      required this.onMenuTap, this.index = 0});

  static Map<String, String> _headers(VideoSource src) {
    const ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    final origins = {
      VideoSource.eporner: 'https://www.eporner.com/',
      VideoSource.pornhub: 'https://www.pornhub.com/',
      VideoSource.redtube: 'https://www.redtube.com/',
      VideoSource.youporn: 'https://www.youporn.com/',
      VideoSource.xvideos: 'https://www.xvideos.com/',
      VideoSource.xhamster: 'https://xhamster.com/',
      VideoSource.spankbang: 'https://spankbang.com/',
      VideoSource.bravotube: 'https://www.bravotube.net/',
      VideoSource.drtuber: 'https://www.drtuber.com/',
      VideoSource.txxx: 'https://www.txxx.com/',
      VideoSource.gotporn: 'https://www.gotporn.com/',
      VideoSource.porndig: 'https://www.porndig.com/',
    };
    return {'User-Agent': ua, if (origins[src] != null) 'Referer': origins[src]!};
  }
  @override State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _slide, _fade;
  @override void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 15)), () {
      if (mounted) _ac.forward();
    });
  }
  @override void dispose() { _ac.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => FadeTransition(opacity: _fade,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child)),
      child: GestureDetector(
        onTap: widget.onTap, behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 160, height: 90,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: _ThumbCompact(url: widget.video.thumb,
                      headers: _RelatedCard._headers(widget.video.source), bg: t.thumbBg)),
                if (widget.video.duration.isNotEmpty)
                  Positioned(bottom: 4, right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                      child: Text(widget.video.duration,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)))),
              ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.video.title, style: TextStyle(color: t.text, fontSize: 13,
                  fontWeight: FontWeight.w500, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${widget.video.sourceLabel}${widget.video.views.isNotEmpty ? "  ·  ${widget.video.views} vis." : ""}',
                  style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
            ])),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => widget.onMenuTap(d.globalPosition),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 20))),
          ]),
        ),
      ),
    );
  }
}

class _ThumbCompact extends StatefulWidget {
  final String url; final Map<String, String> headers; final Color bg;
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
        if (_attempt < 1) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _attempt++); });
        else WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _failed = true); });
        return Container(color: widget.bg,
            child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
      },
      loadingBuilder: (_, child, p) => p == null ? child : const _Shimmer(radius: 0),
    );
  }
}

// ─── ExibicaoPage ─────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? pageUrl;      // ← link da página do vídeo (antes era embedUrl)
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;
  final bool isActive;
  final List<FeedVideo>? playlist;
  final int playlistIndex;

  const ExibicaoPage({
    super.key,
    this.pageUrl,
    this.currentVideo,
    required this.onVideoTap,
    this.isActive = true,
    this.playlist,
    this.playlistIndex = 0,
  });

  @override State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool _loadingRelated = false;
  bool _muted = false;
  bool _playing = true;
  bool _playerLoading = true;
  FeedVideo? _nextVideo;
  int _currentPlaylistIndex = 0;

  late final AnimationController _descAnim;
  late final AnimationController _playerEnterAnim;

  VideoPlayerController? _ctrl;
  bool _initialized = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Timer? _posTimer;

  String? _directUrl;
  bool _extracting = false;

  final _controlsKey = GlobalKey<_PlayerControlsState>();

  bool get _isEmpty => widget.pageUrl == null || widget.currentVideo == null;

  @override void initState() {
    super.initState();
    _currentPlaylistIndex = widget.playlistIndex;
    _descAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _playerEnterAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    if (!_isEmpty) { _loadRelated(); _extractAndPlay(widget.pageUrl!); }
  }

  Future<void> _extractAndPlay(String url) async {
    if (!mounted) return;
    setState(() { _extracting = true; _playerLoading = true; _initialized = false; _directUrl = null; });

    String? directUrl = _isDirectVideoUrl(url) ? url : await _extractDirectLink(url);

    if (!mounted) return;
    if (directUrl == null) {
      setState(() { _extracting = false; _playerLoading = false; });
      _snack('Não foi possível obter o vídeo.');
      return;
    }

    setState(() { _directUrl = directUrl; _extracting = false; });
    await _initPlayer(directUrl);
  }

  Future<void> _initPlayer(String url) async {
    _ctrl?.removeListener(_onVideoUpdate);
    await _ctrl?.dispose();
    _ctrl = null;
    _posTimer?.cancel();
    _initialized = false;

    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
    } catch (_) {
      if (mounted) setState(() => _playerLoading = false);
      return;
    }
    if (!mounted) { c.dispose(); return; }

    _ctrl = c;
    _duration = c.value.duration;
    _initialized = true;
    c.setLooping(true);
    c.setVolume(_muted ? 0.0 : 1.0);
    if (_playing) c.play();
    c.addListener(_onVideoUpdate);

    _posTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted && _ctrl != null) setState(() => _position = _ctrl!.value.position);
    });

    if (mounted) setState(() => _playerLoading = false);
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {
      _playing = _ctrl?.value.isPlaying ?? false;
      _position = _ctrl?.value.position ?? Duration.zero;
      _duration = _ctrl?.value.duration ?? Duration.zero;
    });
  }

  @override void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      _descAnim.forward(from: 0.0);
      _playerEnterAnim.forward(from: 0.0);
      setState(() { _playing = true; _position = Duration.zero; });
      _extractAndPlay(widget.pageUrl!);
      _loadRelated();
    }
    if (widget.isActive != old.isActive) {
      widget.isActive ? _ctrl?.play() : _ctrl?.pause();
      setState(() => _playing = widget.isActive);
    }
  }

  @override void dispose() {
    _posTimer?.cancel();
    _ctrl?.removeListener(_onVideoUpdate);
    _ctrl?.dispose();
    _descAnim.dispose();
    _playerEnterAnim.dispose();
    super.dispose();
  }

  void _togglePlay() {
    final np = !_playing;
    setState(() => _playing = np);
    np ? _ctrl?.play() : _ctrl?.pause();
    _controlsKey.currentState?.show();
  }

  void _toggleMute() {
    final nm = !_muted;
    setState(() => _muted = nm);
    _ctrl?.setVolume(nm ? 0.0 : 1.0);
  }

  void _seek(double ms) {
    _ctrl?.seekTo(Duration(milliseconds: ms.toInt()));
    _controlsKey.currentState?.show();
  }

  void _skipSeconds(int secs) {
    final newPos = _position + Duration(seconds: secs);
    _ctrl?.seekTo(newPos.isNegative ? Duration.zero : newPos);
    _controlsKey.currentState?.show();
  }

  void _goNext() {
    final pl = widget.playlist ?? _related;
    final nextIdx = _currentPlaylistIndex + 1;
    if (nextIdx < pl.length) {
      setState(() => _currentPlaylistIndex = nextIdx);
      widget.onVideoTap(pl[nextIdx]);
    }
  }

  void _goPrev() {
    final prevIdx = _currentPlaylistIndex - 1;
    if (prevIdx >= 0) {
      final pl = widget.playlist ?? _related;
      setState(() => _currentPlaylistIndex = prevIdx);
      widget.onVideoTap(pl[prevIdx]);
    }
  }

  Future<void> _forceDownload() async {
    if (_directUrl == null) { _snack('A extrair link...'); return; }
    DownloadService.instance.startDownload(
      url: _directUrl!,
      title: widget.currentVideo?.title ?? 'video',
      type: 'video',
      thumbUrl: widget.currentVideo?.thumb ?? '',
      sourceUrl: widget.currentVideo?.pageUrl ?? '',
    );
    _snack('Download iniciado');
  }

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    setState(() {
      _related..clear()..addAll(videos.where((v) => v.pageUrl != widget.pageUrl).take(20));
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

  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset pos) {
    final t = AppTheme.current;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx, color: t.popup, elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        _popItem('save', _svgSaveLater, 'Guardar para assistir mais tarde', t),
        _popItem('playlist', _svgPlaylist, 'Adicionar na minha playlist', t),
        _popItem('next', _svgPlayNext, 'Exibir como próximo vídeo', t),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      switch (val) {
        case 'save': _snack('Guardado para assistir mais tarde'); break;
        case 'playlist': _snack('Adicionado à playlist'); break;
        case 'next': setState(() => _nextVideo = v); _snack('Será exibido a seguir'); break;
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
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video = widget.currentVideo;
    final pl = widget.playlist ?? _related;
    final hasPrev = _currentPlaylistIndex > 0;
    final hasNext = _currentPlaylistIndex < pl.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark),
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(bottom: false, child: Column(children: [

          // ── Player ──────────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _playerEnterAnim,
            builder: (_, child) => FadeTransition(opacity: _playerEnterAnim,
              child: Transform.translate(
                offset: Offset(0, (1 - _playerEnterAnim.value) * -20), child: child)),
            child: SizedBox(width: screenW, height: playerH,
              child: ColoredBox(color: Colors.black,
                child: Stack(children: [

                  if (_initialized && _ctrl != null)
                    Positioned.fill(child: FittedBox(fit: BoxFit.contain,
                      child: SizedBox(
                        width: _ctrl!.value.size.width,
                        height: _ctrl!.value.size.height,
                        child: VideoPlayer(_ctrl!)))),

                  if (_playerLoading || _extracting)
                    Positioned.fill(child: Stack(children: [
                      if (video?.thumb != null && video!.thumb.isNotEmpty)
                        Image.network(video.thumb, fit: BoxFit.cover,
                          width: double.infinity, height: double.infinity,
                          headers: const {'User-Agent': 'Mozilla/5.0'},
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black)),
                      Container(color: Colors.black54),
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const CircularProgressIndicator(color: Colors.white70, strokeWidth: 1.5),
                        if (_extracting) ...[
                          const SizedBox(height: 10),
                          const Text('A obter vídeo...', style: TextStyle(color: Colors.white60, fontSize: 12)),
                        ],
                      ])),
                    ])),

                  // Double tap esquerdo — recuar 10s
                  Positioned(left: 0, top: 0, bottom: 0, width: screenW * 0.35,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () { _skipSeconds(-10); _controlsKey.currentState?.show(); },
                      onTap: () => _controlsKey.currentState?.show())),

                  // Double tap direito — avançar 10s
                  Positioned(right: 0, top: 0, bottom: 0, width: screenW * 0.35,
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onDoubleTap: () { _skipSeconds(10); _controlsKey.currentState?.show(); },
                      onTap: () => _controlsKey.currentState?.show())),

                  if (!_isEmpty)
                    Positioned.fill(child: _PlayerControls(
                      key: _controlsKey,
                      playing: _playing, muted: _muted,
                      position: _position, duration: _duration,
                      hasPrev: hasPrev, hasNext: hasNext,
                      onPlayPause: _togglePlay, onMute: _toggleMute,
                      onNext: _goNext, onPrev: _goPrev,
                      onSeek: _seek, onDownload: _forceDownload)),

                  if (_isEmpty)
                    const Positioned.fill(child: ColoredBox(color: Colors.black)),
                ]))),
          ),

          // ── Descrição ──────────────────────────────────────────────────────
          if (!_isEmpty && video != null)
            AnimatedBuilder(
              animation: _descAnim,
              builder: (_, child) => FadeTransition(opacity: _descAnim,
                child: Transform.translate(
                  offset: Offset(0, (1 - _descAnim.value) * 16), child: child)),
              child: _VideoDescription(
                video: video, nextVideo: _nextVideo,
                onNextVideoTap: () {
                  if (_nextVideo != null) { widget.onVideoTap(_nextVideo!); setState(() => _nextVideo = null); }
                },
                onNextVideoClose: () => setState(() => _nextVideo = null)),
            ),

          // ── Sugestões ──────────────────────────────────────────────────────
          Expanded(child: _SuggestionsSection(
            loading: _loadingRelated,
            related: _related,
            onVideoTap: (v) {
              final idx = _related.indexOf(v);
              setState(() => _currentPlaylistIndex = idx >= 0 ? idx : 0);
              if (_nextVideo?.pageUrl == v.pageUrl) setState(() => _nextVideo = null);
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => ExibicaoPage(
                pageUrl: v.pageUrl,
                currentVideo: v,
                onVideoTap: widget.onVideoTap, isActive: true,
                playlist: _related, playlistIndex: idx >= 0 ? idx : 0)));
            },
            onMenuTap: (v, pos) => _showVideoMenu(context, v, pos))),
        ])),
      ),
    );
  }
}

// ─── Descrição ────────────────────────────────────────────────────────────────
class _VideoDescription extends StatelessWidget {
  final FeedVideo video;
  final FeedVideo? nextVideo;
  final VoidCallback onNextVideoTap;
  final VoidCallback onNextVideoClose;

  const _VideoDescription({required this.video, required this.nextVideo,
      required this.onNextVideoTap, required this.onNextVideoClose});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [t.bg, t.bg.withOpacity(0.96), t.bg.withOpacity(0.0)],
        stops: const [0.0, 0.75, 1.0])),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(video.title, style: TextStyle(color: t.text, fontSize: 14.5,
            fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 6),
        Row(children: [
          Text(video.sourceLabel, style: TextStyle(color: t.textSecondary,
              fontSize: 11.5, fontWeight: FontWeight.w500)),
          if (video.views.isNotEmpty)
            Text('  ·  ${video.views} vis.', style: TextStyle(color: t.textHint, fontSize: 11.5)),
        ]),
        const SizedBox(height: 10),
        Divider(color: t.divider, thickness: 1, height: 1),
        const SizedBox(height: 8),
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
              ])),
          ),
          const SizedBox(height: 8),
        ],
      ]),
    );
  }
}

// ─── Sugestões ────────────────────────────────────────────────────────────────
class _SuggestionsSection extends StatefulWidget {
  final bool loading;
  final List<FeedVideo> related;
  final void Function(FeedVideo) onVideoTap;
  final void Function(FeedVideo, Offset) onMenuTap;
  const _SuggestionsSection({required this.loading, required this.related,
      required this.onVideoTap, required this.onMenuTap});
  @override State<_SuggestionsSection> createState() => _SuggestionsSectionState();
}
class _SuggestionsSectionState extends State<_SuggestionsSection> {
  final ScrollController _scroll = ScrollController();
  @override void dispose() { _scroll.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return CustomScrollView(
      controller: _scroll, physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Text('Relacionados', style: TextStyle(color: t.text,
              fontSize: 13.5, fontWeight: FontWeight.w600)))),
        if (widget.loading)
          SliverList(delegate: SliverChildListDelegate(_skeletonCards(5)))
        else
          SliverList(delegate: SliverChildBuilderDelegate(
            (_, i) {
              if (i >= widget.related.length) return const SizedBox(height: 32);
              final v = widget.related[i];
              return _RelatedCard(key: ValueKey(v.pageUrl), video: v, index: i,
                  onTap: () => widget.onVideoTap(v),
                  onMenuTap: (pos) => widget.onMenuTap(v, pos));
            },
            childCount: widget.related.length + 1)),
      ],
    );
  }
}