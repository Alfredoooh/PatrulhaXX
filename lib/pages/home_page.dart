import 'dart:ui';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:animations/animations.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_results_page.dart';
import 'package:http/http.dart' as http;
import '../services/theme_service.dart';
import 'exibicao_page.dart';
import '../theme/app_theme.dart';

const kPrimaryColor = Color(0xFFFF9000);

// ─── SVGs ────────────────────────────────────────────────────────────────────
// Shorts — ícone TikTok-style, vermelho quando ativo
const _svgShortsActive =
    __SVG_0__;

// Outline neutro para estado inativo
const _svgShortsInactive =
    __SVG_1__;

const _svgDownload =
    __SVG_2__;

const _svgSettings =
    __SVG_3__;

const svgExibicaoFilled =
    __SVG_4__;

const svgExibicaoOutline =
    __SVG_5__;

const _svgBrowseFilled =
    __SVG_6__;

const _svgBrowseOutline =
    __SVG_7__;

// ─── Shorts JS ────────────────────────────────────────────────────────────────
const _shortsJsCookies = r"""
(function() {
  var d = new Date(); d.setFullYear(d.getFullYear() + 2);
  var exp = '; expires=' + d.toUTCString() + '; path=/';
  ['age_verified=1','platform=pc','_tc=1','hasVisited=1',
   'cookieConsent=1','accessAgeDisclaimerPH=1','accessPH=1'].forEach(function(c){
    document.cookie = c + exp;
  });
})();
""";

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
// HomePage
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 1; // Feed é o tab principal
  String? _selectedEmbedUrl;
  FeedVideo? _selectedVideo;
  bool _miniPlayerActive = false; // vídeo a tocar em mini player
  late final AnimationController _fadeIn;

  // Cor extraída via HTML do wallpaper
  Color _wallpaperColor = Colors.black;

  static const _kNavH = 62.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    final saved = ThemeService.instance.wallpaperColor;
    if (saved != null) _wallpaperColor = saved;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) _fadeIn.forward();
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeIn.dispose();
    super.dispose();
  }

  void _openSite(SiteModel site) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => BrowserPage(site: site)));

  void _onColorExtracted(Color c) {
    if (mounted) {
      setState(() => _wallpaperColor = c);
      ThemeService.instance.setWallpaperColor(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final navTotal   = _kNavH + safeBottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.of(context).statusBarBrightness,
      ),
      child: Scaffold(
        extendBody: false,
        backgroundColor: AppTheme.of(context).bgFeed,
        body: Column(children: [
          // ── Tabs — IndexedStack preserva estado do feed ───────────────
          Expanded(
            child: AnimatedBuilder(
              animation: ThemeService.instance,
              builder: (_, __) {
                return IndexedStack(
                  index: _tab,
                  children: [
                    _HomeTab(
                      fadeIn: _fadeIn,
                      navBottom: 0,
                      onOpen: _openSite,
                      onDownloads: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DownloadsPage())),
                      onSettings: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const SettingsPage())),
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
                      },
                    ),
                    ExibicaoPage(
                      embedUrl: _selectedEmbedUrl,
                      currentVideo: _selectedVideo,
                      onVideoTap: (FeedVideo video) {
                        setState(() {
                          _selectedEmbedUrl = video.embedUrl;
                          _selectedVideo = video;
                        });
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // ── Mini Player — aparece entre conteúdo e bottom nav ────────
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

          // ── Bottom Nav fixo ────────────────────────────────────────────
          _BottomNav(
            tab: _tab,
            onTab: (i) {
              setState(() {
                if (i == 2 && i != _tab) {
                  _selectedEmbedUrl = null;
                  _selectedVideo = null;
                  _miniPlayerActive = false;
                } else if (i != 2 && _tab == 2 && _selectedVideo != null) {
                  _miniPlayerActive = true;
                } else if (i == 2) {
                  _miniPlayerActive = false;
                }
                _tab = i;
              });
            },
            navH: _kNavH,
            safeBottom: safeBottom,
          ),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _MiniPlayer — vídeo em curso abaixo do conteúdo, acima do bottom nav
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
    // Auto-play após 1s
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
    final isDark = t.isDark;
    final bg = isDark ? const Color(0xFF212121) : Colors.white;
    final textColor = t.navActive;
    final subColor = isDark ? Colors.white54 : Colors.black45;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
          .animate(CurvedAnimation(parent: _slideIn, curve: Curves.easeOutCubic)),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          // Colado ao bottom nav — sem margem lateral, sem margem inferior
          width: double.infinity,
          height: 64,
          color: bg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Linha de progresso no topo (como YouTube) ────────────
              Container(
                height: 2,
                color: AppTheme.current.divider,
                child: FractionallySizedBox(
                  widthFactor: 0.35, // placeholder — sem progresso real no embed
                  alignment: Alignment.centerLeft,
                  child: Container(color: kPrimaryColor),
                ),
              ),

              // ── Conteúdo ──────────────────────────────────────────────
              Expanded(
                child: Row(children: [

                  // Thumbnail — sem padding lateral, colado à esquerda
                  SizedBox(
                    width: 114, height: 62,
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(
                        widget.video.thumb,
                        fit: BoxFit.cover,
                        headers: const {'User-Agent': 'Mozilla/5.0'},
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF333333),
                          child: const Icon(Icons.play_circle_rounded,
                              color: AppTheme.current.textSub, size: 28),
                        ),
                      ),
                      // WebView invisível — mantém embed activo em background
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

                  // Título + canal
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

                  // ── Pause / Play — ícone grande como YouTube ──────────
                  GestureDetector(
                    onTap: _togglePlay,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Icon(
                        _playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: textColor,
                        size: 28,
                      ),
                    ),
                  ),

                  // ── Fechar ────────────────────────────────────────────
                  GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Icon(
                        Icons.close_rounded,
                        color: subColor,
                        size: 24,
                      ),
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
// _BottomNav
// Feed: pill sempre activo com SVG vermelho sempre ligado
// Navegar + Exibição: sem pill, ícone + label em baixo
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  final double navH, safeBottom;
  Color get _kBg => AppTheme.of(context).bgNav;

  const _BottomNav({
    required this.tab, required this.onTab,
    required this.navH, required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kBg,
        border: Border(top: BorderSide(
          color: AppTheme.current.navBorder,
          width: 0.5)),
      ),
      padding: EdgeInsets.only(bottom: safeBottom),
      height: navH + safeBottom,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Navegar — sem pill, ícone + label em baixo
          _NavIcon(
            label: 'Navegar',
            svgFilled: _svgBrowseFilled,
            svgOutline: _svgBrowseOutline,
            active: tab == 0,
            onTap: () => onTab(0),
          ),
          // Feed — pill sempre activo, SVG vermelho sempre ligado
          _NavFeedPill(
            active: tab == 1,
            onTap: () => onTab(1),
          ),
          // Exibição — sem pill, SVG próprio + label em baixo
          _NavIcon(
            label: 'Exibição',
            svgFilled: svgExibicaoFilled,
            svgOutline: svgExibicaoOutline,
            active: tab == 2,
            onTap: () => onTab(2),
          ),
        ],
      ),
    );
  }
}

// ─── Tab Navegar / Exibição — ícone + label em baixo, sem pill ───────────────
class _NavIcon extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final String svgFilled, svgOutline;

  const _NavIcon({
    required this.label,
    required this.active,
    required this.onTap,
    required this.svgFilled,
    required this.svgOutline,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final isDark = t.isDark;
    final color = active ? (t.navActive) : (t.navInactive);
    final iconW = ColorFiltered(
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      child: SvgPicture.string(active ? svgFilled : svgOutline, width: 22, height: 22),
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

// ─── Tab Feed — pill sempre visível, linha cinza quando inactivo ──────────────
class _NavFeedPill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _NavFeedPill({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          // Activo: fill branco translúcido — Inactivo: apenas borda cinza
          color: active ? Colors.white.withOpacity(0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: t.navBorder.withOpacity(active ? 0.0 : 1.0),
            width: 1.2,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.string(_svgShortsActive, width: 22, height: 22),
          // Texto "Feed" SEMPRE visível
          const SizedBox(width: 7),
          Text('Feed',
            style: TextStyle(
              color: (AppTheme.of(context).text).withOpacity(active ? 1.0 : 0.70),
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              letterSpacing: -0.2,
            )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _WallpaperColorExtractor  (WebView HTML/Canvas — sem package externo)
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
// _HomeTab
// ─────────────────────────────────────────────────────────────────────────────

// ─── AppBar do Navegar ────────────────────────────────────────────────────────
class _NavAppBar extends StatelessWidget {
  final VoidCallback onMenu;
  const _NavAppBar({required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.only(top: topPad + 6, bottom: 4),
      child: Row(children: [
        // Menu hamburguer
        GestureDetector(
          onTap: onMenu,
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: AppTheme.current.border,
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _HamburgerLine(),
                const SizedBox(height: 4),
                _HamburgerLine(width: 14),
                const SizedBox(height: 4),
                _HamburgerLine(),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('Navegar',
          style: TextStyle(color: AppTheme.of(context).text, fontSize: 20,
              fontWeight: FontWeight.w700, letterSpacing: -0.5)),
      ]),
    );
  }
}

class _HamburgerLine extends StatelessWidget {
  final double width;
  const _HamburgerLine({this.width = 18});
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: 1.8,
    decoration: BoxDecoration(
      color: AppTheme.current.iconSub,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}

// ─── Drawer do Navegar ────────────────────────────────────────────────────────
class _NavDrawer extends StatelessWidget {
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  const _NavDrawer({required this.onDownloads, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Drawer(
      backgroundColor: AppTheme.of(context).bgNav,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad + 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Row(children: [
            SvgPicture.string(_svgShortsActive, width: 32, height: 32),
            const SizedBox(width: 10),
            Text('patrulhaXX',
              style: TextStyle(color: AppTheme.of(context).text, fontSize: 18,
                  fontWeight: FontWeight.w700)),
          ]),
        ),
        Divider(color: AppTheme.current.bg  /* 222222) / const Color(0xFFE0E0E0) */, height: 1),
        const SizedBox(height: 8),
        _DrawerItem(
          icon: Icons.download_rounded,
          label: 'Downloads',
          onTap: () { Navigator.pop(context); onDownloads(); },
        ),
        _DrawerItem(
          icon: Icons.settings_rounded,
          label: 'Definições',
          onTap: () { Navigator.pop(context); onSettings(); },
        ),
        const Spacer(),
        Divider(color: AppTheme.current.bg  /* 222222) / const Color(0xFFE0E0E0) */, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Text('patrulhaXX',
            style: TextStyle(color: AppTheme.current.textHint,
                fontSize: 11)),
        ),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppTheme.current.iconSub, size: 22),
    title: Text(label,
        style: TextStyle(color: AppTheme.current.drawerText, fontSize: 14,
            fontWeight: FontWeight.w500)),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
  );
}

class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final double navBottom;
  final void Function(SiteModel) onOpen;
  final VoidCallback onDownloads, onSettings;
  final void Function(Color) onColorExtracted;
  final Color navColor;
  final bool navIsLight;

  const _HomeTab({
    required this.fadeIn,
    required this.navBottom,
    required this.onOpen,
    required this.onDownloads,
    required this.onSettings,
    required this.onColorExtracted,
    required this.navColor,
    required this.navIsLight,
  });

  @override
  Widget build(BuildContext context) {
    final ts = ThemeService.instance;
    return Scaffold(
      backgroundColor: AppTheme.of(context).bg,
      drawer: _NavDrawer(
        onDownloads: onDownloads,
        onSettings: onSettings,
      ),
      body: Builder(builder: (scaffoldCtx) => Stack(fit: StackFit.expand, children: [
      // Fundo
      Container(color: AppTheme.of(context).bg),

      // Wallpaper (muda instantaneamente com key)
      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned.fill(
          child: Image.asset(
            ts.bg,
            fit: BoxFit.cover,
            key: ValueKey(ts.bg),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

      // Extrator de cor
      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned(
          left: -1, top: -1, width: 1, height: 1,
          child: _WallpaperColorExtractor(
            imageUrl: ts.bg,
            onColor: onColorExtracted,
          ),
        ),

      // Conteúdo
      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── AppBar Navegar com menu drawer ─────────────────
                    _NavAppBar(onMenu: () => Scaffold.of(scaffoldCtx).openDrawer()),
                    const SizedBox(height: 10),
                    // ── Search bar ─────────────────────────────────────
                    _SearchTrigger(
                      navColor: navColor,
                      navIsLight: navIsLight,
                    ),
                    const SizedBox(height: 10),
                    // ── Botões Downloads + Settings ────────────────────
                    _ActionRow(
                      onDownloads: onDownloads,
                      onSettings: onSettings,
                      navColor: navColor,
                      navIsLight: navIsLight,
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _SitesGrid(sites: kSites, onTap: onOpen),
          ),
          SliverToBoxAdapter(child: SizedBox(height: navBottom + 16)),
        ]),
      ),
    ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchTrigger  —  toca no input → abre SearchResultsPage com container transform
// ─────────────────────────────────────────────────────────────────────────────
class _SearchTrigger extends StatelessWidget {
  final Color navColor;
  final bool navIsLight;
  const _SearchTrigger({required this.navColor, required this.navIsLight});

  Color get _bgColor => navIsLight
      ? Colors.black.withOpacity(0.08)
      : Colors.white.withOpacity(0.10);

  Color get _borderColor => navIsLight
      ? Colors.black.withOpacity(0.10)
      : Colors.white.withOpacity(0.12);

  Color get _hintColor => navIsLight
      ? Colors.black.withOpacity(0.40)
      : Colors.white.withOpacity(0.35);

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 420),
      transitionType: ContainerTransitionType.fadeThrough,
      openColor: Colors.black,
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
            const SizedBox(width: 18),
            Icon(Icons.search_rounded, color: _hintColor, size: 20),
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

// ─── Página de pesquisa que abre com o container transform ───────────────────
class _SearchPage extends StatefulWidget {
  const _SearchPage();
  @override
  State<_SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<_SearchPage> {
  final _ctrl = TextEditingController();
  bool get _hasQuery => _ctrl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Auto-focus com pequeno delay para a animação terminar
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

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.of(context).statusBarBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).bgFeed,
        body: Column(children: [
          SizedBox(height: topPad + 12),
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.current.border,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: AppTheme.current.icon, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.of(context).bgInput,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: AppTheme.current.inputBorder),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 18),
                    Icon(Icons.search_rounded,
                        color: AppTheme.of(context).textSub, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(color: AppTheme.current.inputText, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        cursorColor: kPrimaryColor,
                        cursorWidth: 1.5,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintText: 'Pesquisar...',
                          hintStyle: TextStyle(
                              color: AppTheme.current.inputHint, fontSize: 15),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 13),
                        ),
                      ),
                    ),
                    if (_hasQuery)
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: kPrimaryColor,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text('Ir',
                              style: TextStyle(
                                  color: AppTheme.of(context).bgFeed, fontSize: 13,
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
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionRow  —  Downloads + Settings com cor adaptativa ao wallpaper
// Bordas 100% redondas (circular) iguais ao search
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final VoidCallback onDownloads, onSettings;
  final Color navColor;
  final bool navIsLight;

  const _ActionRow({
    required this.onDownloads, required this.onSettings,
    required this.navColor, required this.navIsLight,
  });

  Color get _bgColor => navIsLight
      ? Colors.black.withOpacity(0.08)
      : Colors.white.withOpacity(0.08);

  Color get _borderColor => navIsLight
      ? Colors.black.withOpacity(0.10)
      : Colors.white.withOpacity(0.10);

  Color get _contentColor => navIsLight
      ? Colors.black.withOpacity(0.60)
      : Colors.white.withOpacity(0.70);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ActionBtn(
        label: 'Downloads', onTap: onDownloads,
        bgColor: _bgColor, borderColor: _borderColor, contentColor: _contentColor,
        isDownloads: true,
      )),
      const SizedBox(width: 10),
      Expanded(child: _ActionBtn(
        svg: _svgSettings, label: 'Definições', onTap: onSettings,
        bgColor: _bgColor, borderColor: _borderColor, contentColor: _contentColor,
        isSettings: true,
      )),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String? svg;
  final String label;
  final VoidCallback onTap;
  final Color bgColor, borderColor, contentColor;
  final bool isDownloads;
  final bool isSettings;

  const _ActionBtn({
    this.svg,
    required this.label, required this.onTap,
    required this.bgColor, required this.borderColor, required this.contentColor,
    this.isDownloads = false,
    this.isSettings = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget iconWidget;
    if (isDownloads) {
      // PNG asset guardado localmente — nunca depende de rede
      iconWidget = Image.asset(
        'assets/icons/downloads_folder.png',
        width: 38, height: 38,
      );
    } else if (isSettings) {
      // SVG com gradientes próprios — SEM ColorFilter para preservar as cores
      iconWidget = SvgPicture.string(svg!, width: 38, height: 38);
    } else {
      iconWidget = SvgPicture.string(svg!, width: 17, height: 17,
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
                  color: contentColor, fontSize: 13, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modelo unificado de vídeo — 4 fontes: Eporner, Pornhub, RedTube, YouPorn
// ─────────────────────────────────────────────────────────────────────────────
enum VideoSource { eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang }

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
      case VideoSource.eporner:  return 'Eporner';
      case VideoSource.pornhub:  return 'Pornhub';
      case VideoSource.redtube:  return 'RedTube';
      case VideoSource.youporn:  return 'YouPorn';
      case VideoSource.xvideos:  return 'XVideos';
      case VideoSource.xhamster: return 'xHamster';
      case VideoSource.spankbang: return 'SpankBang';
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:  return 'E';
      case VideoSource.pornhub:  return 'P';
      case VideoSource.redtube:  return 'R';
      case VideoSource.youporn:  return 'Y';
      case VideoSource.xvideos:  return 'XV';
      case VideoSource.xhamster: return 'XH';
      case VideoSource.spankbang: return 'SB';
    }
  }

  Color get sourceColor => const Color(0xFF222222);

  // ── Eporner ────────────────────────────────────────────────────────────────
  static FeedVideo? fromEporner(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    if (id.isEmpty) return null;
    String thumb = '';
    final thumbs = j['thumbs'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      // Prefere maior resolução disponível
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

  // ── Pornhub (HubTraffic) ───────────────────────────────────────────────────
  static FeedVideo? fromPornhub(Map<String, dynamic> j) {
    final viewkey = j['video_id'] as String? ?? j['viewkey'] as String? ?? '';
    if (viewkey.isEmpty) return null;
    // Thumbnail: PH devolve lista 'thumbs' ou campo 'default_thumb'
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

  // ── RedTube ────────────────────────────────────────────────────────────────
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

  // ── YouPorn ────────────────────────────────────────────────────────────────
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
    // Corrige títulos com encoding errado (latin1 interpretado como utf8)
    try {
      final bytes = latin1.encode(raw);
      final decoded = utf8.decode(bytes, allowMalformed: true);
      // Se o resultado tem mais caracteres válidos, usa-o
      if (decoded.runes.where((r) => r > 127).length <
          raw.runes.where((r) => r > 127).length) {
        return decoded;
      }
    } catch (_) {}
    return raw;
  }


  // ── XVideos ────────────────────────────────────────────────────────────────
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

  // ── xHamster ───────────────────────────────────────────────────────────────
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

  // ── SpankBang ───────────────────────────────────────────────────────────────
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

  static String _fmtViews(dynamic v) {
    if (v == null) return '';
    final n = int.tryParse(v.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}K';
    return n > 0 ? n.toString() : '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedFetcher — lógica de fetch das 4 fontes
// ─────────────────────────────────────────────────────────────────────────────
class FeedFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36';
  static const _epOrders = ['top-weekly', 'top-monthly', 'latest', 'most-viewed'];
  static const _phOrders = ['newest', 'mostviewed', 'rating'];
  static const _rtOrders = ['new', 'rating', 'views'];

  static Future<List<FeedVideo>> fetchEporner(int page) async {
    try {
      final order = _epOrders[Random().nextInt(_epOrders.length)];
      final term = _terms[Random().nextInt(_terms.length)];
      final r = await http.get(
        Uri.parse('https://www.eporner.com/api/v2/video/search/'
            '?query=$term&per_page=20&page=$page&thumbsize=big&order=$order&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      return (data['videos'] as List? ?? [])
          .map((v) => FeedVideo.fromEporner(v as Map<String, dynamic>))
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchPornhub(int page) async {
    try {
      final order = _phOrders[Random().nextInt(_phOrders.length)];
      final term = _terms[Random().nextInt(_terms.length)];
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/search'
            '?search=$term&ordering=$order&page=$page&thumbsize=medium&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 14));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = data['videos'] as List? ?? data['video'] as List? ?? [];
      return videos
          .map((v) => FeedVideo.fromPornhub(v as Map<String, dynamic>))
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchRedtube(int page) async {
    try {
      final order = _rtOrders[Random().nextInt(_rtOrders.length)];
      final term = _terms[Random().nextInt(_terms.length)];
      final r = await http.get(
        Uri.parse('https://api.redtube.com/'
            '?data=redtube.Videos.searchVideos&output=json'
            '&search=$term&ordering=$order&page=$page&thumbsize=big'),
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
            '?is_top=1&page=$page&per_page=20'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body);
      final videos = (data['videos'] ?? data['data'] ?? data) as List? ?? [];
      return videos
          .map((v) => FeedVideo.fromYouporn(v as Map<String, dynamic>))
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }


  static Future<List<FeedVideo>> fetchXvideos(int page) async {
    try {
      final term = _terms[Random().nextInt(_terms.length)];
      final r = await http.get(
        Uri.parse('https://www.xvideos.com/api/videos/search/$term/$page/?q=${Uri.encodeComponent(term)}'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = data['videos'] as List? ?? [];
      return videos.map((v) => FeedVideo.fromXvideos(v as Map<String, dynamic>))
          .whereType<FeedVideo>().toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    try {
      final term = _terms[Random().nextInt(_terms.length)];
      final r = await http.get(
        Uri.parse('https://xhamster.com/api/front/search?q=${Uri.encodeComponent(term)}&page=$page&sectionName=video'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final items = (data['data']?['videos']?['models'] as List?) ?? [];
      return items.map((v) => FeedVideo.fromXhamster(v as Map<String, dynamic>))
          .whereType<FeedVideo>().toList();
    } catch (_) { return []; }
  }

  /// Busca todas as fontes em paralelo, mistura e baralha
  // Termos aleatórios para variar resultados a cada fetch
  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
  ];

  static Future<List<FeedVideo>> fetchAll(int page) async {
    // Seed baseado no tempo — cada chamada produz resultados completamente diferentes
    final rng = Random(DateTime.now().millisecondsSinceEpoch ^ page.hashCode);
    final epPage  = rng.nextInt(60) + 1;
    final phPage  = rng.nextInt(40) + 1;
    final rtPage  = rng.nextInt(30) + 1;
    final ypPage  = rng.nextInt(20) + 1;

    final xvPage  = rng.nextInt(50) + 1;
    final xhPage  = rng.nextInt(30) + 1;

    final results = await Future.wait([
      fetchEporner(epPage),
      fetchPornhub(phPage),
      fetchRedtube(rtPage),
      fetchYouporn(ypPage),
      fetchXvideos(xvPage),
      fetchXhamster(xhPage),
    ]);

    // Intercala as fontes em vez de concatenar — parece mais variado
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
// _ShortsTab — Feed multi-fonte estilo YouTube
// ─────────────────────────────────────────────────────────────────────────────
class _ShortsTab extends StatefulWidget {
  final double navBottom;
  final void Function(FeedVideo) onVideoTap;
  const _ShortsTab({required this.navBottom, required this.onVideoTap});

  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<_ShortsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedVideo> _videos = [];
  bool _loading = true;
  bool _error = false;
  int _page = 1;
  bool _fetching = false;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.of(context).padding.top;

    if (_loading) {
      return Container(
        color: AppTheme.of(context).bgFeed,
        child: ListView(
          padding: EdgeInsets.only(top: topPad + 56),
          children: List.generate(5, (_) => _FeedCardSkeleton()),
        ),
      );
    }

    if (_error) {
      return Container(
        color: AppTheme.of(context).bgFeed,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, color: AppTheme.of(context).iconFaint, size: 48),
          const SizedBox(height: 16),
          Text('Sem ligação à internet', style: TextStyle(color: AppTheme.current.textSub, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimaryColor, borderRadius: BorderRadius.circular(100)),
              child: const Text('Tentar novamente',
                  style: TextStyle(color: AppTheme.of(context).bgFeed, fontWeight: FontWeight.w700)),
            ),
          ),
        ])),
      );
    }

    final t = AppTheme.current;
    final isDark = t.isDark;
    return Container(
      color: t.bg,
      child: Column(children: [
        // ── AppBar Feed ────────────────────────────────────────────────
        _FeedAppBar(topPad: topPad, onRefresh: _fetch),

        // ── Lista de vídeos ────────────────────────────────────────────
        Expanded(
          child: RefreshIndicator(
            color: kPrimaryColor,
            backgroundColor: const Color(0xFF1A1A1A),
            onRefresh: _fetch,
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: _videos.length + 1,
              itemBuilder: (_, i) {
                if (i == _videos.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 1.5, color: kPrimaryColor))),
                  );
                }
                return _VideoCard(video: _videos[i], onTap: () => widget.onVideoTap(_videos[i]));
              },
            ),
          ),
        ),
      ]),
    );
  }
}


// Helper — favicon URL por fonte
String faviconForSource(VideoSource src) {
  switch (src) {
    case VideoSource.eporner:  return 'https://www.eporner.com/favicon.ico';
    case VideoSource.pornhub:  return 'https://www.pornhub.com/favicon.ico';
    case VideoSource.redtube:  return 'https://www.redtube.com/favicon.ico';
    case VideoSource.youporn:  return 'https://www.youporn.com/favicon.ico';
    case VideoSource.xvideos:  return 'https://www.xvideos.com/favicon.ico';
    case VideoSource.xhamster: return 'https://xhamster.com/favicon.ico';
    case VideoSource.spankbang: return 'https://spankbang.com/favicon.ico';
  }
}


// ─── AppBar do Feed — título + chips de filtro estilo YouTube ─────────────────
class _FeedAppBar extends StatefulWidget {
  final double topPad;
  final VoidCallback onRefresh;
  const _FeedAppBar({required this.topPad, required this.onRefresh});
  @override
  State<_FeedAppBar> createState() => _FeedAppBarState();
}

class _FeedAppBarState extends State<_FeedAppBar> {
  int _selectedChip = 0;
  static const _chips = [
    'Todos', 'Mais vistos', 'Recentes', 'Avaliação',
    'Amador', 'MILF', 'Asiática', 'Latina', 'Loira',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.of(context).bgFeed,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: widget.topPad),
        // Título + refresh
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(children: [
            SvgPicture.string(_svgShortsActive, width: 26, height: 26),
            const SizedBox(width: 8),
            Text('Feed',
              style: TextStyle(color: AppTheme.current.text, fontSize: 20,
                  fontWeight: FontWeight.w700, letterSpacing: -0.5)),
            const Spacer(),
            GestureDetector(
              onTap: widget.onRefresh,
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.current.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.refresh_rounded,
                    color: AppTheme.current.iconSub, size: 20),
              ),
            ),
          ]),
        ),
        // Chips horizontais
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 14, right: 14),
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = _selectedChip == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedChip = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? (AppTheme.of(context).text) : (AppTheme.current.bg  /* 1E1E1E) / const Color(0xFFE5E5EA) */),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(_chips[i],
                    style: TextStyle(
                      color: selected ? (AppTheme.current.isDark ? Colors.black : Colors.white) : AppTheme.current.iconSub,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        const Divider(color: Color(0xFF1A1A1A), height: 1),
      ]),
    );
  }
}


// ─── Feed card skeleton ───────────────────────────────────────────────────────
class _FeedCardSkeleton extends StatefulWidget {
  @override
  State<_FeedCardSkeleton> createState() => _FeedCardSkeletonState();
}
class _FeedCardSkeletonState extends State<_FeedCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _box(double w, double h, {double r = 6}) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: w, height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(r),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: AppTheme.current.shimmer,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail 16:9
        _box(w, w * 9 / 16, r: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(36, 36, r: 18),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w * 0.7, 14),
              const SizedBox(height: 6),
              _box(w * 0.45, 12),
            ])),
          ]),
        ),
      ]),
    );
  }
}

// ─── Card de vídeo estilo YouTube ─────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(
                video.thumb,
                fit: BoxFit.cover,
                cacheWidth: 640, // data saver — limita a 640px (suficiente para 16:9 em mobile)
                headers: const {
                  'User-Agent': 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
                },
                errorBuilder: (_, __, ___) => Container(
                  color: AppTheme.of(context).bgThumb,
                  child: Center(child: Icon(Icons.play_circle_outline_rounded,
                      color: AppTheme.of(context).iconFaint, size: 40)),
                ),
                loadingBuilder: (_, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: AppTheme.of(context).bg,
                    child: Center(child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.2,
                        value: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                            : null,
                        color: AppTheme.of(context).iconFaint,
                      ),
                    )),
                  );
                },
              ),
              // Duration badge
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 6, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black87, borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(color: AppTheme.of(context).text,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
              // Play overlay
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.45), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
              )),
            ]),
          ),

          // Info em baixo — estilo YouTube
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar — favicon do site
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  faviconForSource(video.source),
                  width: 36, height: 36,
                  errorBuilder: (_, __, ___) => Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: Color(0xFF222222), shape: BoxShape.circle),
                    child: Center(child: Text(video.sourceInitial,
                        style: const TextStyle(color: AppTheme.of(context).textSub, fontSize: 13,
                            fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                    style: TextStyle(color: AppTheme.current.text, fontSize: 13.5,
                        fontWeight: FontWeight.w500, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                    style: TextStyle(color: AppTheme.of(context).textSub, fontSize: 11.5),
                  ),
                ],
              )),
              SvgPicture.string(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
                '<circle cx="12" cy="2.5" r="2.5"/>'
                '<circle cx="12" cy="12" r="2.5"/>'
                '<circle cx="12" cy="21.5" r="2.5"/></svg>',
                width: 18, height: 18,
                colorFilter: ColorFilter.mode(
                    Colors.white.withOpacity(0.38), BlendMode.srcIn),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SitesGrid
// ─────────────────────────────────────────────────────────────────────────────
class _SitesGrid extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SitesGrid({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final row1 = sites.length >= 5 ? sites.sublist(0, 5) : sites;
    final row2 = sites.length > 5
        ? sites.sublist(5, sites.length >= 10 ? 10 : sites.length)
        : <SiteModel>[];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.35),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.current.border, width: 0.5),
        ),
        child: Column(children: [
          _SiteRow(sites: row1, onTap: onTap),
          if (row2.isNotEmpty) ...[
            const SizedBox(height: 18),
            _SiteRow(sites: row2, onTap: onTap),
          ],
        ]),
      ),
    );
  }
}

class _SiteRow extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SiteRow({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: sites.map((s) => _SiteCell(site: s, onTap: () => onTap(s))).toList(),
      );
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
    final iconSize = MediaQuery.of(context).size.width * 0.13;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
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
                    fontSize: 10, fontWeight: FontWeight.w500)),
          ),
        ]),
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
