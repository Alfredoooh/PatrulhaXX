import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:animations/animations.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_results_page.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../services/theme_service.dart';
import 'exibicao_page.dart';
import 'explore_page.dart';
import '../theme/app_theme.dart';

const kPrimaryColor = Color(0xFFFF9000);

const svgExibicaoOutline = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"
     stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
  <rect x="2" y="3" width="20" height="14" rx="2"/>
  <path d="M8 21h8M12 17v4"/>
  <polygon points="10,8 16,11 10,14" fill="currentColor" stroke="none"/>
</svg>
''';


const _shortsJs = r"""
(function() {
  if (window.__pxShortsInit) return;
  window.__pxShortsInit = true;
  var d = new Date(); d.setFullYear(d.getFullYear() + 2);
  var exp = '; expires=' + d.toUTCString() + '; path=/';
  ['age_verified=1','platform=pc','_tc=1','hasVisited=1',
   'cookieConsent=1','accessAgeDisclaimerPH=1','accessPH=1'].forEach(function(c){
    document.cookie = c + exp;
  });
  function cleanPage() {
    document.querySelectorAll(
      '.age-gate,#age-gate,.AgeGate,[class*="ageGate"],[class*="age-gate"],' +
      '[id*="age-gate"],.cookieBanner,.cookie-banner,[class*="cookie-banner"],' +
      '.gdpr-banner,[class*="gdpr"],[class*="consent"],[class*="Consent"],' +
      '.limited-functionality,.tabs-container,.age-wall,[class*="ageWall"]'
    ).forEach(function(el) { el.remove(); });
    document.body.style.overflow = '';
    document.documentElement.style.overflow = '';
    document.body.style.background = '#000';
    document.documentElement.style.background = '#000';
    var style = document.getElementById('__px_style');
    if (!style) {
      style = document.createElement('style');
      style.id = '__px_style';
      style.textContent = '* { text-decoration: none !important; } a { text-decoration: none !important; }';
      document.head.appendChild(style);
    }
    ['header','footer','.header','.footer','nav#top','#header'].forEach(function(s) {
      var el = document.querySelector(s);
      if (el) el.style.display = 'none';
    });
    (function walkText(node) {
      if (node.nodeType === 3) {
        node.textContent = node.textContent.replace(/PornHub|Pornhub|pornhub/g, 'patrulhaXX');
      } else if (node.nodeType === 1 &&
          !['SCRIPT','STYLE','INPUT','TEXTAREA'].includes(node.tagName)) {
        node.childNodes.forEach(walkText);
      }
    })(document.body);
    document.querySelectorAll('img').forEach(function(img) {
      var src = (img.getAttribute('src') || '').toLowerCase();
      if (src.includes('logo')) img.style.visibility = 'hidden';
    });
  }
  cleanPage();
  new MutationObserver(function() { cleanPage(); })
    .observe(document.documentElement, { childList: true, subtree: true });
  function tryClickAgeBtn() {
    ['[data-role="age-gate-submit"]','.age-gate__submit','.button-cta',
     'button[class*="confirm"]','button[class*="accept"]','button.bg-primary',
     'button[class*="enter"]','.enter-btn','.js-accept'].forEach(function(sel) {
      var btn = document.querySelector(sel);
      if (btn) btn.click();
    });
    cleanPage();
  }
  setTimeout(tryClickAgeBtn, 300);
  setTimeout(tryClickAgeBtn, 900);
  setTimeout(cleanPage, 2000);
  setTimeout(cleanPage, 4000);
})();
""";

// ─────────────────────────────────────────────────────────────────────────────
// Animação nativa iOS (Cupertino slide from right)
// ─────────────────────────────────────────────────────────────────────────────
Route<T> _iosRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    pageBuilder: (_, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (_, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      final pushSlide = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0),
      ).animate(CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      return SlideTransition(
        position: pushSlide,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// kSites — lista expandida de sites
// ─────────────────────────────────────────────────────────────────────────────
final kSites = <SiteModel>[
  SiteModel(id: 'pornhub',    name: 'Pornhub',    baseUrl: 'https://www.pornhub.com',    allowedDomain: 'pornhub.com',    searchUrl: 'https://www.pornhub.com/video/search?search=',   primaryColor: const Color(0xFFFF9000)),
  SiteModel(id: 'xvideos',   name: 'XVideos',    baseUrl: 'https://www.xvideos.com',    allowedDomain: 'xvideos.com',    searchUrl: 'https://www.xvideos.com/?k=',                     primaryColor: const Color(0xFF1A1A1A)),
  SiteModel(id: 'xhamster',  name: 'xHamster',   baseUrl: 'https://xhamster.com',       allowedDomain: 'xhamster.com',   searchUrl: 'https://xhamster.com/search/',                    primaryColor: const Color(0xFFE8630A)),
  SiteModel(id: 'redtube',   name: 'RedTube',    baseUrl: 'https://www.redtube.com',    allowedDomain: 'redtube.com',    searchUrl: 'https://www.redtube.com/?search=',                primaryColor: const Color(0xFFD40000)),
  SiteModel(id: 'youporn',   name: 'YouPorn',    baseUrl: 'https://www.youporn.com',    allowedDomain: 'youporn.com',    searchUrl: 'https://www.youporn.com/search/video/?query=',    primaryColor: const Color(0xFF0D0D0D)),
  SiteModel(id: 'spankbang', name: 'SpankBang',  baseUrl: 'https://spankbang.com',      allowedDomain: 'spankbang.com',  searchUrl: 'https://spankbang.com/s/',                        primaryColor: const Color(0xFFE3272D)),
  SiteModel(id: 'eporner',   name: 'Eporner',    baseUrl: 'https://www.eporner.com',    allowedDomain: 'eporner.com',    searchUrl: 'https://www.eporner.com/search/',                 primaryColor: const Color(0xFF2196F3)),
  SiteModel(id: 'xnxx',      name: 'XNXX',       baseUrl: 'https://www.xnxx.com',       allowedDomain: 'xnxx.com',       searchUrl: 'https://www.xnxx.com/search/',                    primaryColor: const Color(0xFF1A1A1A)),
  SiteModel(id: 'tube8',     name: 'Tube8',      baseUrl: 'https://www.tube8.com',      allowedDomain: 'tube8.com',      searchUrl: 'https://www.tube8.com/search/video/?search=',     primaryColor: const Color(0xFFFF6600)),
  SiteModel(id: 'txxx',      name: 'TXXX',       baseUrl: 'https://www.txxx.com',       allowedDomain: 'txxx.com',       searchUrl: 'https://www.txxx.com/search/',                    primaryColor: const Color(0xFF333333)),
  SiteModel(id: 'bravotube', name: 'BravoTube',  baseUrl: 'https://www.bravotube.net',  allowedDomain: 'bravotube.net',  searchUrl: 'https://www.bravotube.net/search/',               primaryColor: const Color(0xFFE53935)),
  SiteModel(id: 'drtuber',   name: 'DrTuber',    baseUrl: 'https://www.drtuber.com',    allowedDomain: 'drtuber.com',    searchUrl: 'https://www.drtuber.com/search/video/',           primaryColor: const Color(0xFF009688)),
  SiteModel(id: 'gotporn',   name: 'GotPorn',    baseUrl: 'https://www.gotporn.com',    allowedDomain: 'gotporn.com',    searchUrl: 'https://www.gotporn.com/search/',                 primaryColor: const Color(0xFFFF5722)),
  SiteModel(id: 'porndig',   name: 'PornDig',    baseUrl: 'https://www.porndig.com',    allowedDomain: 'porndig.com',    searchUrl: 'https://www.porndig.com/search/',                 primaryColor: const Color(0xFFAA00FF)),
  SiteModel(id: 'hclips',    name: 'HClips',     baseUrl: 'https://hclips.com',         allowedDomain: 'hclips.com',     searchUrl: 'https://hclips.com/search/',                      primaryColor: const Color(0xFFCC2200)),
  SiteModel(id: 'fuq',       name: 'Fuq',        baseUrl: 'https://www.fuq.com',        allowedDomain: 'fuq.com',        searchUrl: 'https://www.fuq.com/search/?q=',                  primaryColor: const Color(0xFF222222)),
  SiteModel(id: 'porntube',  name: 'PornTube',   baseUrl: 'https://www.porntube.com',   allowedDomain: 'porntube.com',   searchUrl: 'https://www.porntube.com/search?term=',           primaryColor: const Color(0xFFDD2222)),
  SiteModel(id: 'sunporno',  name: 'SunPorno',   baseUrl: 'https://www.sunporno.com',   allowedDomain: 'sunporno.com',   searchUrl: 'https://www.sunporno.com/search/',                primaryColor: const Color(0xFFFF8C00)),
];


// ─────────────────────────────────────────────────────────────────────────────
// HomePage
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 1;
  int _previousTab = 1;
  String? _selectedEmbedUrl;
  FeedVideo? _selectedVideo;
  bool _miniPlayerActive = false;
  late final AnimationController _fadeIn;
  late final AnimationController _tabAnim;

  Color _wallpaperColor = Colors.black;

  static const _kNavH = 62.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 340));
    _tabAnim.value = 1.0;
    final saved = ThemeService.instance.wallpaperColor;
    if (saved != null) _wallpaperColor = saved;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) {
        _fadeIn.forward();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeIn.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  void _openSite(SiteModel site) => Navigator.push(
      context, _iosRoute(BrowserPage(site: site)));

  void _onColorExtracted(Color c) {
    if (mounted) {
      setState(() => _wallpaperColor = c);
      ThemeService.instance.setWallpaperColor(c);
    }
  }

  void _openDownloads() => Navigator.push(context,
      _iosRoute(const DownloadsPage()));

  void _openSettings() => Navigator.push(context,
      _iosRoute(const SettingsPage()));

  void _switchTab(int i) {
    if (i == _tab) return;
    setState(() {
      _previousTab = _tab;
      if (i != 2 && _tab == 2 && _selectedVideo != null) {
        _miniPlayerActive = true;
      } else if (i == 2) {
        _miniPlayerActive = false;
      }
      _tab = i;
    });
    _tabAnim.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.current.statusBar,
      ),
      child: Scaffold(
        key: _scaffoldKey,
        extendBody: false,
        backgroundColor: AppTheme.current.bg,
        drawer: _NavDrawer(
          onDownloads: () { _scaffoldKey.currentState?.closeDrawer(); _openDownloads(); },
          onSettings:  () { _scaffoldKey.currentState?.closeDrawer(); _openSettings(); },
        ),
        body: Column(children: [
          Expanded(
            child: AnimatedBuilder(
              animation: ThemeService.instance,
              builder: (_, __) {
                return AnimatedBuilder(
                  animation: _tabAnim,
                  builder: (_, child) => FadeTransition(
                    opacity: _tabAnim,
                    child: child,
                  ),
                  child: IndexedStack(
                    index: _tab,
                    children: [
                      _HomeTab(
                        fadeIn: _fadeIn,
                        navBottom: 0,
                        onOpen: _openSite,
                        onDownloads: _openDownloads,
                        onSettings: _openSettings,
                        onMenu: () => _scaffoldKey.currentState?.openDrawer(),
                        onColorExtracted: _onColorExtracted,
                        navColor: const Color(0xFF111111),
                        navIsLight: false,
                      ),
                      // Tab 1 — Explorar (ficheiro separado)
                      ExplorePage(
                        onVideoTap: (FeedVideo video) {
                          setState(() {
                            _selectedEmbedUrl = video.embedUrl;
                            _selectedVideo = video;
                            _tab = 2;
                          });
                          _tabAnim.forward(from: 0.0);
                        },
                      ),
                      ExibicaoPage(
                        embedUrl: _selectedEmbedUrl,
                        currentVideo: _selectedVideo,
                        isActive: _tab == 2,
                        onVideoTap: (FeedVideo video) {
                          setState(() {
                            _selectedEmbedUrl = video.embedUrl;
                            _selectedVideo = video;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (_miniPlayerActive && _selectedVideo != null)
            _MiniPlayer(
              video: _selectedVideo!,
              onTap: () => setState(() {
                _miniPlayerActive = false;
                _tab = 2;
              }),
              onClose: () => setState(() {
                _miniPlayerActive = false;
                _selectedVideo = null;
                _selectedEmbedUrl = null;
              }),
            ),

          _BottomNav(
            tab: _tab,
            onTab: _switchTab,
            navH: _kNavH,
            safeBottom: safeBottom,
          ),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _MiniPlayer
// ─────────────────────────────────────────────────────────────────────────────
class _MiniPlayer extends StatefulWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final VoidCallback onClose;
  const _MiniPlayer({required this.video, required this.onTap, required this.onClose});
  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer>
    with SingleTickerProviderStateMixin {
  InAppWebViewController? _ctrl;
  bool _playing = true;
  late final AnimationController _slideIn;

  @override
  void initState() {
    super.initState();
    _slideIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slideIn.forward();
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) {
        _ctrl?.evaluateJavascript(
            source: 'document.querySelector("video")?.play()');
      }
    });
  }

  @override
  void dispose() { _slideIn.dispose(); super.dispose(); }

  void _togglePlay() {
    _ctrl?.evaluateJavascript(source: _playing
        ? 'document.querySelector("video")?.pause()'
        : 'document.querySelector("video")?.play()');
    setState(() => _playing = !_playing);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final textColor = t.navActive;
    final subColor = t.textSecondary;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slideIn, curve: Curves.easeOutCubic)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: double.infinity,
          height: 64,
          color: t.miniPlayerBg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 2,
                color: t.divider,
                child: FractionallySizedBox(
                  widthFactor: 0.35,
                  alignment: Alignment.centerLeft,
                  child: Container(color: AppTheme.ytRed),
                ),
              ),
              Expanded(
                child: Row(children: [
                  SizedBox(
                    width: 114, height: 62,
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(
                        widget.video.thumb,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'Mozilla/5.0'},
                        errorBuilder: (_, __, ___) => Container(
                          color: t.thumbBg,
                          child: Icon(Icons.play_circle_rounded,
                              color: t.textSecondary, size: 28),
                        ),
                      ),
                      Opacity(
                        opacity: 0.0,
                        child: InAppWebView(
                          key: ValueKey(widget.video.embedUrl),
                          initialUrlRequest: URLRequest(
                              url: WebUri(widget.video.embedUrl)),
                          initialSettings: InAppWebViewSettings(
                            javaScriptEnabled: true,
                            mediaPlaybackRequiresUserGesture: false,
                            allowsInlineMediaPlayback: true,
                          ),
                          onWebViewCreated: (c) => _ctrl = c,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.video.title,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.video.sourceLabel,
                          style: TextStyle(color: subColor, fontSize: 11.5),
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _togglePlay,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: textColor,
                        size: 28,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(Icons.close_rounded, color: subColor, size: 24),
                    ),
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _BottomNav — mesma cor do body (t.bg), sem escurecimento/clarificação
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  final double navH, safeBottom;

  const _BottomNav({
    required this.tab, required this.onTab,
    required this.navH, required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        // Mesma cor exacta do body — sem lerp, sem modificação
        return Container(
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(top: BorderSide(color: t.navBorder, width: 0.5)),
          ),
          padding: EdgeInsets.only(bottom: safeBottom),
          height: navH + safeBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                label: 'Início',
                assetFilled: 'assets/icons/svg/browse_filled.svg',
                assetOutline: 'assets/icons/svg/browse_outline.svg',
                active: tab == 0,
                onTap: () => onTab(0),
              ),
              _NavIcon(
                label: 'Explorar',
                assetFilled: 'assets/icons/svg/explore_filled.svg',
                assetOutline: 'assets/icons/svg/explore_outline.svg',
                active: tab == 1,
                onTap: () => onTab(1),
              ),
              _NavIcon(
                label: 'Exibição',
                assetFilled: 'assets/icons/svg/exibicao_filled.svg',
                assetOutline: 'assets/icons/svg/exibicao_outline.svg',
                active: tab == 2,
                onTap: () => onTab(2),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String assetFilled, assetOutline;

  const _NavIcon({
    required this.label,
    required this.active,
    required this.onTap,
    required this.assetFilled,
    required this.assetOutline,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.current.navActive : AppTheme.current.navInactive;
    final iconW = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: SvgPicture.asset(active ? assetFilled : assetOutline, width: 22, height: 22),
    );

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconW,
            const SizedBox(height: 4),
            Text(label,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
          ],
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _WallpaperColorExtractor
// ─────────────────────────────────────────────────────────────────────────────
class _WallpaperColorExtractor extends StatefulWidget {
  final String imageUrl;
  final void Function(Color) onColor;
  const _WallpaperColorExtractor({required this.imageUrl, required this.onColor});
  @override
  State<_WallpaperColorExtractor> createState() => _WallpaperColorExtractorState();
}

class _WallpaperColorExtractorState extends State<_WallpaperColorExtractor> {
  bool _done = false;

  String get _html => '''
<!DOCTYPE html><html><head><meta charset="utf-8"></head>
<body style="margin:0;background:#000">
<canvas id="c" width="64" height="64" style="display:none"></canvas>
<script>
(function() {
  var img = new Image();
  img.crossOrigin = "anonymous";
  img.onload = function() {
    var c = document.getElementById("c");
    var ctx = c.getContext("2d");
    ctx.drawImage(img, 0, 0, 64, 64);
    var data = ctx.getImageData(0, 0, 64, 64).data;
    var r=0,g=0,b=0,n=0;
    for (var i=0; i<data.length; i+=4) {
      var pr=data[i],pg=data[i+1],pb=data[i+2];
      if ((pr+pg+pb)/3 > 20) { r+=pr; g+=pg; b+=pb; n++; }
    }
    if (n===0) { window.flutter_inappwebview.callHandler("color","0,0,0"); return; }
    r=Math.round(r/n); g=Math.round(g/n); b=Math.round(b/n);
    window.flutter_inappwebview.callHandler("color", r+","+g+","+b);
  };
  img.onerror = function() { window.flutter_inappwebview.callHandler("color","0,0,0"); };
  img.src = "${widget.imageUrl}";
})();
</script></body></html>
''';

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 1, height: 1,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: _html, mimeType: 'text/html'),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true, transparentBackground: true),
        onWebViewCreated: (ctrl) {
          ctrl.addJavaScriptHandler(
            handlerName: 'color',
            callback: (args) {
              if (_done) return;
              _done = true;
              try {
                final p = (args[0] as String).split(',');
                widget.onColor(Color.fromARGB(
                    255, int.parse(p[0]), int.parse(p[1]), int.parse(p[2])));
              } catch (_) { widget.onColor(Colors.black); }
            },
          );
        },
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _NavDrawer
// ─────────────────────────────────────────────────────────────────────────────
class _NavDrawer extends StatelessWidget {
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  const _NavDrawer({required this.onDownloads, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Drawer(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      backgroundColor: t.drawerBg,
      elevation: 0,
      child: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              SvgPicture.asset('assets/icons/svg/shorts_active.svg', width: 28, height: 28),
              const SizedBox(width: 10),
              Text('patrulhaXX',
                style: TextStyle(
                  color: t.text, fontSize: 18,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3,
                )),
            ]),
          ),

          Divider(color: t.divider, height: 1, thickness: 1),
          const SizedBox(height: 4),

          _DrawerItemSvg(
            assetPath: 'assets/icons/svg/drawer_download.svg',
            label: 'Downloads',
            onTap: () { Navigator.pop(context); onDownloads(); },
          ),
          _DrawerItemSvg(
            assetPath: 'assets/icons/svg/drawer_settings.svg',
            label: 'Definições',
            onTap: () { Navigator.pop(context); onSettings(); },
          ),

          const Spacer(),
          Divider(color: t.divider, height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Text('patrulhaXX',
                style: TextStyle(color: t.textTertiary, fontSize: 11)),
          ),
        ]),
      ),
    );
  }
}

class _DrawerItemSvg extends StatelessWidget {
  final String assetPath;
  final String label;
  final VoidCallback onTap;
  const _DrawerItemSvg({
    required this.assetPath, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SvgPicture.asset(
            assetPath,
            width: 20, height: 20,
            colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn),
          ),
          const SizedBox(width: 20),
          Text(label,
            style: TextStyle(
              color: t.text,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _HomeTab
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  final AnimationController fadeIn;
  final double navBottom;
  final void Function(SiteModel) onOpen;
  final VoidCallback onDownloads, onSettings, onMenu;
  final void Function(Color) onColorExtracted;
  final Color navColor;
  final bool navIsLight;

  const _HomeTab({
    required this.fadeIn,
    required this.navBottom,
    required this.onOpen,
    required this.onDownloads,
    required this.onSettings,
    required this.onMenu,
    required this.onColorExtracted,
    required this.navColor,
    required this.navIsLight,
  });

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final ScrollController _scroll = ScrollController();
  double _collapseProgress = 0.0;
  static const double _kCollapseThreshold = 80.0;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final px = _scroll.position.pixels;
    final progress = (px / _kCollapseThreshold).clamp(0.0, 1.0);
    if ((progress - _collapseProgress).abs() > 0.01) {
      setState(() => _collapseProgress = progress);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ts = ThemeService.instance;
    final t = AppTheme.current;

    return Stack(fit: StackFit.expand, children: [
      Container(color: t.bg),

      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned.fill(
          child: Image.asset(
            ts.bg, fit: BoxFit.cover, key: ValueKey(ts.bg),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned(
          left: -1, top: -1, width: 1, height: 1,
          child: _WallpaperColorExtractor(
            imageUrl: ts.bg, onColor: widget.onColorExtracted),
        ),

      FadeTransition(
        opacity: CurvedAnimation(parent: widget.fadeIn, curve: Curves.easeOut),
        child: Column(children: [

          SafeArea(
            bottom: false,
            child: AnimatedBuilder(
              animation: widget.fadeIn,
              builder: (_, __) => _HomeAppBar(
                collapseProgress: _collapseProgress,
                onMenu: widget.onMenu,
                onDownloads: widget.onDownloads,
                onSettings: widget.onSettings,
                navColor: widget.navColor,
                navIsLight: widget.navIsLight,
              ),
            ),
          ),

          Expanded(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _SitesRow(sites: kSites, onTap: widget.onOpen),
                  ),
                ),
                const SliverToBoxAdapter(child: _HomeFeedSection()),
                SliverToBoxAdapter(child: SizedBox(height: widget.navBottom + 16)),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── AppBar da _HomeTab ───────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final double collapseProgress;
  final VoidCallback onMenu, onDownloads, onSettings;
  final Color navColor;
  final bool navIsLight;

  const _HomeAppBar({
    required this.collapseProgress,
    required this.onMenu,
    required this.onDownloads,
    required this.onSettings,
    required this.navColor,
    required this.navIsLight,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            GestureDetector(
              onTap: onMenu,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                width: 38, height: 44,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/svg/hamburger.svg', width: 22, height: 22,
                    colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Início',
                style: TextStyle(
                  color: t.text, fontSize: 20,
                  fontWeight: FontWeight.w700, letterSpacing: -0.5,
                )),
            ),
            if (collapseProgress > 0.1)
              Opacity(
                opacity: collapseProgress,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _IconBtn(
                    assetPath: 'assets/icons/svg/search.svg',
                    onTap: () => Navigator.push(context, _iosRoute(const _SearchPage())),
                    color: t.icon,
                  ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    assetPath: 'assets/icons/svg/drawer_download.svg',
                    onTap: onDownloads,
                    color: t.icon,
                  ),
                  const SizedBox(width: 4),
                  _IconBtn(
                    assetPath: 'assets/icons/svg/drawer_settings.svg',
                    onTap: onSettings,
                    color: t.icon,
                  ),
                ]),
              ),
          ]),

          ClipRect(
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: (1.0 - collapseProgress).clamp(0.0, 1.0),
              child: Opacity(
                opacity: (1.0 - collapseProgress * 1.5).clamp(0.0, 1.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _SearchTrigger(navColor: navColor, navIsLight: navIsLight),
                    const SizedBox(height: 10),
                    _ActionRow(
                      onDownloads: onDownloads,
                      onSettings: onSettings,
                      navColor: navColor,
                      navIsLight: navIsLight,
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final Color color;
  const _IconBtn({required this.assetPath, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SvgPicture.asset(assetPath, width: 20, height: 20,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn)),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _HomeFeedSection — feed de fotos estilo masonry
// ─────────────────────────────────────────────────────────────────────────────
class _HomeFeedSection extends StatefulWidget {
  const _HomeFeedSection();
  @override
  State<_HomeFeedSection> createState() => _HomeFeedSectionState();
}

class _HomeFeedSectionState extends State<_HomeFeedSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedPhoto> _photos = [];
  bool _loading = true;
  bool _fetching = false;
  int _page = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final photos = await PhotoFetcher.fetchAll(_page);
    if (!mounted) return;
    setState(() {
      _photos.addAll(photos);
      _page++;
      _loading = false;
    });
  }

  Future<void> _loadMore() async {
    if (_fetching || _loading) return;
    _fetching = true;
    final photos = await PhotoFetcher.fetchAll(_page);
    _fetching = false;
    if (!mounted) return;
    setState(() {
      _photos.addAll(photos);
      _page++;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;

    if (_loading) {
      return Column(
        children: List.generate(3, (_) => _PhotoCardSkeleton()),
      );
    }

    if (_photos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text('Sem conteúdo disponível',
              style: TextStyle(color: t.textSecondary, fontSize: 13)),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification) _loadMore();
        return false;
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Text('Fotos em destaque',
                style: TextStyle(
                  color: t.text, fontSize: 16,
                  fontWeight: FontWeight.w700, letterSpacing: -0.3,
                )),
            ]),
          ),
          MasonryGridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
            padding: const EdgeInsets.symmetric(horizontal: 3),
            itemCount: _photos.length,
            itemBuilder: (_, i) => _HomeFeedPhotoTile(photo: _photos[i]),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _HomeFeedPhotoTile extends StatelessWidget {
  final FeedPhoto photo;
  const _HomeFeedPhotoTile({required this.photo});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: Stack(
        children: [
          Image.network(
            photo.url,
            fit: BoxFit.cover,
            width: double.infinity,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
              'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: t.thumbBg,
              child: Center(child: Icon(Icons.image_not_supported_rounded,
                  color: t.iconSub, size: 28)),
            ),
            loadingBuilder: (_, child, p) => p == null ? child : Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: t.shimmer,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
          ),
          if (photo.sourceLabel.isNotEmpty)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC000000), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(6, 16, 6, 5),
                child: Text(photo.sourceLabel,
                  style: const TextStyle(
                    color: Colors.white, fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PhotoCardSkeleton extends StatefulWidget {
  @override
  State<_PhotoCardSkeleton> createState() => _PhotoCardSkeletonState();
}
class _PhotoCardSkeletonState extends State<_PhotoCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        width: w, height: w * 0.6,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
            colors: AppTheme.current.shimmer,
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _SearchTrigger
// ─────────────────────────────────────────────────────────────────────────────
class _SearchTrigger extends StatelessWidget {
  final Color navColor;
  final bool navIsLight;
  const _SearchTrigger({required this.navColor, required this.navIsLight});

  Color get _bgColor => AppTheme.current.inputBg;
  Color get _borderColor => AppTheme.current.inputBorder;
  Color get _hintColor => AppTheme.current.inputHint;

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 420),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: AppTheme.current.bg,
      closedColor: Colors.transparent,
      closedElevation: 0,
      openElevation: 0,
      closedShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(100)),
      ),
      openShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      closedBuilder: (_, openContainer) => GestureDetector(
        onTap: openContainer,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            color: _bgColor,
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: _borderColor),
          ),
          child: Row(children: [
            const SizedBox(width: 16),
            SvgPicture.asset('assets/icons/svg/search.svg', width: 18, height: 18,
                colorFilter: ColorFilter.mode(_hintColor, BlendMode.srcIn)),
            const SizedBox(width: 10),
            Text(
              'Pesquisar vídeos, sites...',
              style: TextStyle(color: _hintColor, fontSize: 15),
            ),
          ]),
        ),
      ),
      openBuilder: (_, __) => const _SearchPage(),
    );
  }
}


// ─── _SearchPage ──────────────────────────────────────────────────────────────
class _SearchPage extends StatefulWidget {
  const _SearchPage();
  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl = TextEditingController();
  bool get _hasQuery => _ctrl.text.trim().isNotEmpty;

  static const _suggestions = [
    'amador português', 'milf', 'latina', 'caseiro', 'teen',
    'loira', 'morena', 'asiática', 'lésbicas', 'threesome',
    'maduro', 'college', 'office', 'massage', 'outdoor',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => SearchResultsPage(query: q)));
  }

  void _searchFor(String q) {
    _ctrl.text = q;
    setState(() {});
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => SearchResultsPage(query: q)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(children: [
          SizedBox(height: topPad + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: t.btnGhost,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/svg/back_arrow.svg',
                      width: 18, height: 18,
                      colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: t.inputBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: t.inputBorder),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 16),
                    SvgPicture.asset('assets/icons/svg/search.svg', width: 18, height: 18,
                        colorFilter: ColorFilter.mode(t.textSecondary, BlendMode.srcIn)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(color: t.inputText, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.ytRed,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Pesquisar...',
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    if (_hasQuery)
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.ytRed,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text('Ir',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text('Sugestões',
                    style: TextStyle(
                        color: t.textSecondary, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _suggestions.map((s) => GestureDetector(
                    onTap: () => _searchFor(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.chipBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: t.borderSoft),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              color: t.text, fontSize: 13,
                              fontWeight: FontWeight.w400)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ActionRow
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final VoidCallback onDownloads, onSettings;
  final Color navColor;
  final bool navIsLight;

  const _ActionRow({
    required this.onDownloads, required this.onSettings,
    required this.navColor, required this.navIsLight,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final bgColor      = t.btnGhost;
    final borderColor  = t.border;
    final contentColor = t.text;

    return Row(children: [
      Expanded(child: _ActionBtn(
        label: 'Downloads', onTap: onDownloads,
        bgColor: bgColor, borderColor: borderColor, contentColor: contentColor,
        isDownloads: true,
      )),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(
        assetPath: 'assets/icons/svg/settings_gradient.svg', label: 'Definições', onTap: onSettings,
        bgColor: bgColor, borderColor: borderColor, contentColor: contentColor,
        isSettings: true,
      )),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String? assetPath;
  final String label;
  final VoidCallback onTap;
  final Color bgColor, borderColor, contentColor;
  final bool isDownloads;
  final bool isSettings;

  const _ActionBtn({
    this.assetPath,
    required this.label, required this.onTap,
    required this.bgColor, required this.borderColor, required this.contentColor,
    this.isDownloads = false,
    this.isSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (isDownloads) {
      iconWidget = Image.asset('assets/icons/downloads_folder.png', width: 38, height: 38);
    } else if (isSettings) {
      iconWidget = SvgPicture.asset(assetPath!, width: 38, height: 38);
    } else {
      iconWidget = SvgPicture.asset(assetPath!, width: 17, height: 17,
          colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn));
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          iconWidget,
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: contentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _SitesRow
// ─────────────────────────────────────────────────────────────────────────────
class _SitesRow extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SitesRow({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sites.length,
        itemBuilder: (_, i) => _SiteCell(site: sites[i], onTap: () => onTap(sites[i])),
      ),
    );
  }
}

class _SiteCell extends StatefulWidget {
  final SiteModel site;
  final VoidCallback onTap;
  const _SiteCell({required this.site, required this.onTap});
  @override
  State<_SiteCell> createState() => _SiteCellState();
}

class _SiteCellState extends State<_SiteCell> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 200),
        lowerBound: 0, upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 52;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SiteIconWidget(site: widget.site, size: iconSize, showShadow: true),
            const SizedBox(height: 5),
            SizedBox(
              width: iconSize + 10,
              child: Text(widget.site.name,
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: AppTheme.current.iconSub,
                      fontSize: 10,
                      fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Modelo de foto do feed
// ─────────────────────────────────────────────────────────────────────────────
class FeedPhoto {
  final String id;
  final String url;
  final String thumb;
  final String title;
  final String source;
  final String sourceLabel;
  final int likes;

  const FeedPhoto({
    required this.id,
    required this.url,
    required this.thumb,
    required this.title,
    required this.source,
    required this.sourceLabel,
    this.likes = 0,
  });

  static FeedPhoto? fromPornhub(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['photo_id'] ?? '').toString();
    if (id.isEmpty) return null;
    String url = j['thumb_url'] as String?
        ?? j['url'] as String?
        ?? j['thumbnail'] as String? ?? '';
    if (url.isNotEmpty && url.contains('_160')) {
      url = url.replaceAll('_160', '_720');
    }
    if (url.isEmpty) return null;
    return FeedPhoto(
      id: 'ph_$id', url: url, thumb: url,
      title: j['title'] as String? ?? '',
      source: 'https://www.pornhub.com/favicon.ico',
      sourceLabel: 'Pornhub',
      likes: int.tryParse((j['rating'] ?? j['likes'] ?? '0').toString()) ?? 0,
    );
  }

  static FeedPhoto? fromRedtube(Map<String, dynamic> j) {
    final id = (j['photo_id'] ?? j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final url = j['thumb_url'] as String? ?? j['url'] as String? ?? '';
    if (url.isEmpty) return null;
    return FeedPhoto(
      id: 'rt_$id', url: url, thumb: url,
      title: j['title'] as String? ?? '',
      source: 'https://www.redtube.com/favicon.ico',
      sourceLabel: 'RedTube',
      likes: int.tryParse((j['rating'] ?? '0').toString()) ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhotoFetcher
// ─────────────────────────────────────────────────────────────────────────────
class PhotoFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static Future<List<FeedPhoto>> fetchAll(int page) async {
    final results = await Future.wait([
      _fetchPornhub(page),
      _fetchRedtube(page),
    ]);
    final all = <FeedPhoto>[];
    for (final list in results) all.addAll(list);
    all.shuffle();
    return all;
  }

  static Future<List<FeedPhoto>> _fetchPornhub(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/photos?format=json&page=${page.clamp(1,30)}&thumbsize=medium'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final photos = data['photos'] as List? ?? data['photo'] as List? ?? [];
      return photos
          .map((p) => FeedPhoto.fromPornhub(p as Map<String, dynamic>))
          .whereType<FeedPhoto>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedPhoto>> _fetchRedtube(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://api.redtube.com/?data=redtube.Photos.searchPhotos&output=json&thumbsize=medium&page=${page.clamp(1,20)}&count=20'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final photos = data['photos'] as List? ?? [];
      return photos.map((p) {
        final pm = (p as Map)['photo'] as Map<String, dynamic>? ?? p as Map<String, dynamic>;
        return FeedPhoto.fromRedtube(pm);
      }).whereType<FeedPhoto>().toList();
    } catch (_) { return []; }
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Modelo unificado de vídeo
// ─────────────────────────────────────────────────────────────────────────────
enum VideoSource {
  eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang,
  bravotube, drtuber, txxx, gotporn, porndig,
}

class FeedVideo {
  final String title;
  final String thumb;
  final String embedUrl;
  final String duration;
  final String views;
  final VideoSource source;

  const FeedVideo({
    required this.title, required this.thumb, required this.embedUrl,
    required this.duration, required this.views, required this.source,
  });

  String get sourceLabel {
    switch (source) {
      case VideoSource.eporner:   return 'Eporner';
      case VideoSource.pornhub:   return 'Pornhub';
      case VideoSource.redtube:   return 'RedTube';
      case VideoSource.youporn:   return 'YouPorn';
      case VideoSource.xvideos:   return 'XVideos';
      case VideoSource.xhamster:  return 'xHamster';
      case VideoSource.spankbang: return 'SpankBang';
      case VideoSource.bravotube: return 'BravoTube';
      case VideoSource.drtuber:   return 'DrTuber';
      case VideoSource.txxx:      return 'TXXX';
      case VideoSource.gotporn:   return 'GotPorn';
      case VideoSource.porndig:   return 'PornDig';
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:   return 'E';
      case VideoSource.pornhub:   return 'P';
      case VideoSource.redtube:   return 'R';
      case VideoSource.youporn:   return 'Y';
      case VideoSource.xvideos:   return 'XV';
      case VideoSource.xhamster:  return 'XH';
      case VideoSource.spankbang: return 'SB';
      case VideoSource.bravotube: return 'BT';
      case VideoSource.drtuber:   return 'DT';
      case VideoSource.txxx:      return 'TX';
      case VideoSource.gotporn:   return 'GP';
      case VideoSource.porndig:   return 'PD';
    }
  }

  Color get sourceColor => const Color(0xFF222222);

  static FeedVideo? fromEporner(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    if (id.isEmpty) return null;
    String thumb = '';
    final thumbs = j['thumbs'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      final sorted = thumbs.map((t) => t as Map).toList()
        ..sort((a, b) => ((b['width'] ?? 0) as int).compareTo((a['width'] ?? 0) as int));
      thumb = sorted.first['src'] as String? ?? '';
    }
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.eporner.com/embed/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.eporner,
    );
  }

  static FeedVideo? fromPornhub(Map<String, dynamic> j) {
    final viewkey = j['video_id'] as String? ?? j['viewkey'] as String? ?? '';
    if (viewkey.isEmpty) return null;
    String thumb = '';
    final thumbs = j['thumbs'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      thumb = (thumbs.first['src'] ?? thumbs.first['url'] ?? '') as String;
    }
    if (thumb.isEmpty) thumb = j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.pornhub.com/embed/$viewkey',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.pornhub,
    );
  }

  static FeedVideo? fromRedtube(Map<String, dynamic> j) {
    final vid = j['video_id'] as String? ?? '';
    if (vid.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://embed.redtube.com/?id=$vid',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.redtube,
    );
  }

  static FeedVideo? fromYouporn(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.youporn.com/embed/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.youporn,
    );
  }

  static String cleanTitle(String raw) {
    try {
      final bytes = latin1.encode(raw);
      final decoded = utf8.decode(bytes, allowMalformed: true);
      if (decoded.runes.where((r) => r > 127).length <
          raw.runes.where((r) => r > 127).length) {
        return decoded;
      }
    } catch (_) {}
    return raw;
  }

  static FeedVideo? fromXvideos(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ??
        j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.xvideos.com/embedframe/$id',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views'] ?? j['nb_views']),
      source:   VideoSource.xvideos,
    );
  }

  static FeedVideo? fromXhamster(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumbUrl'] as String? ?? j['thumb'] as String? ??
        j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://xhamster.com/xembed.php?video=$id',
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.xhamster,
    );
  }

  static FeedVideo? fromSpankbang(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://spankbang.com/$id/embed/',
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.spankbang,
    );
  }

  static FeedVideo fromRss({
    required String title,
    required String thumb,
    required String embedUrl,
    required VideoSource source,
  }) => FeedVideo(
    title: cleanTitle(title),
    thumb: thumb,
    embedUrl: embedUrl,
    duration: '',
    views: '',
    source: source,
  );

  static String _fmtViews(dynamic raw) {
    if (raw == null) return '';
    final n = int.tryParse(raw.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n > 0 ? n.toString() : '';
  }

  static String fmtViewsPublic(dynamic raw) => _fmtViews(raw);
}


// ─────────────────────────────────────────────────────────────────────────────
// FeedFetcher
// ─────────────────────────────────────────────────────────────────────────────
class FeedFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
  ];

  static Future<List<FeedVideo>> fetchEporner(int page) async {
    final term = _terms[page % _terms.length];
    try {
      final r = await http.get(
        Uri.parse('https://www.eporner.com/api/v2/video/search/'
            '?query=$term&per_page=20&page=${page.clamp(1, 60)}&thumbsize=big&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) => FeedVideo.fromEporner(v as Map<String, dynamic>))
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchPornhub(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/search?search=&ordering=newest'
            '&page=${page.clamp(1, 40)}&thumbsize=medium&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) {
            final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
            return FeedVideo.fromPornhub(inner);
          })
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchRedtube(int page) async {
    final term = _terms[page % _terms.length];
    final order = ['mostviewed', 'rating', 'newestdate'][page % 3];
    try {
      final r = await http.get(
        Uri.parse('https://api.redtube.com/?data=redtube.Videos.searchVideos'
            '&output=json&thumbsize=medium&count=20'
            '&search=$term&ordering=$order&page=$page'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) {
            final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
            return FeedVideo.fromRedtube(inner);
          })
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchYouporn(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.youporn.com/api/video/search/'
            '?is_top=1&page=${page.clamp(1,15)}&per_page=20'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json',
            'Referer': 'https://www.youporn.com/'},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final videos = (data['videos'] ?? data['data'] ?? data) as List? ?? [];
        final result = videos
            .map((v) => FeedVideo.fromYouporn(v as Map<String, dynamic>))
            .whereType<FeedVideo>()
            .toList();
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<FeedVideo>> fetchXvideos(int page) async {
    final urls = [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://www.xvideos.com/embedframe/${match.group(1)}',
            source: VideoSource.xvideos,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    final urls = [
      'https://www.xnxx.com/rss/latest_videos',
      'https://www.xnxx.com/rss/best_videos',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video-(\w+)/').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://www.xnxx.com/embedframe/${match.group(1)}',
            source: VideoSource.xhamster,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchSpankbang(int page) async {
    final urls = ['https://spankbang.com/rss/', 'https://spankbang.com/rss/trending/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(Uri.parse(link).path);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://spankbang.com/${match.group(1)}/embed/',
            source: VideoSource.spankbang,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchBravotube(int page) async {
    final urls = ['https://www.bravotube.net/rss/new/', 'https://www.bravotube.net/rss/popular/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.bravotube.net/embed/${match.group(1)}/',
            source: VideoSource.bravotube,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchDrtuber(int page) async {
    final urls = ['https://www.drtuber.com/rss/latest', 'https://www.drtuber.com/rss/popular'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video/(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.drtuber.com/embed/${match.group(1)}',
            source: VideoSource.drtuber,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchTxxx(int page) async {
    final urls = ['https://www.txxx.com/rss/new/', 'https://www.txxx.com/rss/popular/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)/?$').firstMatch(Uri.parse(link).path);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.txxx.com/embed/${match.group(1)}/',
            source: VideoSource.txxx,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchGotporn(int page) async {
    final urls = ['https://www.gotporn.com/rss/latest', 'https://www.gotporn.com/rss/popular'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video-(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.gotporn.com/video/embed/${match.group(1)}',
            source: VideoSource.gotporn,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchPorndig(int page) async {
    final urls = ['https://www.porndig.com/rss', 'https://www.porndig.com/rss?category=latest'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.porndig.com/embed/${match.group(1)}',
            source: VideoSource.porndig,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static String _xml(dynamic el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); } catch (_) { return ''; }
  }

  static String _mediaAttr(dynamic item, String localName, String attr) {
    try {
      for (final child in (item as dynamic).childElements) {
        final qn = child.qualifiedName as String? ?? '';
        final ln = child.localName as String? ?? '';
        if (qn == 'media:$localName' || ln == localName) {
          final val = child.getAttribute(attr) as String? ?? '';
          if (val.isNotEmpty) return val;
        }
      }
    } catch (_) {}
    return '';
  }

  static String _rssThumb(dynamic item) {
    final mc = _mediaAttr(item, 'content', 'url');
    if (mc.isNotEmpty) return mc;
    final mt = _mediaAttr(item, 'thumbnail', 'url');
    if (mt.isNotEmpty) return mt;
    try {
      for (final child in (item as dynamic).childElements) {
        final ln = (child.localName as String? ?? '').toLowerCase();
        if (ln == 'enclosure') {
          final url = child.getAttribute('url') as String? ?? '';
          final type = child.getAttribute('type') as String? ?? '';
          if (url.isNotEmpty && (type.startsWith('image') ||
              url.contains('.jpg') || url.contains('.png') || url.contains('.webp'))) {
            return url;
          }
        }
      }
    } catch (_) {}
    try {
      final desc = _xml(item, 'description');
      if (desc.isNotEmpty) {
        final rx = RegExp('<img[^>]+src=["\'](.*?)["\']');
        final m = rx.firstMatch(desc);
        if (m != null) return m.group(1) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static Future<List<FeedVideo>> fetchAll(int page) async {
    final rng = Random(DateTime.now().millisecondsSinceEpoch ^ page.hashCode);
    final epPage = rng.nextInt(60) + 1;
    final phPage = rng.nextInt(40) + 1;
    final rtPage = rng.nextInt(30) + 1;
    final ypPage = rng.nextInt(20) + 1;
    final xvPage = rng.nextInt(50) + 1;
    final xhPage = rng.nextInt(30) + 1;
    final sbPage = rng.nextInt(20) + 1;

    final results = await Future.wait([
      fetchEporner(epPage),
      fetchPornhub(phPage),
      fetchRedtube(rtPage),
      fetchYouporn(ypPage),
      fetchXvideos(xvPage),
      fetchXhamster(xhPage),
      fetchSpankbang(sbPage),
      fetchBravotube(page),
      fetchDrtuber(page),
      fetchTxxx(page),
      fetchGotporn(page),
      fetchPorndig(page),
    ]);

    final merged = <FeedVideo>[];
    final lists = results.where((l) => l.isNotEmpty).toList();
    if (lists.isEmpty) return [];

    int maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < maxLen; i++) {
      for (final list in lists) {
        if (i < list.length) merged.add(list[i]);
      }
    }
    merged.shuffle(rng);
    return merged;
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _ThumbShimmer (usado por _MiniPlayer e outros)
// ─────────────────────────────────────────────────────────────────────────────
class _ThumbShimmer extends StatefulWidget {
  @override State<_ThumbShimmer> createState() => _ThumbShimmerState();
}
class _ThumbShimmerState extends State<_ThumbShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// faviconForSource (helper público, usado por explore_page.dart)
// ─────────────────────────────────────────────────────────────────────────────
String faviconForSource(VideoSource src) {
  switch (src) {
    case VideoSource.eporner:   return 'https://www.eporner.com/favicon.ico';
    case VideoSource.pornhub:   return 'https://www.pornhub.com/favicon.ico';
    case VideoSource.redtube:   return 'https://www.redtube.com/favicon.ico';
    case VideoSource.youporn:   return 'https://www.youporn.com/favicon.ico';
    case VideoSource.xvideos:   return 'https://www.xvideos.com/favicon.ico';
    case VideoSource.xhamster:  return 'https://xhamster.com/favicon.ico';
    case VideoSource.spankbang: return 'https://spankbang.com/favicon.ico';
    case VideoSource.bravotube: return 'https://www.bravotube.net/favicon.ico';
    case VideoSource.drtuber:   return 'https://www.drtuber.com/favicon.ico';
    case VideoSource.txxx:      return 'https://www.txxx.com/favicon.ico';
    case VideoSource.gotporn:   return 'https://www.gotporn.com/favicon.ico';
    case VideoSource.porndig:   return 'https://www.porndig.com/favicon.ico';
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// FreeBrowserPage
// ─────────────────────────────────────────────────────────────────────────────
class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(
          id: 'free', name: title, baseUrl: url,
          allowedDomain: '', searchUrl: url, primaryColor: kPrimaryColor),
      freeNavigation: true,
    );
  }
}
