import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/site_model.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_page.dart';
import 'biblioteca_page.dart';
import '../services/theme_service.dart';
import 'explore_page.dart';
import '../theme/app_theme.dart';
import 'create_post_page.dart';

const kPrimaryColor = Color(0xFFFF9000);

Route<T> iosRoute<T>(Widget page) {
  return CupertinoPageRoute<T>(builder: (_) => page);
}

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

  Color _appBarColor = Colors.transparent;

  static const _kNavH = 48.0;

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

  void _onColorExtracted(Color c) {
    if (mounted) setState(() => _appBarColor = c);
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

    final overlayStyle = _tab == 0
        ? const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          )
        : SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: AppTheme.current.statusBar,
          );

    return PopScope(
      canPop: !_drawerOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _drawerOpen) _closeDrawer();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
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
                                  onMenu: _toggleDrawer,
                                  appBarColor: _appBarColor,
                                  onColorExtracted: _onColorExtracted,
                                ),
                                ExplorePage(onVideoTap: (_) {}),
                                const SearchPage(),
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

// ─── BottomNav ────────────────────────────────────────────────────────────────
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
        final isHome = tab == 0;
        return Container(
          decoration: BoxDecoration(
            color: isHome ? const Color(0xFF0A0A0A) : t.bg,
            border: Border(top: BorderSide(
              color: isHome ? const Color(0xFF1A1A1A) : t.divider,
              width: 0.6,
            )),
          ),
          child: SizedBox(
            height: navH + safeBottom,
            child: Padding(
              padding: EdgeInsets.only(bottom: safeBottom),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _NavIcon(
                    assetFilled:  'assets/icons/svg/browse_filled.svg',
                    assetOutline: 'assets/icons/svg/browse_outline.svg',
                    active: tab == 0,
                    onTap: () => onTab(0),
                    forceLight: isHome,
                  ),
                  _NavIcon(
                    assetFilled:  'assets/icons/svg/explore_filled.svg',
                    assetOutline: 'assets/icons/svg/explore_outline.svg',
                    active: tab == 1,
                    onTap: () => onTab(1),
                    forceLight: isHome,
                  ),
                  _NavIcon(
                    assetFilled:  'assets/icons/svg/search_filled.svg',
                    assetOutline: 'assets/icons/svg/search_outline.svg',
                    active: tab == 2,
                    onTap: () => onTab(2),
                    forceLight: isHome,
                  ),
                  _NavIcon(
                    assetFilled:  'assets/icons/svg/library_filled.svg',
                    assetOutline: 'assets/icons/svg/library_outline.svg',
                    active: tab == 3,
                    onTap: () => onTab(3),
                    forceLight: isHome,
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
  final String assetFilled, assetOutline;
  final bool active;
  final bool forceLight;
  final VoidCallback onTap;

  const _NavIcon({
    required this.active,
    required this.onTap,
    required this.assetFilled,
    required this.assetOutline,
    this.forceLight = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (forceLight) {
      color = active ? Colors.white : Colors.white38;
    } else {
      color = active ? AppTheme.current.navActive : AppTheme.current.navInactive;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        height: double.infinity,
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: SvgPicture.asset(
              active ? assetFilled : assetOutline,
              width: 24, height: 24),
          ),
        ),
      ),
    );
  }
}

// ─── _NavDrawer ───────────────────────────────────────────────────────────────
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
                      style: TextStyle(color: t.textTertiary, fontSize: 11)),
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
  const _DrawerItemSvg({required this.assetPath, required this.label, required this.onTap});

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
              colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
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

// ─── _HomeTab ─────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final VoidCallback onMenu;
  final Color appBarColor;
  final void Function(Color) onColorExtracted;

  const _HomeTab({
    required this.fadeIn,
    required this.onMenu,
    required this.appBarColor,
    required this.onColorExtracted,
  });

  @override
  Widget build(BuildContext context) {
    final safePadding = MediaQuery.of(context).padding;

    return Stack(fit: StackFit.expand, children: [
      // ── WebView fullscreen com shorties ──────────────────────────────────
      Positioned.fill(
        child: _ShortiesWebView(onColorExtracted: onColorExtracted),
      ),

      // ── Gradiente topo para AppBar legível ───────────────────────────────
      Positioned(
        top: 0, left: 0, right: 0,
        height: safePadding.top + 80,
        child: IgnorePointer(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent],
              ),
            ),
          ),
        ),
      ),

      // ── AppBar flutuante com cor extraída ────────────────────────────────
      Positioned(
        top: 0, left: 0, right: 0,
        child: FadeTransition(
          opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
          child: SafeArea(
            bottom: false,
            child: _HomeAppBar(
              onMenu: onMenu,
              accentColor: appBarColor,
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── _ShortiesWebView ─────────────────────────────────────────────────────────
class _ShortiesWebView extends StatefulWidget {
  final void Function(Color) onColorExtracted;
  const _ShortiesWebView({required this.onColorExtracted});

  @override
  State<_ShortiesWebView> createState() => _ShortiesWebViewState();
}

class _ShortiesWebViewState extends State<_ShortiesWebView> {
  InAppWebViewController? _ctrl;
  bool _colorExtracted = false;

  // CSS injectado para esconder elementos indesejados:
  // .actionScribe   → botão de seguir (+ laranja)
  // .headerLogo     → logo do PH no canto
  // .rightMenuSection, .flag.topMenuFlag → menu kebab e flag
  static const String _hideCSS = '''
    .actionScribe,
    .headerLogo,
    .rightMenuSection,
    .flag.topMenuFlag,
    .joinNowWrapper,
    .externalLinkButton,
    .menuContainer {
      display: none !important;
    }
  ''';

  // JS para extrair a cor dominante do thumbnail do vídeo atual
  static const String _extractColorJS = '''
  (function() {
    try {
      var video = document.querySelector('video.mgp_videoElement');
      if (!video) return '0,0,0';
      var c = document.createElement('canvas');
      c.width = 32; c.height = 32;
      var ctx = c.getContext('2d');
      ctx.drawImage(video, 0, 0, 32, 32);
      var d = ctx.getImageData(0, 0, 32, 32).data;
      var r=0,g=0,b=0,n=0;
      for(var i=0;i<d.length;i+=4){
        var avg=(d[i]+d[i+1]+d[i+2])/3;
        if(avg>20&&avg<235){r+=d[i];g+=d[i+1];b+=d[i+2];n++;}
      }
      if(n===0) return '0,0,0';
      return Math.round(r/n)+','+Math.round(g/n)+','+Math.round(b/n);
    } catch(e){ return '0,0,0'; }
  })();
  ''';

  void _injectCSS(InAppWebViewController ctrl) {
    ctrl.evaluateJavascript(source: '''
      (function() {
        var s = document.getElementById('_nuxxx_hide');
        if (s) return;
        s = document.createElement('style');
        s.id = '_nuxxx_hide';
        s.textContent = `$_hideCSS`;
        document.head.appendChild(s);
      })();
    ''');
  }

  Future<void> _extractColor() async {
    if (_ctrl == null) return;
    try {
      final result = await _ctrl!.evaluateJavascript(source: _extractColorJS);
      final raw = result?.toString() ?? '0,0,0';
      final parts = raw.replaceAll("'", '').split(',');
      if (parts.length == 3) {
        final r = int.tryParse(parts[0].trim()) ?? 0;
        final g = int.tryParse(parts[1].trim()) ?? 0;
        final b = int.tryParse(parts[2].trim()) ?? 0;
        if (r + g + b > 0) {
          widget.onColorExtracted(Color.fromARGB(255, r, g, b));
          _colorExtracted = true;
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.pornhub.com/shorties'),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        },
      ),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        transparentBackground: true,
        useHybridComposition: true,
        domStorageEnabled: true,
        databaseEnabled: true,
        supportZoom: false,
        disableHorizontalScroll: false,
        disableVerticalScroll: false,
      ),
      onWebViewCreated: (ctrl) {
        _ctrl = ctrl;

        // Handler para extração de cor via JS handler (fallback)
        ctrl.addJavaScriptHandler(
          handlerName: 'nuxxx_color',
          callback: (args) {
            if (_colorExtracted) return;
            try {
              final parts = (args[0] as String).split(',');
              widget.onColorExtracted(Color.fromARGB(
                255,
                int.parse(parts[0]),
                int.parse(parts[1]),
                int.parse(parts[2]),
              ));
              _colorExtracted = true;
            } catch (_) {}
          },
        );
      },
      onLoadStop: (ctrl, url) async {
        _injectCSS(ctrl);
        // Aguarda vídeo iniciar antes de extrair cor
        await Future.delayed(const Duration(milliseconds: 1500));
        _extractColor();
      },
      onScrollChanged: (ctrl, x, y) {
        // Reinjecta CSS ao fazer scroll (novo slide carregado)
        _injectCSS(ctrl);
        // Re-extrai cor do novo vídeo visível
        _colorExtracted = false;
        Future.delayed(const Duration(milliseconds: 600), _extractColor);
      },
      shouldOverrideUrlLoading: (ctrl, action) async {
        final url = action.request.url?.toString() ?? '';
        // Mantém dentro do shorties, bloqueia navegação externa
        if (url.contains('pornhub.com')) {
          return NavigationActionPolicy.ALLOW;
        }
        return NavigationActionPolicy.CANCEL;
      },
    );
  }
}

// ─── _HomeAppBar ──────────────────────────────────────────────────────────────
class _HomeAppBar extends StatelessWidget {
  final VoidCallback onMenu;
  final Color accentColor;
  const _HomeAppBar({required this.onMenu, required this.accentColor});

  // Luminosidade relativa para decidir cor do ícone sobre o accent
  bool get _isDark {
    final r = accentColor.red / 255;
    final g = accentColor.green / 255;
    final b = accentColor.blue / 255;
    final lum = 0.2126 * r + 0.7152 * g + 0.0722 * b;
    return lum < 0.5;
  }

  @override
  Widget build(BuildContext context) {
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
                  colorFilter: const ColorFilter.mode(
                      Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const Spacer(),
          // Indicador de cor extraída (opcional — remove se não quiseres)
          if (accentColor != Colors.transparent &&
              accentColor != Colors.black)
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withOpacity(0.6),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
                context, iosRoute(const CreatePostPage())),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 38, height: 44,
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/svg/plus.svg',
                  width: 22, height: 22,
                  colorFilter: const ColorFilter.mode(
                      Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}