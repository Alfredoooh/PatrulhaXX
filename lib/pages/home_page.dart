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
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
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
      // Slide da direita (iOS nativo)
      final slide = Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ));
      // A página actual desliza ligeiramente para a esquerda (efeito iOS)
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
                  builder: (_, child) {
                    // Animação entre tabs: fade + leve scale (não é slide)
                    final opacity = CurvedAnimation(
                      parent: _tabAnim,
                      curve: Curves.easeOutCubic,
                    ).value;
                    return FadeTransition(
                      opacity: _tabAnim,
                      child: child,
                    );
                  },
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
                      _ShortsTab(
                        navBottom: 0,
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
// _BottomNav — fundo levemente menos escuro (-5%)
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
        // Navbg levemente menos escuro (-5%)
        final navBg = t.isDark
            ? Color.lerp(t.navBg, Colors.white, 0.05)!
            : Color.lerp(t.navBg, Colors.black, 0.05)!;
        return Container(
          decoration: BoxDecoration(
            color: navBg,
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
              // Tab "Explorar" — igual aos demais (ícone + nome em baixo)
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
// _NavAppBar — hambúrguer + título "Início"
// ─────────────────────────────────────────────────────────────────────────────
class _NavAppBar extends StatelessWidget {
  final VoidCallback onMenu;
  const _NavAppBar({required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Row(children: [
      GestureDetector(
        onTap: onMenu,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 38, height: 38,
          child: Center(
            child: SvgPicture.asset(
              'assets/icons/svg/hamburger.svg', width: 22, height: 22,
              colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
            ),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Text('Início',
        style: TextStyle(
          color: t.text, fontSize: 20,
          fontWeight: FontWeight.w700, letterSpacing: -0.5,
        )),
    ]);
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
// _HomeTab — AppBar com scroll-aware (searchbar + botões sobem/aparecem como ícones)
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
  // 0.0 = tudo visível, 1.0 = scrolled (searchbar+botões escondidos, ícones visíveis)
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

          // ── AppBar FIXO ────────────────────────────────────────────────────
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

          // ── Conteúdo scrollável ────────────────────────────────────────────
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
                // Feed estilo Facebook com fotos de múltiplas fontes
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

// ─── AppBar da _HomeTab com colapso suave ────────────────────────────────────
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
    // Altura do bloco colapsável: searchbar(50) + actionRow(48) + spacings(10+10+14) = ~132
    final collapseH = (1.0 - collapseProgress) * 132.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Linha do título + ícones de ação (sempre visível mas ícones
          // aparecem quando collapsed)
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
            // Ícones que aparecem quando colapsa
            if (collapseProgress > 0.1) ...[
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
            ],
          ]),

          // Bloco colapsável: searchbar + botões
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

// Botão ícone SVG compacto para a barra colapsada
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
// _HomeFeedSection — feed estilo Facebook com imagens de fontes de pornografia
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
              Text('Explorar fotos',
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
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
      borderRadius: BorderRadius.circular(6),
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
          // Label da fonte no canto
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


// ─── _SearchPage ─────────────────────────────────────────────────────────────
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
// _ActionRow — botões Downloads + Definições
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
    final bgColor     = t.btnGhost;
    final borderColor = t.border;
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
      id: 'ph_$id',
      url: url,
      thumb: url,
      title: j['title'] as String? ?? '',
      source: 'https://www.pornhub.com/favicon.ico',
      sourceLabel: 'Pornhub',
      likes: int.tryParse((j['rating'] ?? j['likes'] ?? '0').toString()) ?? 0,
    );
  }

  static FeedPhoto? fromRedtube(Map<String, dynamic> j) {
    final id = (j['photo_id'] ?? j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final url = j['thumb_url'] as String?
        ?? j['url'] as String? ?? '';
    if (url.isEmpty) return null;
    return FeedPhoto(
      id: 'rt_$id',
      url: url,
      thumb: url,
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
    final terms = _terms;
    final term = terms[page % terms.length];
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
    final terms = _terms;
    final term = terms[page % terms.length];
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
    final urls = [
      'https://spankbang.com/rss/',
      'https://spankbang.com/rss/trending/',
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
          if (url.isNotEmpty && (type.startsWith('image') || url.contains('.jpg') || url.contains('.png') || url.contains('.webp'))) {
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
// _ShortsTab — Feed multi-fonte estilo YouTube (renomeado para Explorar)
// AppBar com gradiente escuro em baixo
// Cards sem botão de play, staggered grid
// ─────────────────────────────────────────────────────────────────────────────
class _ShortsTab extends StatefulWidget {
  final double navBottom;
  final void Function(FeedVideo) onVideoTap;
  const _ShortsTab({required this.navBottom, required this.onVideoTap});

  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}

const _kChipTerms = [
  '',        // Todos
  '',        // Mais vistos
  '',        // Recentes
  '',        // Avaliação
  'amateur',
  'milf',
  'asian',
  'latina',
  'blonde',
];

class _ShortsTabState extends State<_ShortsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedVideo> _videos = [];
  final List<FeedPhoto> _photos = [];
  bool _loading = true;
  bool _error = false;
  int _page = 1;
  int _photoPage = 1;
  bool _fetching = false;
  int _selectedChip = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchPhotos();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 500) {
      _fetchMore();
    }
  }

  List<FeedVideo> get _filtered {
    final term = _kChipTerms[_selectedChip].toLowerCase();
    if (term.isEmpty) return _videos;
    return _videos.where((v) =>
        v.title.toLowerCase().contains(term) ||
        v.sourceLabel.toLowerCase().contains(term)).toList();
  }

  void _onChipChanged(int index) {
    setState(() => _selectedChip = index);
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = false; });
    final videos = await FeedFetcher.fetchAll(_page);
    if (!mounted) return;
    if (videos.isEmpty) {
      setState(() { _loading = false; _error = true; });
    } else {
      _videos.clear();
      _videos.addAll(videos);
      _page++;
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading) return;
    _fetching = true;
    final videos = await FeedFetcher.fetchAll(_page);
    _fetching = false;
    if (!mounted || videos.isEmpty) return;
    setState(() {
      _videos.addAll(videos);
      _page++;
    });
    _fetchPhotos();
  }

  Future<void> _fetchPhotos() async {
    try {
      final photos = await PhotoFetcher.fetchAll(_photoPage);
      if (!mounted) return;
      setState(() {
        _photos.addAll(photos);
        _photoPage++;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: t.bg,
      child: Stack(
        children: [
          // Conteúdo principal
          Column(children: [
            // Espaço para o AppBar sobreposto
            SizedBox(height: topPad + 100),

            Expanded(
              child: RefreshIndicator(
                color: AppTheme.ytRed,
                backgroundColor: t.surface,
                onRefresh: _fetch,
                child: _loading
                    ? _buildSkeletonGrid()
                    : _error
                        ? const Center(
                            child: Text(
                              'Sem conexão',
                              style: TextStyle(color: Color(0xFF888888), fontSize: 13),
                            ),
                          )
                        : _buildStaggeredGrid(),
              ),
            ),
          ]),

          // AppBar sobreposto com gradiente (transparente em baixo → opaco em cima)
          Positioned(
            top: 0, left: 0, right: 0,
            child: _ExplorarAppBar(
              topPad: topPad,
              selectedChip: _selectedChip,
              onChipChanged: _onChipChanged,
              onSearchTap: () => Navigator.push(context,
                  _iosRoute(const _SearchPage())),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return MasonryGridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      itemCount: 10,
      itemBuilder: (_, i) => _GridSkeleton(tall: i % 3 == 0),
    );
  }

  Widget _buildStaggeredGrid() {
    final list = _filtered;
    return MasonryGridView.count(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 24),
      itemCount: list.length + (list.isNotEmpty ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == list.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.ytRed))),
          );
        }
        final video = list[i];
        return _GridVideoCard(
          video: video,
          onTap: () => widget.onVideoTap(video),
        );
      },
    );
  }
}

// ─── AppBar do Explorar com gradiente em cima, transparente em baixo ──────────
class _ExplorarAppBar extends StatelessWidget {
  final double topPad;
  final int selectedChip;
  final void Function(int) onChipChanged;
  final VoidCallback onSearchTap;

  static const _chips = [
    'Todos', 'Mais vistos', 'Recentes', 'Avaliação',
    'Amador', 'MILF', 'Asiática', 'Latina', 'Loira',
  ];

  const _ExplorarAppBar({
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final gradientEnd = t.isDark
        ? Colors.transparent
        : Colors.transparent;
    final gradientStart = t.isDark
        ? t.bg.withOpacity(0.97)
        : t.bg.withOpacity(0.97);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [gradientStart, gradientStart, gradientEnd],
          stops: const [0.0, 0.78, 1.0],
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad),

        // Título + botão de pesquisa
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
          child: Row(children: [
            Text('Explorar',
              style: TextStyle(
                color: t.text, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5,
              )),
            const Spacer(),
            GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: SvgPicture.asset('assets/icons/svg/search.svg', width: 20, height: 20,
                    colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
              ),
            ),
          ]),
        ),

        // Chips com indicador de linha em baixo (sem container cheio)
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 14, right: 14),
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 4),
            itemBuilder: (_, i) {
              final selected = selectedChip == i;
              return GestureDetector(
                onTap: () => onChipChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    // Sem container cheio — só indicador de linha em baixo
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? kPrimaryColor : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                  ),
                  child: Text(_chips[i],
                    style: TextStyle(
                      color: selected ? t.text : t.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    )),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 6),
      ]),
    );
  }
}

// ─── Card de vídeo para grid staggered (sem botão play, aspecto imagem) ───────
class _GridVideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _GridVideoCard({required this.video, required this.onTap});

  static Map<String, String> _headers(VideoSource src) {
    final origin = _originForSource(src);
    return {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
      if (origin.isNotEmpty) 'Referer': origin,
    };
  }

  static String _originForSource(VideoSource src) {
    switch (src) {
      case VideoSource.eporner:   return 'https://www.eporner.com/';
      case VideoSource.pornhub:   return 'https://www.pornhub.com/';
      case VideoSource.redtube:   return 'https://www.redtube.com/';
      case VideoSource.youporn:   return 'https://www.youporn.com/';
      case VideoSource.xvideos:   return 'https://www.xvideos.com/';
      case VideoSource.xhamster:  return 'https://xhamster.com/';
      case VideoSource.spankbang: return 'https://spankbang.com/';
      case VideoSource.bravotube: return 'https://www.bravotube.net/';
      case VideoSource.drtuber:   return 'https://www.drtuber.com/';
      case VideoSource.txxx:      return 'https://www.txxx.com/';
      case VideoSource.gotporn:   return 'https://www.gotporn.com/';
      case VideoSource.porndig:   return 'https://www.porndig.com/';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            // Thumbnail sem AspectRatio fixo — adapta-se à imagem real (staggered)
            _ThumbImage(
              url: video.thumb,
              headers: _headers(video.source),
              placeholder: t.thumbBg,
            ),

            // Gradiente em baixo com duração + título
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xDD000000), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        video.title,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w500, height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (video.duration.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(video.duration,
                          style: const TextStyle(
                            color: Colors.white, fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                          )),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton para grid ────────────────────────────────────────────────────────
class _GridSkeleton extends StatefulWidget {
  final bool tall;
  const _GridSkeleton({this.tall = false});
  @override State<_GridSkeleton> createState() => _GridSkeletonState();
}
class _GridSkeletonState extends State<_GridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final h = widget.tall ? 200.0 : 140.0;
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_a.value - 1, 0),
              end: Alignment(_a.value + 1, 0),
              colors: AppTheme.current.shimmer,
            ),
          ),
        ),
      ),
    );
  }
}


// ─── Widget de thumbnail com retry automático ─────────────────────────────────
class _ThumbImage extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final Color placeholder;
  const _ThumbImage({required this.url, required this.headers, required this.placeholder});
  @override
  State<_ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<_ThumbImage> {
  int _attempt = 0;
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (widget.url.isEmpty || _failed) {
      return _placeholder(t);
    }

    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover,
      headers: widget.headers,
      errorBuilder: (_, __, ___) {
        if (_attempt < 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _attempt++);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
        }
        return _placeholder(t);
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _ThumbShimmer();
      },
    );
  }

  Widget _placeholder(AppTheme t) => Container(
    height: 120,
    color: t.thumbBg,
    child: Center(child: Icon(Icons.play_circle_outline_rounded,
        color: t.iconSub, size: 36)),
  );
}

// Shimmer para thumbnail
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

// ─── Avatar do favicon com fallback ──────────────────────────────────────────
class _FaviconAvatar extends StatelessWidget {
  final VideoSource source;
  const _FaviconAvatar({required this.source});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.network(
        faviconForSource(source),
        width: 36, height: 36,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: t.avatarBg, shape: BoxShape.circle),
          child: Center(child: Text(
            source.name[0].toUpperCase(),
            style: TextStyle(color: t.textSecondary, fontSize: 13,
                fontWeight: FontWeight.w600))),
        ),
        loadingBuilder: (_, child, p) => p == null ? child : Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: t.avatarBg, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// Helper — favicon URL por fonte
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

void _showVideoMenu(BuildContext context, FeedVideo video, Offset pos, AppTheme t) {
  PopupMenuItem<String> _item(String val, String assetPath, String label) =>
      PopupMenuItem<String>(
        value: val, height: 46,
        child: Row(children: [
          SvgPicture.asset(assetPath, width: 17, height: 17,
              colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: TextStyle(color: t.text, fontSize: 13.5))),
        ]),
      );

  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  showMenu<String>(
    context: context,
    color: t.popup,
    elevation: 6,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: t.borderSoft)),
    position: RelativeRect.fromRect(pos & const Size(1, 1), Offset.zero & overlay.size),
    items: [
      _item('save',     'assets/icons/svg/save_later.svg', 'Guardar para assistir mais tarde'),
      _item('playlist', 'assets/icons/svg/playlist.svg',  'Adicionar na minha playlist'),
      _item('next',     'assets/icons/svg/play_next.svg',  'Exibir como próximo vídeo'),
    ],
  ).then((val) {
    if (val == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(val == 'save'
          ? 'Guardado para assistir mais tarde'
          : val == 'playlist' ? 'Adicionado à playlist' : 'Será exibido a seguir',
          style: TextStyle(color: AppTheme.current.toastText)),
      backgroundColor: AppTheme.current.toastBg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  });
}


// ─────────────────────────────────────────────────────────────────────────────
// _PhotoCard — card de foto estilo post do Facebook/Instagram
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoCard extends StatefulWidget {
  final FeedPhoto photo;
  const _PhotoCard({required this.photo});
  @override State<_PhotoCard> createState() => _PhotoCardState();
}
class _PhotoCardState extends State<_PhotoCard> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final photo = widget.photo;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      color: t.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                photo.source, width: 36, height: 36,
                fit: BoxFit.cover,
                headers: const {'User-Agent': 'Mozilla/5.0'},
                errorBuilder: (_, __, ___) => Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: t.avatarBg, shape: BoxShape.circle),
                  child: Center(child: Text(
                    photo.sourceLabel[0],
                    style: TextStyle(color: t.textSecondary,
                        fontSize: 14, fontWeight: FontWeight.w700),
                  )),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(photo.sourceLabel,
                  style: TextStyle(color: t.text, fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
                Text('Galeria de fotos',
                  style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
              ],
            )),
          ]),
        ),

        if (photo.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(photo.title,
              style: TextStyle(color: t.text, fontSize: 13.5, height: 1.4),
              maxLines: 2, overflow: TextOverflow.ellipsis),
          ),

        AspectRatio(
          aspectRatio: 4 / 3,
          child: Image.network(
            photo.url,
            fit: BoxFit.cover,
            width: double.infinity,
            headers: const {
              'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
              'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
            },
            errorBuilder: (_, __, ___) => Container(
              color: t.thumbBg,
              child: Center(child: Icon(Icons.image_not_supported_rounded,
                  color: t.iconSub, size: 40)),
            ),
            loadingBuilder: (_, child, p) => p == null ? child
                : _ThumbShimmer(),
          ),
        ),

        if (photo.likes > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
            child: Text(
              '${_liked ? photo.likes + 1 : photo.likes} gostos',
              style: TextStyle(color: t.textSecondary, fontSize: 12),
            ),
          ),

        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(color: t.divider, height: 1, thickness: 0.5),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          child: Row(children: [
            _PhotoAction(
              icon: _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              label: 'Gosto',
              color: _liked ? Colors.red : t.textSecondary,
              onTap: () => setState(() => _liked = !_liked),
            ),
            _PhotoAction(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Comentar',
              color: t.textSecondary,
              onTap: () {},
            ),
            _PhotoAction(
              icon: Icons.share_rounded,
              label: 'Partilhar',
              color: t.textSecondary,
              onTap: () {},
            ),
          ]),
        ),
      ]),
    );
  }
}

class _PhotoAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PhotoAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(label,
              style: TextStyle(color: color, fontSize: 12.5,
                  fontWeight: FontWeight.w500)),
          ]),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _SitesRow — linha única horizontal deslizável (todos os sites)
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


