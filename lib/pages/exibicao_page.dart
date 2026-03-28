import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:animations/animations.dart';
import 'home_page.dart'
    show kPrimaryColor, FeedVideo, FeedFetcher, VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

const _kAdsUrl = 'https://patrulhaxx.onrender.com/ads';

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

String get _kCss0Stealth => r"""
  video::-webkit-media-controls,video::-webkit-media-controls-enclosure,
  video::-webkit-media-controls-panel,video::-webkit-media-controls-play-button,
  video::-webkit-media-controls-start-playback-button,
  video::-webkit-media-controls-timeline,video::-webkit-media-controls-current-time-display,
  video::-webkit-media-controls-time-remaining-display,
  video::-webkit-media-controls-mute-button,video::-webkit-media-controls-volume-slider,
  video::-webkit-media-controls-fullscreen-button,
  video::-webkit-media-controls-overflow-button,
  video::-internal-media-controls-download-button,
  video::-webkit-media-controls-overlay-play-button,
  video::-webkit-media-controls-overlay-enclosure {
    display:none!important;visibility:hidden!important;
    opacity:0!important;pointer-events:none!important;
  }
  .vjs-control-bar,.vjs-big-play-button,.vjs-loading-spinner,.vjs-poster,
  .vjs-overlay,.vjs-modal-dialog,.vjs-error-display,.vjs-text-track-display,
  .vjs-playback-rate,.vjs-chapters-button,.vjs-progress-control,
  .video-js .vjs-big-play-button{display:none!important;}
  .jw-controls,.jw-display,.jw-nextup-container,.jw-logo,.jw-dock,
  .jw-captions,.jw-rightclick,.jw-overlays,.jw-controlbar,.jw-icon,
  .jw-button-container{display:none!important;}
  .plyr__controls,.plyr__captions,.plyr__menu,.plyr__progress,.plyr__volume{display:none!important;}
  .ep-logo,.ep-controls,.ep-related,.ep-title,.ep-overlay,
  #eporner-logo,#ep-logo,.eporner-header,.eporner-footer,
  [class*="eporner-nav"],[id*="eporner-ad"]{display:none!important;}
  .pc-overlay,.pc-info-block,.ph-logo,.pc-header,.pc-footer,
  .pc-subscribe-now,.pc-age-gate,.ageGate,.age-gate-wrapper,
  .pcRecoverContent,.removeForEmbed,.pc-overlay-transparent,
  #pc-user-info,.pc-nav,.pc-tabs,.pc-ad,.pc-rating-wrap,
  [class*="pcHeader"],[class*="pc-header"],[id*="pc-header"],
  #player-controls,.player-controls,.playerControlBar,
  .playbackControls,.playerOverlay,[class*="playerControl"],
  [class*="controls-bar"],[id*="controls"]{display:none!important;}
  .redtube-logo,.rt-logo,.site-controls,.embed-logo,
  #redtube_header,.redtube-header,.rt-header,.embed-header,
  .site-branding,.embed-branding,.embed-play-wrap,
  [class*="redtube"],[id*="redtube"]{display:none!important;}
  .xha-header,.xha-logo,.xha-footer,.xha-overlay,
  [class*="xha-"],[class*="ham-header"]{display:none!important;}
  .xv-logo,.xvideos-logo,.xv-header,
  [class*="xvideos-"],[class*="xv-logo"]{display:none!important;}
  .sb-header,.sb-logo,.sb-footer,[class*="spankbang-"]{display:none!important;}
  .redirect-banner,.watch-hd-button,.hd-button,.upgrade-btn,.banner,.ad-banner,
  .popup,.modal,.overlay-redirect,.age-gate,.age-gate-container,
  .age-verification,.agewall,.cookie-consent,.gdpr,.consent-banner,
  [class*="redirect"],[class*="watch-hd"],[class*="upgrade"],
  [class*="age-gate"],[class*="banner"],[class*="popup"],
  [class*="modal"],[class*="overlay"]{display:none!important;}
  body,html{overflow:hidden!important;background:#000!important;}
  video{width:100%!important;height:100%!important;object-fit:contain!important;}
""";

String get _kJsTakeover => r"""
(function(){if(window.__pxTakeover)return;window.__pxTakeover=true;
const css=document.createElement('style');css.textContent=`""" +
    _kCss0Stealth +
    r"""`;document.head.insertBefore(css,document.head.firstChild);
let realVideo=null;
function findVideo(){const all=document.querySelectorAll('video');
for(const v of all)if(v.src||v.querySelector('source')){realVideo=v;return v;}
return null;}
setTimeout(()=>{const v=findVideo();if(v){v.controls=false;v.setAttribute('playsinline','');
v.setAttribute('webkit-playsinline','');v.removeAttribute('controls');}},100);
setInterval(()=>{const v=findVideo();if(v&&v.controls){v.controls=false;
v.removeAttribute('controls');}},300);
window.addEventListener('message',e=>{if(!e.data||!e.data.cmd)return;const v=realVideo||findVideo();
if(!v)return;const c=e.data.cmd;if(c==='play')v.play().catch(()=>{});
else if(c==='pause')v.pause();else if(c==='mute')v.muted=!v.muted;
else if(c==='seek'&&e.data.to!=null)v.currentTime=e.data.to;});
new MutationObserver(()=>{const all=document.querySelectorAll('video');
for(const v of all){v.controls=false;v.removeAttribute('controls');}
}).observe(document.documentElement,{childList:true,subtree:true,attributes:true});
})();
""";

class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final FeedVideo? video;
  final VoidCallback onClose;
  const ExibicaoPage({
    super.key,
    this.embedUrl,
    this.video,
    required this.onClose,
  });
  @override
  State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with TickerProviderStateMixin {
  InAppWebViewController? _ctrl;
  bool _playing = false, _muted = false;
  final _fetcher = FeedFetcher();
  final _related = <FeedVideo>[];
  bool _loadingRelated = false;

  late AnimationController _slideUpAnim;
  late AnimationController _fadeInAnim;
  late Animation<Offset> _slideUpOffset;
  late Animation<double> _fadeInOpacity;

  @override
  void initState() {
    super.initState();
    _slideUpAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeInAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideUpOffset = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideUpAnim,
      curve: Curves.easeOutCubic,
    ));
    _fadeInOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeInAnim, curve: Curves.easeIn),
    );

    if (widget.video != null) {
      _slideUpAnim.forward();
      _fadeInAnim.forward();
      _loadRelated();
    }
  }

  @override
  void dispose() {
    _slideUpAnim.dispose();
    _fadeInAnim.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ExibicaoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.video != oldWidget.video && widget.video != null) {
      _playing = false;
      _muted = false;
      _related.clear();
      _slideUpAnim.reset();
      _fadeInAnim.reset();
      _slideUpAnim.forward();
      _fadeInAnim.forward();
      _loadRelated();
    }
  }

  Future<void> _loadRelated() async {
    if (_loadingRelated) return;
    setState(() => _loadingRelated = true);
    try {
      final videos = await _fetcher.fetchMixed();
      if (mounted) {
        setState(() {
          _related.addAll(videos.take(10));
          _loadingRelated = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingRelated = false);
    }
  }

  void _sendCmd(String cmd, [Map<String, dynamic>? extra]) {
    final msg = {'cmd': cmd, ...?extra};
    _ctrl?.evaluateJavascript(source: 'window.postMessage(${jsonEncode(msg)},"*");');
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _sendCmd(_playing ? 'play' : 'pause');
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _sendCmd('mute');
  }

  void _onRelatedTap(FeedVideo v) {
    setState(() {
      _playing = false;
      _muted = false;
    });
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ExibicaoPage(
          embedUrl: v.embedUrl,
          video: v,
          onClose: widget.onClose,
        ),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut),
            child: child,
          );
        },
      ),
    );
  }

  void _onMenuTap(FeedVideo v, Offset pos) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(pos.dx, pos.dy, pos.dx, pos.dy),
      items: [
        PopupMenuItem(
          child: Row(children: [
            SvgPicture.string(_svgPlayNext, width: 18, height: 18,
                colorFilter: ColorFilter.mode(AppTheme.current.text, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text('Reproduzir a seguir',
                style: TextStyle(color: AppTheme.current.text, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          child: Row(children: [
            SvgPicture.string(_svgPlaylist, width: 18, height: 18,
                colorFilter: ColorFilter.mode(AppTheme.current.text, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text('Adicionar à playlist',
                style: TextStyle(color: AppTheme.current.text, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          child: Row(children: [
            SvgPicture.string(_svgSaveLater, width: 18, height: 18,
                colorFilter: ColorFilter.mode(AppTheme.current.text, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text('Guardar para mais tarde',
                style: TextStyle(color: AppTheme.current.text, fontSize: 14)),
          ]),
        ),
        PopupMenuItem(
          onTap: () => _downloadVideo(v),
          child: Row(children: [
            SvgPicture.string(_svgDl, width: 18, height: 18,
                colorFilter: ColorFilter.mode(AppTheme.current.text, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text('Download',
                style: TextStyle(color: AppTheme.current.text, fontSize: 14)),
          ]),
        ),
      ],
    );
  }

  Future<void> _downloadVideo(FeedVideo v) async {
    try {
      await DownloadService.instance.addDownload(
        url: v.embedUrl,
        title: v.title,
        thumb: v.thumb,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download adicionado: ${v.title}'),
          action: SnackBarAction(
            label: 'Ver',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DownloadListPage()),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar download: $e')),
      );
    }
  }

  void _openAds() async {
    final uri = Uri.parse(_kAdsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final safeTop = MediaQuery.of(context).padding.top;

    if (widget.video == null || widget.embedUrl == null) {
      return _EmptyBody(onAdsLinkTap: _openAds);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(children: [
          Column(children: [
            SizedBox(
              height: 280,
              child: Stack(fit: StackFit.expand, children: [
                if (widget.embedUrl != null)
                  Transform.scale(
                    scale: 0.01,
                    child: Opacity(
                      opacity: 0.01,
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(widget.embedUrl!)),
                        initialSettings: InAppWebViewSettings(
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          javaScriptEnabled: true,
                          userAgent: 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
                        ),
                        onWebViewCreated: (c) => _ctrl = c,
                        onLoadStop: (c, url) async {
                          await c.evaluateJavascript(source: _kJsTakeover);
                        },
                      ),
                    ),
                  ),
                Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.video!.thumb),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(color: Colors.black.withOpacity(0.3)),
                  ),
                ),
                Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(widget.video!.thumb),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: safeTop + 8,
                  left: 8,
                  child: FadeTransition(
                    opacity: _fadeInOpacity,
                    child: GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: FadeTransition(
                    opacity: _fadeInOpacity,
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      _PlayerBtn(
                        svg: _muted ? _svgVolOff : _svgVolOn,
                        onTap: _toggleMute,
                      ),
                      const SizedBox(width: 16),
                      _PlayerBtn(
                        svg: _playing ? _svgPause : _svgPlay,
                        onTap: _togglePlay,
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            Expanded(
              child: Stack(children: [
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const SizedBox(height: 120),
                    if (_related.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                        child: SlideTransition(
                          position: _slideUpOffset,
                          child: FadeTransition(
                            opacity: _fadeInOpacity,
                            child: Text('Sugestões',
                                style: TextStyle(color: t.text, fontSize: 16,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ),
                    ..._related.map((v) => SlideTransition(
                      position: _slideUpOffset,
                      child: FadeTransition(
                        opacity: _fadeInOpacity,
                        child: _RelatedCard(
                          video: v,
                          onTap: () => _onRelatedTap(v),
                          onMenuTap: (pos) => _onMenuTap(v, pos),
                        ),
                      ),
                    )),
                    if (_loadingRelated)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SlideTransition(
                    position: _slideUpOffset,
                    child: FadeTransition(
                      opacity: _fadeInOpacity,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              t.isDark
                                  ? Colors.black
                                  : Colors.white,
                              t.isDark
                                  ? Colors.black.withOpacity(0)
                                  : Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.video!.title,
                                style: TextStyle(color: t.text, fontSize: 15.5,
                                    fontWeight: FontWeight.w600, height: 1.3),
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 6),
                            Row(children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: t.avatarBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    widget.video!.sourceLabel[0],
                                    style: TextStyle(
                                      color: t.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(widget.video!.sourceLabel,
                                  style: TextStyle(color: t.textSecondary,
                                      fontSize: 12.5, fontWeight: FontWeight.w500)),
                              if (widget.video!.views.isNotEmpty) ...[
                                Text('  ·  ',
                                    style: TextStyle(color: t.textSecondary,
                                        fontSize: 12.5)),
                                Text('${widget.video!.views} visualizações',
                                    style: TextStyle(color: t.textSecondary,
                                        fontSize: 12.5)),
                              ],
                            ]),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _PlayerBtn extends StatefulWidget {
  final String svg;
  final VoidCallback onTap;
  const _PlayerBtn({required this.svg, required this.onTap});

  @override
  State<_PlayerBtn> createState() => _PlayerBtnState();
}

class _PlayerBtnState extends State<_PlayerBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
              )
            ],
          ),
          child: Center(
            child: SvgPicture.string(
              widget.svg,
              width: 22,
              height: 22,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdsLinkTap;
  const _EmptyBody({required this.onAdsLinkTap});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          color: t.surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Bem-vindo ao PixlHub',
                style: TextStyle(
                    color: t.text,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2)),
            const SizedBox(height: 6),
            Text('Selecione qualquer vídeo na aba feed para ser exibido aqui...',
                style: TextStyle(color: t.textSecondary, fontSize: 13.5, height: 1.4)),
            const SizedBox(height: 8),
            GestureDetector(
                onTap: onAdsLinkTap,
                child: Text('Publicitar minha marca',
                    style: TextStyle(
                        color: t.emptyLinkText,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: t.emptyLinkText))),
          ])),
      Expanded(
          child: Center(
              child: SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset('assets/lottie/Cat_playing_animation.json',
                      repeat: true,
                      animate: true,
                      errorBuilder: (_, __, ___) => SvgPicture.string(
                          svgExibicaoOutline,
                          width: 72,
                          height: 72,
                          colorFilter: ColorFilter.mode(t.emptyIcon, BlendMode.srcIn)))))),
    ]);
  }
}

class _RelatedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  const _RelatedCard({
    required this.video,
    required this.onTap,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: 160,
            height: 90,
            child: Stack(fit: StackFit.expand, children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  video.thumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: t.thumbBg,
                    child: Center(
                      child: Icon(Icons.play_circle_outline_rounded,
                          color: t.iconSub, size: 32),
                    ),
                  ),
                ),
              ),
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 4,
                  right: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(video.duration,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                    style: TextStyle(
                        color: t.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                    '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                    style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onMenuTap(d.globalPosition),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 20),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  final double radius;
  const _Shimmer({this.radius = 0});
  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      decoration: BoxDecoration(
        color: t.thumbBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
