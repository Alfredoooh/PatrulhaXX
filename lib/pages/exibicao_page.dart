import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'home_page.dart' show kPrimaryColor, FeedVideo, FeedFetcher,
    VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// ─── URLs ─────────────────────────────────────────────────────────────────────
const _kAdsUrl = 'https://patrulhaxx.onrender.com/ads';

// ─── SVGs menu popup ──────────────────────────────────────────────────────────
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
    'm9.659-9.756a1 1 0 1 1 -1-1 1 1 0 0 1 1 1z"/>'
    '</svg>';

const _svgPlaylist =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Filled" viewBox="0 0 24 24">'
    '<path d="M1,6H23a1,1,0,0,0,0-2H1A1,1,0,0,0,1,6Z"/>'
    '<path d="M23,9H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,19H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,14H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M1.707,16.245l2.974-2.974a1.092,1.092,0,0,0,0-1.542L1.707,8.755'
    'A1,1,0,0,0,0,9.463v6.074A1,1,0,0,0,1.707,16.245Z"/>'
    '</svg>';

const _svgPlayNext =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Layer_1" viewBox="0 0 24 24">'
    '<path d="m5,20c0,1.381-1.119,2.5-2.5,2.5s-2.5-1.119-2.5-2.5,1.119-2.5,2.5-2.5,2.5,1.119,2.5,2.5Z'
    'M21.5,6.5c1.381,0,2.5-1.119,2.5-2.5s-1.119-2.5-2.5-2.5-2.5,1.119-2.5,2.5,1.119,2.5,2.5,2.5Z'
    'm-1,8v.5c0,.552.448,1,1,1s1-.448,1-1v-.5c0-2.481-2.019-4.5-4.5-4.5H4.5c-1.378,0-2.5-1.122-2.5-2.5'
    's1.122-2.5,2.5-2.5h9.728l-1.293,1.293c-.391.391-.391,1.023,0,1.414.195.195.451.293.707.293'
    's.512-.098.707-.293l1.972-1.972c.939-.938.939-2.466,0-3.405L14.284.293c-.391-.391-1.023-.391-1.414,0'
    's-.391,1.023,0,1.414l1.293,1.293H4.5C2.019,3,0,5.019,0,7.5s2.019,4.5,4.5,4.5h13.5c1.378,0,2.5,1.122,2.5,2.5Z'
    'm1,3c-1.381,0-2.5,1.119-2.5,2.5s1.119,2.5,2.5,2.5,2.5-1.119,2.5-2.5-1.119-2.5-2.5-2.5Z'
    'm-7.216-1.207c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414l1.293,1.293h-6.163'
    'c-.552,0-1,.448-1,1s.448,1,1,1h6.228l-1.293,1.293c-.391.391-.391,1.023,0,1.414'
    '.195.195.451.293.707.293s.512-.098.707-.293l1.972-1.972c.939-.938.939-2.466,0-3.405l-2.037-2.037Z"/>'
    '</svg>';

const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Outline" viewBox="0 0 24 24">'
    '<path d="M9.878,18.122a3,3,0,0,0,4.244,0l3.211-3.211A1,1,0,0,0,15.919,13.5'
    'l-2.926,2.927L13,1a1,1,0,0,0-1-1h0a1,1,0,0,0-1,1l-.009,15.408L8.081,13.5'
    'a1,1,0,0,0-1.414,1.415Z"/>'
    '<path d="M23,16h0a1,1,0,0,0-1,1v4a1,1,0,0,1-1,1H3a1,1,0,0,1-1-1V17a1,1,0,0,0-1-1H1'
    'a1,1,0,0,0-1,1v4a3,3,0,0,0,3,3H21a3,3,0,0,0,3-3V17A1,1,0,0,0,23,16Z"/>'
    '</svg>';

// ─── SVG play/pause para o player ────────────────────────────────────────────
const _svgPlay =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.492,7.969,8.967.8A4.322,4.322,0,0,0,2.735,4.344V19.667A4.294,4.294,0,0,0,7,24a4.357,4.357,0,0,0,2.232-.62l11.526-7.165a4.321,4.321,0,0,0-.266-8.246Z"/>'
    '</svg>';

const _svgPause =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M6.5,0A3.5,3.5,0,0,0,3,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,6.5,0Z"/>'
    '<path d="M17.5,0A3.5,3.5,0,0,0,14,3.5v17a3.5,3.5,0,0,0,7,0V3.5A3.5,3.5,0,0,0,17.5,0Z"/>'
    '</svg>';


    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M20.807,4.29a1,1,0,0,0-1.415,1.415,8.913,8.913,0,0,1,0,12.59'
    'a1,1,0,0,0,1.415,1.415A10.916,10.916,0,0,0,20.807,4.29Z"/>'
    '<path d="M18.1,7.291A1,1,0,0,0,16.68,8.706a4.662,4.662,0,0,1,0,6.588'
    'A1,1,0,0,0,18.1,16.709,6.666,6.666,0,0,0,18.1,7.291Z"/>'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2ZM13,21.535a10.083,10.083,0,0,1-5.371-4.08'
    'A1,1,0,0,0,6.792,17H5a3,3,0,0,1-3-3V10A3,3,0,0,1,5,7h1.8'
    'a1,1,0,0,0,.837-.453A10.079,10.079,0,0,1,13,2.465Z"/>'
    '</svg>';

const _svgVolOff =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M13.82.2A12.054,12.054,0,0,0,6.266,5H5a5.008,5.008,0,0,0-5,5v4'
    'a5.008,5.008,0,0,0,5,5H6.266A12.059,12.059,0,0,0,13.82,23.8a.917.917,0,0,0,.181.017'
    'a1,1,0,0,0,1-1V1.186A1,1,0,0,0,13.82.2Z"/>'
    '<path d="M22.707,8.293a1,1,0,0,0-1.414,0L20,9.586l-1.293-1.293a1,1,0,0,0-1.414,1.414'
    'L18.586,11l-1.293,1.293a1,1,0,1,0,1.414,1.414L20,12.414l1.293,1.293a1,1,0,0,0,1.414-1.414'
    'L21.414,11l1.293-1.293A1,1,0,0,0,22.707,8.293Z"/>'
    '</svg>';

// ─────────────────────────────────────────────────────────────────────────────
// JS injectado no player após o load
// Faz 3 coisas:
//   1. Carrega hls.js CDN e re-configura o stream HLS com buffer/qualidade
//      reduzidos (~70% menos dados)
//   2. Esconde TODOS os controlos/overlays/banners do site via CSS
//   3. Auto-scroll no RedTube para esconder o header
// ─────────────────────────────────────────────────────────────────────────────
String get _kCleanCss => r"""
  video::-webkit-media-controls,
  video::-webkit-media-controls-enclosure,
  video::-webkit-media-controls-panel { display:none!important; }
  .player-controls,.player-overlay,.video-controls,.vjs-control-bar,
  .plyr__controls,.jwplayer .jw-controls,.fp-controls,
  .redirect-banner,.watch-hd-button,.hd-button,.upgrade-btn,
  .banner,.ad-banner,.popup,.modal,.overlay-redirect,
  [class*="redirect"],[class*="watch-hd"],[class*="upgrade"],
  [class*="notification"],[id*="banner"],
  .site-header,.main-header,#header,.topbar,
  #redtube_header,[class*="header"]:not(video):not(source) { display:none!important; }
  body,html { background:#000!important; margin:0!important; padding:0!important; overflow:hidden!important; }
  video { width:100vw!important; height:100vh!important; object-fit:contain!important;
          display:block!important; position:fixed!important; top:0!important; left:0!important; }
""";

// JS separado para não ter problemas de escape em Dart
String get _kPlayerInitJs => r"""
(function(){
  if(window.__pxDone) return;
  window.__pxDone = true;

  // 1. Injeta CSS de limpeza
  var st = document.createElement('style');
  st.textContent = window.__pxCss || '';
  document.head && document.head.appendChild(st);

  // 2. Remove nós irritantes do DOM
  function clean(){
    ['.redirect-overlay','[class*="redirect"]','[class*="watch-hd"]',
     '.hd-notifier','.upgrade','.notification',
     'header','.header','#header','#redtube_header',
     '.ad','.ads','[id*="ad_"]'].forEach(function(s){
      try{ document.querySelectorAll(s).forEach(function(e){ e.remove(); }); }catch(_){}
    });
    document.querySelectorAll('a,span,div,p').forEach(function(el){
      var txt = (el.innerText||'').toLowerCase();
      if(txt.includes('redirect')||txt.includes('watch in hd')||txt.includes('watch hd')){
        el.style.cssText='display:none!important';
      }
    });
  }
  clean();
  new MutationObserver(clean).observe(document.documentElement,{childList:true,subtree:true});

  // 3. Remove controls do <video>
  function stripControls(){
    document.querySelectorAll('video').forEach(function(v){
      v.removeAttribute('controls');
      v.setAttribute('playsinline','');
      v.setAttribute('webkit-playsinline','');
    });
  }
  stripControls();
  setTimeout(stripControls, 800);
  setTimeout(stripControls, 2000);

  // 4. RedTube: scroll automático para esconder header
  var host = location.hostname || '';
  if(host.indexOf('redtube') >= 0){
    setTimeout(function(){
      try{ window.scrollTo({top:120,behavior:'instant'}); }catch(_){}
    }, 600);
  }

  // 5. hls.js — compressão e redução de dados ~70%
  function setupHls(){
    var v = document.querySelector('video');
    if(!v) return;
    var src = v.currentSrc || v.src || '';
    if(!src){
      var s = v.querySelector('source[src]');
      if(s) src = s.src;
    }
    // Também verifica data-src
    if(!src) src = v.getAttribute('data-src')||v.getAttribute('data-hls-url')||'';

    var isHls = src.indexOf('.m3u8') >= 0 || src.indexOf('m3u8') >= 0;
    if(!isHls) return;

    if(typeof Hls === 'undefined' || !Hls.isSupported()) return;

    // Destrói instância anterior se existir
    if(v.__hls){ try{ v.__hls.destroy(); }catch(_){} }

    var hls = new Hls({
      maxBufferLength: 8,
      maxMaxBufferLength: 16,
      startLevel: 0,           // começa na pior qualidade
      autoLevelCapping: 1,     // nunca passa do 2º nível (70% menos dados)
      capLevelToPlayerSize: true,
      lowLatencyMode: false,
      progressive: false,
      xhrSetup: function(xhr){ xhr.withCredentials = false; }
    });
    hls.loadSource(src);
    hls.attachMedia(v);
    v.__hls = hls;
    hls.on(Hls.Events.MANIFEST_PARSED, function(){ v.play && v.play().catch(function(){}); });
  }

  // Carrega hls.js via CDN e depois configura
  if(typeof Hls === 'undefined'){
    var sc = document.createElement('script');
    sc.src = 'https://cdn.jsdelivr.net/npm/hls.js@1.5.13/dist/hls.min.js';
    sc.onload = setupHls;
    document.head.appendChild(sc);
  } else {
    setupHls();
  }
})();
""";

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width, height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 6});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
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
  Padding(padding: const EdgeInsets.fromLTRB(12,0,12,14),
    child: Row(children: [
      _Shimmer(width: 160, height: 90),
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
// Player de vídeo local (estado vazio — nenhum vídeo selecionado)
// ─────────────────────────────────────────────────────────────────────────────
class _LocalAssetPlayer extends StatefulWidget {
  final bool muted;
  const _LocalAssetPlayer({required this.muted});
  @override State<_LocalAssetPlayer> createState() => _LocalAssetPlayerState();
}

class _LocalAssetPlayerState extends State<_LocalAssetPlayer> {
  late VideoPlayerController _ctrl;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _ctrl = VideoPlayerController.asset('assets/videos/promo.mp4')
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        _ctrl.setLooping(true);
        _ctrl.setVolume(widget.muted ? 0.0 : 1.0);
        _ctrl.play();
      });
  }

  @override
  void didUpdateWidget(_LocalAssetPlayer old) {
    super.didUpdateWidget(old);
    if (old.muted != widget.muted) {
      _ctrl.setVolume(widget.muted ? 0.0 : 1.0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const ColoredBox(color: Colors.black);
    }
    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: _ctrl.value.size.width,
        height: _ctrl.value.size.height,
        child: VideoPlayer(_ctrl),
      ),
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
  /// Controlado pelo IndexedStack pai — pausa/retoma ao trocar de tab
  final bool isActive;

  const ExibicaoPage({
    super.key,
    this.embedUrl,
    this.currentVideo,
    required this.onVideoTap,
    this.isActive = true,
  });

  @override State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool   _loadingRelated = false;
  InAppWebViewController? _webCtrl;
  bool   _titleExpanded  = false;
  bool   _muted          = false;
  bool   _playing        = true;
  bool   _playerLoading  = true;
  FeedVideo? _nextVideo;

  bool get _isEmpty => widget.embedUrl == null || widget.currentVideo == null;

  // ── Lifecycle ───────────────────────────────────────────────────────────────
  @override void initState() {
    super.initState();
    if (!_isEmpty) _loadRelated();
  }

  @override
  void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      setState(() { _titleExpanded = false; _playerLoading = true; });
      _loadRelated();
    }
    // Pausa/retoma ao mudar de tab
    if (widget.isActive != old.isActive) {
      if (!widget.isActive) {
        _webCtrl?.evaluateJavascript(
            source: "document.querySelector('video')?.pause()");
      } else {
        _webCtrl?.evaluateJavascript(
            source: "document.querySelector('video')?.play().catch(()=>{})");
      }
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
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
      backgroundColor: t.toastBg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = widget.currentVideo; if (video == null) return;
    _snack('A capturar link do vídeo...');
    try {
      final result = await _webCtrl!.evaluateJavascript(source: r'''
        (function(){
          var v=document.querySelector('video');
          if(v&&v.src&&v.src.startsWith('http'))return v.src;
          if(v&&v.currentSrc&&v.currentSrc.startsWith('http'))return v.currentSrc;
          var s=document.querySelector('source[src]');
          if(s&&s.src&&s.src.startsWith('http'))return s.src;
          return '__none__';
        })()''');
      final src = result?.toString().replaceAll('"','').trim() ?? '__none__';
      if (!mounted) return;
      if (src == '__none__' || src.isEmpty) { _snack('Inicia a reprodução antes.'); return; }
      DownloadService.instance.startDownload(
        url: src, title: video.title, type: 'video',
        thumbUrl: video.thumb, sourceUrl: video.embedUrl);
      _snack('Download iniciado');
    } catch (_) { if (mounted) _snack('Erro ao capturar o vídeo.'); }
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _webCtrl?.evaluateJavascript(
      source: _playing
          ? "document.querySelector('video')?.play().catch(()=>{})"
          : "document.querySelector('video')?.pause()");
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    if (!_isEmpty) {
      _webCtrl?.evaluateJavascript(
          source: "document.querySelector('video').muted = ${_muted};");
    }
    // O _LocalAssetPlayer recebe o novo valor de muted via didUpdateWidget
  }

  Future<void> _openAdsUrl() async {
    final uri = Uri.parse(_kAdsUrl);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Injeta o CSS e o JS no WebView após o load
  Future<void> _injectJs(InAppWebViewController ctrl) async {
    final escapedCss = _kCleanCss.replaceAll("'", "\\'").replaceAll('\n', '\\n');
    await ctrl.evaluateJavascript(source: "window.__pxCss = '$escapedCss';");
    await ctrl.evaluateJavascript(source: _kPlayerInitJs);
  }

  // ── Popup menu três pontinhos ────────────────────────────────────────────────
  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset globalPos) {
    final t = AppTheme.current;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx,
      color: t.popup,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(
        globalPos & const Size(1, 1),
        Offset.zero & overlay.size,
      ),
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
        case 'next':
          setState(() => _nextVideo = v);
          _snack('Será exibido a seguir');
          break;
      }
    });
  }

  PopupMenuItem<String> _popItem(String val, String svg, String label, AppTheme t) {
    return PopupMenuItem<String>(
      value: val,
      height: 46,
      child: Row(children: [
        SvgPicture.string(svg, width: 18, height: 18,
            colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(color: t.text, fontSize: 13.5))),
      ]),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video   = widget.currentVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(children: [

          SizedBox(height: topPad),

          // ── Player — container preto, sem margem, sem scroll lateral ────────
          SizedBox(
            width: screenW,
            height: playerH,
            child: ColoredBox(
              color: Colors.black,
              child: Stack(children: [

                // ── Vídeo local (estado vazio) ou WebView (vídeo selecionado) ─
                Positioned.fill(
                  child: _isEmpty
                      ? _LocalAssetPlayer(muted: _muted)
                      : InAppWebView(
                          key: ValueKey(widget.embedUrl),
                          initialUrlRequest: URLRequest(url: WebUri(widget.embedUrl!)),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                            transparentBackground: true,
                            disableDefaultErrorPage: true,
                            disableHorizontalScroll: true,
                            disableVerticalScroll: false,
                            supportZoom: false,
                            builtInZoomControls: false,
                            displayZoomControls: false,
                            horizontalScrollBarEnabled: false,
                            verticalScrollBarEnabled: false,
                            userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
                                'AppleWebKit/537.36 (KHTML, like Gecko) '
                                'Chrome/124.0.0.0 Mobile Safari/537.36',
                          ),
                          onWebViewCreated: (ctrl) {
                            _webCtrl = ctrl;
                            if (_muted) {
                              ctrl.evaluateJavascript(
                                  source: "document.querySelector('video')&&(document.querySelector('video').muted=true)");
                            }
                          },
                          onLoadStop: (ctrl, _) async {
                            await _injectJs(ctrl);
                            if (mounted) setState(() => _playerLoading = false);
                          },
                          shouldOverrideUrlLoading: (ctrl, action) async {
                            final url = action.request.url?.toString() ?? '';
                            final ok = url.contains('/embed/') ||
                                url.contains('embed.redtube') ||
                                url.contains('youporn.com/embed') ||
                                url == widget.embedUrl ||
                                url.startsWith('about:') ||
                                url.startsWith('blob:') ||
                                url.startsWith('data:') ||
                                url.isEmpty;
                            return ok ? NavigationActionPolicy.ALLOW : NavigationActionPolicy.CANCEL;
                          },
                        ),
                ),

                // Thumbnail enquanto carrega (como YouTube) — só no WebView
                if (!_isEmpty && _playerLoading)
                  Positioned.fill(
                    child: Stack(children: [
                      if (video?.thumb != null && video!.thumb.isNotEmpty)
                        Image.network(video.thumb,
                          fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                          headers: const {'User-Agent': 'Mozilla/5.0'},
                          errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black),
                        ),
                      Container(color: Colors.black38),
                      const Center(child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 1.5)),
                    ]),
                  ),

                // Botão play/pause — centro do player
                if (!_isEmpty)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _togglePlay,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: _playing ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Container(
                            width: 54, height: 54,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SvgPicture.string(
                                _playing ? _svgPause : _svgPlay,
                                width: 22, height: 22,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white, BlendMode.srcIn),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Botões bottom-right: mudo + download
                Positioned(
                  bottom: 8, right: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _PlayerBtn(svg: _muted ? _svgVolOff : _svgVolOn, onTap: _toggleMute),
                      const SizedBox(height: 8),
                      _PlayerBtn(svg: _svgDl, onTap: _forceDownload),
                    ],
                  ),
                ),
              ]),
            ),
          ),

          // ── Corpo ─────────────────────────────────────────────────────────
          Expanded(
            child: _isEmpty
                ? _EmptyBody(onAdsLinkTap: _openAdsUrl)
                : ListView(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    children: [

                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Título
                            GestureDetector(
                              onTap: () => setState(() => _titleExpanded = !_titleExpanded),
                              child: Text(video!.title,
                                style: TextStyle(color: t.text, fontSize: 14.5,
                                    fontWeight: FontWeight.w600, height: 1.3),
                                maxLines: _titleExpanded ? null : 2,
                                overflow: _titleExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(faviconForSource(video.source),
                                  width: 15, height: 15,
                                  errorBuilder: (_, __, ___) => const SizedBox(width: 15, height: 15)),
                              ),
                              const SizedBox(width: 5),
                              Text(video.sourceLabel,
                                  style: TextStyle(color: t.textSecondary,
                                      fontSize: 11.5, fontWeight: FontWeight.w500)),
                              if (video.views.isNotEmpty)
                                Text('  ·  ${video.views} vis.',
                                    style: TextStyle(color: t.textHint, fontSize: 11.5)),
                            ]),

                            const SizedBox(height: 12),
                            Divider(color: t.divider, thickness: 1, height: 1),
                            const SizedBox(height: 12),

                            // Card de próximo vídeo — estilo playlist cor-de-rosa
                            if (_nextVideo != null) ...[
                              GestureDetector(
                                onTap: () {
                                  widget.onVideoTap(_nextVideo!);
                                  setState(() => _nextVideo = null);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: t.isDark
                                        ? const Color(0xFF2A1A1A)
                                        : const Color(0xFFFFF0F0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: t.isDark
                                          ? const Color(0xFF5A2020)
                                          : const Color(0xFFFFCCCC),
                                    ),
                                  ),
                                  child: Row(children: [
                                    SvgPicture.string(_svgPlaylist,
                                        width: 16, height: 16,
                                        colorFilter: ColorFilter.mode(
                                            AppTheme.ytRed, BlendMode.srcIn)),
                                    const SizedBox(width: 10),
                                    Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Seguinte:',
                                            style: TextStyle(
                                                color: AppTheme.ytRed,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 2),
                                        Text(_nextVideo!.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: t.text,
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w600)),
                                        Text(_nextVideo!.sourceLabel,
                                            style: TextStyle(
                                                color: t.textSecondary,
                                                fontSize: 11)),
                                      ],
                                    )),
                                    GestureDetector(
                                      onTap: () => setState(() => _nextVideo = null),
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: Icon(Icons.close_rounded,
                                            color: t.iconTertiary, size: 18),
                                      ),
                                    ),
                                  ]),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            Text('Relacionados',
                                style: TextStyle(color: t.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),

                      if (_loadingRelated)
                        Column(children: _skeletonCards(5))
                      else
                        ..._related.map((v) => _RelatedCard(
                              video: v,
                              onTap: () {
                                if (_nextVideo?.embedUrl == v.embedUrl) setState(() => _nextVideo = null);
                                widget.onVideoTap(v);
                              },
                              onMenuTap: (pos) => _showVideoMenu(context, v, pos),
                            )),

                      const SizedBox(height: 24),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ─── Botão flutuante do player (mudo) ─────────────────────────────────────────
class _PlayerBtn extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  const _PlayerBtn({required this.svg, required this.onTap});
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34, height: 34,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.58), shape: BoxShape.circle),
      child: Center(child: SvgPicture.string(svg, width: 16, height: 16,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn))),
    ),
  );
}

// ─── Estado vazio — layout idêntico à imagem ──────────────────────────────────
class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdsLinkTap;
  const _EmptyBody({required this.onAdsLinkTap});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [

        // ── Bloco de info — colado ao player, fundo surface ──────────────────
        Container(
          color: t.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bem-vindo ao nuxx',
                style: TextStyle(
                  color: t.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Selecione qualquer vídeo na aba feed para ser exibido aqui...',
                style: TextStyle(
                  color: t.textSecondary,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onAdsLinkTap,
                child: Text(
                  'Publicitar minha marca',
                  style: TextStyle(
                    color: t.link,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                    decorationColor: t.link,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Gato Lottie — ocupa o espaço restante, centrado ─────────────────
        Expanded(
          child: Center(
            child: SizedBox(
              width: 200, height: 200,
              child: Lottie.asset(
                'assets/lottie/Cat_playing_animation.json',
                repeat: true, animate: true,
                errorBuilder: (_, __, ___) => SvgPicture.string(
                  svgExibicaoOutline, width: 72, height: 72,
                  colorFilter: ColorFilter.mode(t.emptyIcon, BlendMode.srcIn)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Card relacionado ─────────────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  const _RelatedCard({required this.video, required this.onTap, required this.onMenuTap});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              SizedBox(width: 160, height: 90,
                child: Image.network(video.thumb, fit: BoxFit.cover, cacheWidth: 320,
                  headers: const {'User-Agent': 'Mozilla/5.0'},
                  errorBuilder: (_, __, ___) => Container(width: 160, height: 90, color: t.card,
                    child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 28))),
                  loadingBuilder: (_, child, p) => p == null ? child : _Shimmer(width: 160, height: 90),
                ),
              ),
              if (video.duration.isNotEmpty)
                Positioned(bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),

          const SizedBox(width: 10),

          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(video.title,
              style: TextStyle(color: t.text, fontSize: 12.5, fontWeight: FontWeight.w500, height: 1.35),
              maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 5),
            Row(children: [
              ClipRRect(borderRadius: BorderRadius.circular(7),
                child: Image.network(faviconForSource(video.source), width: 12, height: 12,
                  errorBuilder: (_, __, ___) => const SizedBox(width: 12, height: 12))),
              const SizedBox(width: 4),
              Expanded(child: Text(
                '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                style: TextStyle(color: t.textHint, fontSize: 11),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
            ]),
          ])),

          // Three-dot — captura posição global exacta do toque
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onMenuTap(d.globalPosition),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 18),
            ),
          ),
        ]),
      ),
    );
  }
}
