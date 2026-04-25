import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:volume_controller/volume_controller.dart';

import '../models/feed_video_model.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';

// ─── APIs de conversão ────────────────────────────────────────────────────────
const List<String> _convertApis = [
  'https://nuxxconvert1.onrender.com',
  'https://nuxxconvert2.onrender.com',
  'https://nuxxconvert3.onrender.com',
  'https://nuxxconvert4.onrender.com',
  'https://nuxxconvert5.onrender.com',
];

Future<String?> _extractDirectLink(String videoUrl) async {
  final completer = Completer<String?>();
  int failed = 0;
  for (final api in _convertApis) {
    () async {
      try {
        final uri = Uri.parse('$api/extract?url=${Uri.encodeComponent(videoUrl)}');
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

// ─── _SvgIcon — carrega SVG de assets/icons/svg/ ─────────────────────────────
class _SvgIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color color;
  const _SvgIcon(this.name, {this.size = 20, this.color = Colors.white});
  @override Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/svg/$name.svg',
    width: size, height: size,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

// ─── _SmallBtn ────────────────────────────────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  final String iconName;
  final VoidCallback onTap;
  const _SmallBtn({required this.iconName, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), shape: BoxShape.circle),
      child: Center(child: _SvgIcon(iconName, size: 17))));
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
      VideoSource.eporner:    'https://www.eporner.com/',
      VideoSource.pornhub:    'https://www.pornhub.com/',
      VideoSource.redtube:    'https://www.redtube.com/',
      VideoSource.youporn:    'https://www.youporn.com/',
      VideoSource.xvideos:    'https://www.xvideos.com/',
      VideoSource.xhamster:   'https://xhamster.com/',
      VideoSource.spankbang:  'https://spankbang.com/',
      VideoSource.bravotube:  'https://www.bravotube.net/',
      VideoSource.drtuber:    'https://www.drtuber.com/',
      VideoSource.txxx:       'https://www.txxx.com/',
      VideoSource.gotporn:    'https://www.gotporn.com/',
      VideoSource.porndig:    'https://www.porndig.com/',
      VideoSource.beeg:       'https://beeg.com/',
      VideoSource.tube8:      'https://www.tube8.com/',
      VideoSource.tnaflix:    'https://www.tnaflix.com/',
      VideoSource.empflix:    'https://www.empflix.com/',
      VideoSource.porntrex:   'https://www.porntrex.com/',
      VideoSource.hclips:     'https://hclips.com/',
      VideoSource.tubedupe:   'https://www.tubedupe.com/',
      VideoSource.nuvid:      'https://www.nuvid.com/',
      VideoSource.sunporno:   'https://www.sunporno.com/',
      VideoSource.pornone:    'https://pornone.com/',
      VideoSource.slutload:   'https://www.slutload.com/',
      VideoSource.iceporn:    'https://www.iceporn.com/',
      VideoSource.vjav:       'https://vjav.com/',
      VideoSource.jizzbunker: 'https://jizzbunker.com/',
      VideoSource.cliphunter: 'https://www.cliphunter.com/',
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: _SvgIcon('more_vert', size: 20, color: t.iconTertiary))),
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
          child: Center(child: _SvgIcon('play_circle_outline', size: 32, color: t.iconSub)));
    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover, headers: widget.headers,
      errorBuilder: (_, __, ___) {
        if (_attempt < 1) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _attempt++); });
        else WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) setState(() => _failed = true); });
        return Container(color: widget.bg,
            child: Center(child: _SvgIcon('play_circle_outline', size: 32, color: t.iconSub)));
      },
      loadingBuilder: (_, child, p) => p == null ? child : const _Shimmer(radius: 0),
    );
  }
}

// ─── ExibicaoPage ─────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? videoUrl;
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;
  final bool isActive;
  final List<FeedVideo>? playlist;
  final int playlistIndex;

  const ExibicaoPage({
    super.key,
    this.videoUrl,
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
  int _currentPlaylistIndex = 0;

  late final AnimationController _descAnim;
  late final AnimationController _playerEnterAnim;

  String? _directUrl;
  bool _extracting = false;
  bool _extractFailed = false;
  InAppWebViewController? _webCtrl;
  String? _playerHtmlTemplate;

  bool get _isEmpty => widget.videoUrl == null || widget.currentVideo == null;

  @override void initState() {
    super.initState();
    _currentPlaylistIndex = widget.playlistIndex;
    _descAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..forward();
    _playerEnterAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _loadPlayerTemplate();
    if (!_isEmpty) {
      _loadRelated();
      _extractAndPlay(widget.videoUrl!);
    }
  }

  // ── Template ───────────────────────────────────────────────────────────────
  Future<void> _loadPlayerTemplate() async {
    try {
      final html = await rootBundle.loadString('assets/player.html');
      if (mounted) setState(() => _playerHtmlTemplate = html);
    } catch (_) {
      if (mounted) setState(() => _playerHtmlTemplate = _fallbackHtml);
    }
  }

  static const String _fallbackHtml = '''<!DOCTYPE html>
<html><head><meta charset="UTF-8"/>
<meta name="viewport" content="width=device-width,initial-scale=1.0"/>
<style>*{margin:0;padding:0;box-sizing:border-box}
html,body{width:100%;height:100%;background:#000;overflow:hidden}
video{width:100%;height:100%;display:block;object-fit:contain}</style>
</head><body>
<video id="vid" src="{{VIDEO_URL}}" controls autoplay playsinline webkit-playsinline></video>
<script>
document.getElementById("vid").addEventListener("playing",function(){
  if(window.flutter_inappwebview)
    window.flutter_inappwebview.callHandler("onVideoPlaying");
},{once:true});
window.setSystemVolume=function(p){
  var v=document.getElementById("vid");
  if(v){v.volume=p/100;v.muted=(p===0);}
};
</script>
</body></html>''';

  String _buildPlayerHtml(String directUrl) {
    final escaped = directUrl.replaceAll('"', '&quot;');
    return (_playerHtmlTemplate ?? _fallbackHtml).replaceAll('{{VIDEO_URL}}', escaped);
  }

  // ── Extracção ──────────────────────────────────────────────────────────────
  Future<void> _extractAndPlay(String url) async {
    if (!mounted) return;
    setState(() { _extracting = true; _extractFailed = false; _directUrl = null; });

    final direct = await _extractDirectLink(url);
    if (!mounted) return;
    if (direct == null || direct.isEmpty) {
      setState(() { _extracting = false; _extractFailed = true; });
      return;
    }
    setState(() { _directUrl = direct; _extracting = false; });
  }

  // ── Volume sistema ─────────────────────────────────────────────────────────
  Future<void> _startVolumeSync() async {
    try {
      final vol = await VolumeController.instance.getVolume();
      _sendVolumeToPlayer((vol * 100).round());
    } catch (_) {}
    try {
      VolumeController.instance.addListener((vol) {
        _sendVolumeToPlayer((vol * 100).round());
      }, fetchInitialVolume: false);
    } catch (_) {}
  }

  void _sendVolumeToPlayer(int pct) {
    _webCtrl?.evaluateJavascript(source: 'window.setSystemVolume($pct);');
  }

  void _stopVolumeSync() {
    try { VolumeController.instance.removeListener(); } catch (_) {}
  }

  // ── Ciclo de vida ──────────────────────────────────────────────────────────
  @override void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      _descAnim.forward(from: 0.0);
      _playerEnterAnim.forward(from: 0.0);
      _webCtrl = null;
      _stopVolumeSync();
      _extractAndPlay(widget.videoUrl!);
      _loadRelated();
    }
    if (widget.isActive != old.isActive && !widget.isActive) {
      _webCtrl?.evaluateJavascript(source: 'document.getElementById("vid")?.pause()');
    }
  }

  @override void dispose() {
    _descAnim.dispose();
    _playerEnterAnim.dispose();
    _stopVolumeSync();
    super.dispose();
  }

  // ── Download ───────────────────────────────────────────────────────────────
  Future<void> _forceDownload() async {
    if (_directUrl == null) { _snack('A extrair link...'); return; }
    DownloadService.instance.startDownload(
      url: _directUrl!,
      title: widget.currentVideo?.title ?? 'video',
      type: 'video',
      thumbUrl: widget.currentVideo?.thumb ?? '',
      sourceUrl: widget.currentVideo?.videoUrl ?? '',
    );
    _snack('Download iniciado');
  }

  // ── Related ────────────────────────────────────────────────────────────────
  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    setState(() {
      _related..clear()..addAll(videos.where((v) => v.videoUrl != widget.videoUrl).take(20));
      _loadingRelated = false;
    });
  }

  // ── Snack ──────────────────────────────────────────────────────────────────
  void _snack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: t.toastText)),
      backgroundColor: t.toastBg, behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2)));
  }

  // ── Menu ───────────────────────────────────────────────────────────────────
  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset pos) {
    final t = AppTheme.current;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx, color: t.popup, elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        _popItem('save',     'save_later',   'Guardar para assistir mais tarde', t),
        _popItem('playlist', 'playlist_add', 'Adicionar na minha playlist', t),
        _popItem('next',     'play_next',    'Exibir como próximo vídeo', t),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      switch (val) {
        case 'save':     _snack('Guardado para assistir mais tarde'); break;
        case 'playlist': _snack('Adicionado à playlist'); break;
        case 'next':     _snack('Será exibido a seguir'); break;
      }
    });
  }

  PopupMenuItem<String> _popItem(String val, String iconName, String label, AppTheme t) =>
    PopupMenuItem<String>(value: val, height: 46,
      child: Row(children: [
        _SvgIcon(iconName, size: 18, color: t.iconSub),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: t.text, fontSize: 13.5))),
      ]));

  // ── Build ──────────────────────────────────────────────────────────────────
  @override Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video = widget.currentVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark),
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(bottom: false, child: Column(children: [

          // ── Player ──────────────────────────────────────────────────────
          AnimatedBuilder(
            animation: _playerEnterAnim,
            builder: (_, child) => FadeTransition(opacity: _playerEnterAnim,
              child: Transform.translate(
                offset: Offset(0, (1 - _playerEnterAnim.value) * -20), child: child)),
            child: SizedBox(
              width: screenW, height: playerH,
              child: ColoredBox(color: Colors.black,
                child: Stack(children: [

                  // WebView
                  if (_playerHtmlTemplate != null && _directUrl != null)
                    Positioned.fill(
                      child: InAppWebView(
                        initialData: InAppWebViewInitialData(
                          data: _buildPlayerHtml(_directUrl!),
                          mimeType: 'text/html',
                          encoding: 'utf-8',
                        ),
                        initialSettings: InAppWebViewSettings(
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          transparentBackground: true,
                          supportZoom: false,
                          disableHorizontalScroll: true,
                          disableVerticalScroll: true,
                          allowFileAccessFromFileURLs: true,
                          allowUniversalAccessFromFileURLs: true,
                        ),
                        onWebViewCreated: (ctrl) {
                          _webCtrl = ctrl;
                          ctrl.addJavaScriptHandler(
                            handlerName: 'onVideoPlaying',
                            callback: (_) {},
                          );
                          ctrl.addJavaScriptHandler(
                            handlerName: 'onVolumeChange',
                            callback: (args) {
                              if (args.isEmpty) return;
                              final pct = (args[0] as num).toDouble();
                              try { VolumeController.instance.setVolume(pct / 100); } catch (_) {}
                            },
                          );
                        },
                        onLoadStop: (ctrl, _) async => await _startVolumeSync(),
                      ),
                    ),

                  // Spinner (a extrair ou template ainda a carregar)
                  if (_extracting || (_playerHtmlTemplate == null && !_extractFailed))
                    const Positioned.fill(
                      child: ColoredBox(color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Colors.white54, strokeWidth: 1.5)))),

                  // Erro
                  if (_extractFailed)
                    Positioned.fill(child: ColoredBox(color: Colors.black,
                      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _SvgIcon('error_outline', size: 36, color: Colors.white54),
                        const SizedBox(height: 10),
                        const Text('Não foi possível obter o vídeo.',
                            style: TextStyle(color: Colors.white60, fontSize: 12)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _extractAndPlay(widget.videoUrl!),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white54),
                              borderRadius: BorderRadius.circular(8)),
                            child: const Text('Tentar novamente',
                                style: TextStyle(color: Colors.white70, fontSize: 12)))),
                      ])))),

                  // Vazio
                  if (_isEmpty)
                    const Positioned.fill(child: ColoredBox(color: Colors.black)),

                  // Download
                  if (_directUrl != null)
                    Positioned(top: 8, right: 8,
                      child: _SmallBtn(iconName: 'download', onTap: _forceDownload)),
                ])),
            ),
          ),

          // ── Descrição ────────────────────────────────────────────────────
          if (!_isEmpty && video != null)
            AnimatedBuilder(
              animation: _descAnim,
              builder: (_, child) => FadeTransition(opacity: _descAnim,
                child: Transform.translate(
                  offset: Offset(0, (1 - _descAnim.value) * 16), child: child)),
              child: _VideoDescription(video: video),
            ),

          // ── Sugestões ─────────────────────────────────────────────────────
          Expanded(child: _SuggestionsSection(
            loading: _loadingRelated,
            related: _related,
            onVideoTap: (v) {
              final idx = _related.indexOf(v);
              setState(() => _currentPlaylistIndex = idx >= 0 ? idx : 0);
              Navigator.of(context).push(CupertinoPageRoute(builder: (_) => ExibicaoPage(
                videoUrl: v.videoUrl,
                currentVideo: v,
                onVideoTap: widget.onVideoTap,
                isActive: true,
                playlist: _related,
                playlistIndex: idx >= 0 ? idx : 0)));
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
  const _VideoDescription({required this.video});

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
            Text('  ·  ${video.views} vis.',
                style: TextStyle(color: t.textHint, fontSize: 11.5)),
        ]),
        const SizedBox(height: 10),
        Divider(color: t.divider, thickness: 1, height: 1),
        const SizedBox(height: 4),
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
              return _RelatedCard(key: ValueKey(v.videoUrl), video: v, index: i,
                  onTap: () => widget.onVideoTap(v),
                  onMenuTap: (pos) => widget.onMenuTap(v, pos));
            },
            childCount: widget.related.length + 1)),
      ],
    );
  }
}