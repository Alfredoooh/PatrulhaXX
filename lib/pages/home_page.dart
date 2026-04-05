import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_tab_page.dart';
import 'biblioteca_page.dart';
import '../services/theme_service.dart';
import 'explore_page.dart';
import '../theme/app_theme.dart';
import '../models/feed_photo_model.dart';
import 'create_post_page.dart';

const kPrimaryColor = Color(0xFFFF9000);

// ─────────────────────────────────────────────────────────────────────────────
// CupertinoPageRoute helper
// ─────────────────────────────────────────────────────────────────────────────
Route<T> iosRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

// ─────────────────────────────────────────────────────────────────────────────
// kSites
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

  static const double _kDrawerWidth = 260;
  static const double _kAppShift    = 110;
  static const Duration _kAnimDur   = Duration(milliseconds: 420);
  static const Cubic    _kAnimCurve = Cubic(0.22, 1.0, 0.36, 1.0);

  bool   _drawerOpen = false;
  double _dragX      = 0;
  bool   _dragging   = false;

  void _openDrawer()   => setState(() => _drawerOpen = true);
  void _closeDrawer()  => setState(() => _drawerOpen = false);
  void _toggleDrawer() => setState(() => _drawerOpen = !_drawerOpen);

  int _tab = 0;
  late final AnimationController _fadeIn;
  late final AnimationController _tabAnim;

  Color _wallpaperColor = Colors.black;

  static const _kNavH = 53.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _tabAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _tabAnim.value = 1.0;
    final saved = ThemeService.instance.wallpaperColor;
    if (saved != null) _wallpaperColor = saved;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) _fadeIn.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeIn.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  void _openSite(SiteModel site) =>
      Navigator.push(context, iosRoute(BrowserPage(site: site)));

  void _onColorExtracted(Color c) {
    if (mounted) {
      setState(() => _wallpaperColor = c);
      ThemeService.instance.setWallpaperColor(c);
    }
  }

  void _openDownloads() =>
      Navigator.push(context, iosRoute(const DownloadsPage()));
  void _openSettings() =>
      Navigator.push(context, iosRoute(const SettingsPage()));

  void _switchTab(int i) {
    if (i == _tab) return;
    setState(() => _tab = i);
    _tabAnim.forward(from: 0.0);
  }

  double get _openProgress {
    if (_dragging) {
      final base = _drawerOpen ? 1.0 : 0.0;
      return (base + _dragX / _kDrawerWidth).clamp(0.0, 1.0);
    }
    return _drawerOpen ? 1.0 : 0.0;
  }

  void _onHorizontalDragStart(DragStartDetails d) {
    if (!_drawerOpen && d.globalPosition.dx > 24) return;
    _dragging = true;
    _dragX = 0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails d) {
    if (!_dragging) return;
    setState(() {
      _dragX = (_dragX + d.delta.dx).clamp(
        _drawerOpen ? -_kDrawerWidth : 0,
        _drawerOpen ? 0 : _kDrawerWidth,
      );
    });
  }

  void _onHorizontalDragEnd(DragEndDetails d) {
    if (!_dragging) return;
    _dragging = false;
    final velocity = d.primaryVelocity ?? 0;
    final progress = _openProgress;
    if (velocity > 300 || (velocity >= 0 && progress > 0.4)) {
      _openDrawer();
    } else {
      _closeDrawer();
    }
    setState(() => _dragX = 0);
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final progress   = _openProgress;

    final contentLeft = progress * _kAppShift;
    final drawerLeft  = -_kDrawerWidth + progress * _kDrawerWidth;

    return PopScope(
      canPop: !_drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _drawerOpen) _closeDrawer();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: AppTheme.current.statusBar,
        ),
        child: Scaffold(
          backgroundColor: AppTheme.current.bg,
          body: GestureDetector(
            onHorizontalDragStart:  _onHorizontalDragStart,
            onHorizontalDragUpdate: _onHorizontalDragUpdate,
            onHorizontalDragEnd:    _onHorizontalDragEnd,
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: _dragging ? Duration.zero : _kAnimDur,
                  curve: _kAnimCurve,
                  top: 0, bottom: 0,
                  left: contentLeft,
                  right: -contentLeft,
                  child: Column(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: ThemeService.instance,
                          builder: (_, __) => FadeTransition(
                            opacity: _tabAnim,
                            child: IndexedStack(
                              index: _tab,
                              children: [
                                _HomeTab(
                                  fadeIn: _fadeIn,
                                  onOpen: _openSite,
                                  onMenu: _toggleDrawer,
                                  onColorExtracted: _onColorExtracted,
                                ),
                                ExplorePage(onVideoTap: (_) {}),
                                const SearchTabPage(),
                                const BibliotecaPage(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      _BottomNav(
                        tab: _tab,
                        onTab: _switchTab,
                        navH: _kNavH,
                        safeBottom: safeBottom,
                      ),
                    ],
                  ),
                ),

                if (progress > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: !_drawerOpen,
                      child: GestureDetector(
                        onTap: _closeDrawer,
                        child: Container(
                          color: Color.fromRGBO(0, 0, 0, progress * 0.18),
                        ),
                      ),
                    ),
                  ),

                AnimatedPositioned(
                  duration: _dragging ? Duration.zero : _kAnimDur,
                  curve: _kAnimCurve,
                  top: 0, bottom: 0,
                  left: drawerLeft,
                  width: _kDrawerWidth,
                  child: _NavDrawer(
                    onDownloads: () { _closeDrawer(); _openDownloads(); },
                    onSettings:  () { _closeDrawer(); _openSettings();  },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _BottomNav
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  final double navH, safeBottom;

  const _BottomNav({
    required this.tab,
    required this.onTab,
    required this.navH,
    required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        return Container(
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(
              top: BorderSide(color: t.divider, width: 0.6),
            ),
          ),
          child: SizedBox(
            height: navH + safeBottom,
            child: Padding(
              padding: EdgeInsets.only(top: 8, bottom: safeBottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavIcon(
                    label: 'Início',
                    assetFilled:  'assets/icons/svg/browse_filled.svg',
                    assetOutline: 'assets/icons/svg/browse_outline.svg',
                    active: tab == 0,
                    onTap: () => onTab(0),
                  ),
                  _NavIcon(
                    label: 'Explorar',
                    assetFilled:  'assets/icons/svg/explore_filled.svg',
                    assetOutline: 'assets/icons/svg/explore_outline.svg',
                    active: tab == 1,
                    onTap: () => onTab(1),
                  ),
                  _NavIcon(
                    label: 'Pesquisa',
                    assetFilled:  'assets/icons/svg/search_filled.svg',
                    assetOutline: 'assets/icons/svg/search_outline.svg',
                    active: tab == 2,
                    onTap: () => onTab(2),
                  ),
                  _NavIcon(
                    label: 'Biblioteca',
                    assetFilled:  'assets/icons/svg/library_filled.svg',
                    assetOutline: 'assets/icons/svg/library_outline.svg',
                    active: tab == 3,
                    onTap: () => onTab(3),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavIcon extends StatelessWidget {
  final String label, assetFilled, assetOutline;
  final bool active;
  final VoidCallback onTap;

  const _NavIcon({
    required this.label,
    required this.active,
    required this.onTap,
    required this.assetFilled,
    required this.assetOutline,
  });

  @override
  Widget build(BuildContext context) {
    final color = active
        ? AppTheme.current.navActive
        : AppTheme.current.navInactive;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              child: SvgPicture.asset(
                  active ? assetFilled : assetOutline,
                  width: 22, height: 22),
            ),
            const SizedBox(height: 5),
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
  const _WallpaperColorExtractor(
      {required this.imageUrl, required this.onColor});

  @override
  State<_WallpaperColorExtractor> createState() =>
      _WallpaperColorExtractorState();
}

class _WallpaperColorExtractorState
    extends State<_WallpaperColorExtractor> {
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
        initialData:
            InAppWebViewInitialData(data: _html, mimeType: 'text/html'),
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
                widget.onColor(Color.fromARGB(255, int.parse(p[0]),
                    int.parse(p[1]), int.parse(p[2])));
              } catch (_) {
                widget.onColor(Colors.black);
              }
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
  final VoidCallback onDownloads, onSettings;
  const _NavDrawer({required this.onDownloads, required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        return Container(
          decoration: BoxDecoration(
            color: t.drawerBg,
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.12),
                blurRadius: 14,
                offset: Offset(2, 0),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(children: [
                    Image.asset('assets/logo.png', width: 28, height: 28),
                    const SizedBox(width: 10),
                    Text('nuxxx',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        )),
                  ]),
                ),
                Divider(color: t.divider, height: 1, thickness: 1),
                const SizedBox(height: 4),
                _DrawerItemSvg(
                  assetPath: 'assets/icons/svg/drawer_download.svg',
                  label: 'Downloads',
                  onTap: onDownloads,
                ),
                _DrawerItemSvg(
                  assetPath: 'assets/icons/svg/drawer_settings.svg',
                  label: 'Definições',
                  onTap: onSettings,
                ),
                const Spacer(),
                Divider(color: t.divider, height: 1, thickness: 1),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  child: Text('nuxxx',
                      style: TextStyle(
                          color: t.textTertiary, fontSize: 11)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrawerItemSvg extends StatelessWidget {
  final String assetPath, label;
  final VoidCallback onTap;
  const _DrawerItemSvg(
      {required this.assetPath, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SvgPicture.asset(assetPath,
              width: 20, height: 20,
              colorFilter:
                  ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
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
class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final void Function(SiteModel) onOpen;
  final VoidCallback onMenu;
  final void Function(Color) onColorExtracted;

  const _HomeTab({
    required this.fadeIn,
    required this.onOpen,
    required this.onMenu,
    required this.onColorExtracted,
  });

  @override
  Widget build(BuildContext context) {
    final ts = ThemeService.instance;
    final t  = AppTheme.current;

    return Stack(fit: StackFit.expand, children: [
      Container(color: t.bg),

      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned.fill(
          child: Image.asset(
            ts.bg,
            fit: BoxFit.cover,
            key: ValueKey(ts.bg),
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),

      if (ts.useWallpaper && ts.bg.isNotEmpty)
        Positioned(
          left: -1, top: -1, width: 1, height: 1,
          child: _WallpaperColorExtractor(
              imageUrl: ts.bg,
              onColor: onColorExtracted),
        ),

      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: Column(children: [
          SafeArea(
            bottom: false,
            child: _HomeAppBar(onMenu: onMenu),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _SitesRow(sites: kSites, onTap: onOpen),
                  ),
                ),
                const SliverToBoxAdapter(child: _HomeFeedSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
              ],
            ),
          ),
        ]),
      ),
    ]);
  }
}


// ─── AppBar da home ───────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final VoidCallback onMenu;
  const _HomeAppBar({required this.onMenu});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: SizedBox(
        height: 44,
        child: Row(children: [
          GestureDetector(
            onTap: onMenu,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 38, height: 44,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/svg/hamburger.svg',
                  width: 22, height: 22,
                  colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const Spacer(),
          // ── botão "+" abre CreatePostPage ─────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              iosRoute(const CreatePostPage()),
            ),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 38, height: 44,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/svg/plus.svg',
                  width: 22, height: 22,
                  colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _HomeFeedSection
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
  int  _page = 1;

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
          children: List.generate(3, (_) => _PhotoCardSkeleton()));
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
                    color: t.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
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
              'User-Agent':
                  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36',
              'Accept':
                  'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
            },
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              color: t.thumbBg,
              child: Center(
                  child: Icon(Icons.image_not_supported_rounded,
                      color: t.iconSub, size: 28)),
            ),
            loadingBuilder: (_, child, p) => p == null
                ? child
                : Container(
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
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
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
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

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
            begin: Alignment(_a.value - 1, 0),
            end: Alignment(_a.value + 1, 0),
            colors: AppTheme.current.shimmer,
          ),
        ),
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
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sites.length,
        itemBuilder: (_, i) =>
            _SiteCell(site: sites[i], onTap: () => onTap(sites[i])),
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

class _SiteCellState extends State<_SiteCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 200),
        lowerBound: 0,
        upperBound: 1);
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 52;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SiteIconWidget(site: widget.site, size: iconSize, showShadow: true),
            const SizedBox(height: 5),
            SizedBox(
              width: iconSize + 10,
              child: Text(widget.site.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
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
