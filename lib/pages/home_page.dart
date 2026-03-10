import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_results_page.dart';
import '../services/theme_service.dart';

const kPrimaryColor = Color(0xFFFF9000);

// ─── SVG ícone de voltar ──────────────────────────────────────────────────────
const _svgBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

// ─── SVGs bottom nav ─────────────────────────────────────────────────────────
const _svgHomeFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m1.5,19c.828,0,1.5.672,1.5,1.5s-.672,1.5-1.5,1.5S0,21.328,0,20.5s.672-1.5,1.5-1.5Z'
    'M8,21c0-3.86-3.14-7-7-7-.552,0-1,.448-1,1s.448,1,1,1c2.757,0,5,2.243,5,5,0,.552.448,1,1,1s1-.448,1-1Z'
    'm5,0c0-6.617-5.362-12-11.953-12-.552,0-1,.448-1,1s.448,1,1,1c5.488,0,9.953,4.486,9.953,10,0,.552.448,1,1,1s1-.448,1-1Z'
    'm11-4V7c0-2.757-2.243-5-5.001-5l-14.129.018C2.598,2.018.609,3.551.033,5.746c-.079.3.01.619.199.865'
    '.189.246.505.389.815.389,7.685,0,13.936,6.28,13.936,14,0,.552.465,1,1.017,1h3c2.757,0,5-2.243,5-5Z"/>'
    '</svg>';

const _svgHomeOutline =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m24,7v10c0,2.757-2.243,5-5,5h-3c-.552,0-1-.448-1-1s.448-1,1-1h3c1.654,0,3-1.346,3-3V7'
    'c0-1.654-1.346-3-3-3H5c-1.363,0-2.557.919-2.902,2.236-.14.534-.684.855-1.221.713-.534-.14-.854-.687-.713-1.221'
    '.576-2.195,2.564-3.728,4.836-3.728h14c2.757,0,5,2.243,5,5Z'
    'M1.5,19c-.828,0-1.5.672-1.5,1.5s.672,1.5,1.5,1.5,1.5-.672,1.5-1.5-.672-1.5-1.5-1.5Z'
    'm-.5-5c-.552,0-1,.448-1,1s.448,1,1,1c2.757,0,5,2.243,5,5,0,.552.448,1,1,1s1-.448,1-1c0-3.86-3.14-7-7-7Z'
    'm.047-5c-.552,0-1,.448-1,1s.448,1,1,1c5.488,0,9.953,4.486,9.953,10,0,.552.448,1,1,1s1-.448,1-1'
    'c0-6.617-5.362-12-11.953-12Z"/>'
    '</svg>';

const _svgShortsFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m16.914,1h2.086c.621,0,1.215.114,1.764.322l-5.678,5.678h-4.172l6-6Z'
    'm7.086,6v-1c0-1.4-.579-2.668-1.51-3.576l-4.576,4.576h6.086Z'
    'M10.522,1l-6.084,6h3.648L14.086,1h-3.564Z'
    'M1.59,7L7.674,1h-2.674C2.243,1,0,3.243,0,6v1h1.59Z'
    'm22.41,2v9c0,2.757-2.243,5-5,5H5c-2.757,0-5-2.243-5-5v-9h24Z'
    'm-8.953,6.2l-4.634-2.48c-.622-.373-1.413.075-1.413.8v4.961'
    'c0,.725.791,1.173,1.413.8l4.634-2.48c.604-.362.604-1.238,0-1.6Z"/>'
    '</svg>';

const _svgShortsOutline =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m19,1H5C2.243,1,0,3.243,0,6v12c0,2.757,2.243,5,5,5h14c2.757,0,5-2.243,5-5V6'
    'c0-2.757-2.243-5-5-5Zm3,6h-3.894l3.066-3.066c.512.538.828,1.266.828,2.066v1Z'
    'm-2.734-3.988l-3.973,3.973s-.009.01-.014.015h-3.423l4-4h3.144c.09,0,.178.005.266.012Z'
    'm-6.238-.012l-3.764,3.764c-.071.071-.13.151-.175.236h-3.483l4-4h3.422Z'
    'm-8.028,0h1.778L2.778,7h-.778v-1c0-1.654,1.346-3,3-3Zm14,18H5c-1.654,0-3-1.346-3-3v-9h20v9'
    'c0,1.654-1.346,3-3,3Zm-3.953-5.2l-4.634,2.48c-.622.373-1.413-.075-1.413-.8v-4.961'
    'c0-.725.791-1.173,1.413-.8l4.634,2.48c.604.362.604,1.238,0,1.6Z"/>'
    '</svg>';

const _svgDownload =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M19,3h-6.528c-.154,0-.31-.036-.447-.105l-3.156-1.578c-.415-.207-.878-.316-1.341-.316h-2.528'
    'C2.243,1,0,3.243,0,6v12c0,2.757,2.243,5,5,5h1c.552,0,1-.447,1-1s-.448-1-1-1h-1c-1.654,0-3-1.346-3-3V9H22v9'
    'c0,1.654-1.346,3-3,3h-1c-.553,0-1,.447-1,1s.447,1,1,1h1c2.757,0,5-2.243,5-5V8c0-2.757-2.243-5-5-5Z'
    'M2,6c0-1.654,1.346-3,3-3h2.528c.154,0,.31,.036,.447,.105l3.156,1.578c.415,.207,.878,.316,1.341,.316h6.528'
    'c1.302,0,2.402,.839,2.816,2H2v-1Zm13.707,13.105c.391,.391,.391,1.023,0,1.414l-1.613,1.613'
    'c-.577,.577-1.335,.865-2.094,.865s-1.516-.288-2.093-.865l-1.614-1.613c-.391-.391-.391-1.023,0-1.414'
    's1.023-.391,1.414,0l1.293,1.293v-7.398c0-.553,.448-1,1-1s1,.447,1,1v7.398l1.293-1.293'
    'c.391-.391,1.023-.391,1.414,0Z"/></svg>';

const _svgSettings =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M1,4.75H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2Z'
    'M7.333,2a1.75,1.75,0,1,1-1.75,1.75A1.752,1.752,0,0,1,7.333,2Z"/>'
    '<path d="M23,11H20.264a3.727,3.727,0,0,0-7.194,0H1a1,1,0,0,0,0,2H13.07a3.727,3.727,0,0,0,7.194,0H23a1,1,0,0,0,0-2Z'
    'm-6.333,2.75A1.75,1.75,0,1,1,18.417,12,1.752,1.752,0,0,1,16.667,13.75Z"/>'
    '<path d="M23,19.25H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2Z'
    'M7.333,22a1.75,1.75,0,1,1,1.75-1.75A1.753,1.752,0,0,1,7.333,22Z"/></svg>';

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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _tab = 0;
  final _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;
  late final AnimationController _fadeIn;

  // Cor extraída do wallpaper via WebView HTML
  Color _wallpaperColor = Colors.black;
  static const _kNavH = 60.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    // Carrega a cor do wallpaper guardada no ThemeService
    final savedWp = ThemeService.instance.wallpaperColor;
    if (savedWp != null) _wallpaperColor = savedWp;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Quando o app volta ao foreground (resume), re-lança a animação
    // e força rebuild para evitar ecrã preto
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) {
        _fadeIn.forward();
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeIn.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => SearchResultsPage(query: q)));
  }

  void _openSite(SiteModel site) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => BrowserPage(site: site)));

  // Chamado pelo WallpaperColorExtractor quando deteta a cor dominante
  void _onColorExtracted(Color c) {
    if (mounted) {
      setState(() => _wallpaperColor = c);
      ThemeService.instance.setWallpaperColor(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final navTotal = _kNavH + safeBottom;

    // A cor da nav: no tab Shorts é sempre preto; no tab Home vem do wallpaper
    final navColor = _tab == 1 ? Colors.black : _wallpaperColor;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.black,
        body: Stack(children: [

          // ── Conteúdo (tabs) ───────────────────────────────────────────────
          IndexedStack(index: _tab, children: [
            _HomeTab(
              fadeIn: _fadeIn,
              searchCtrl: _searchCtrl,
              hasQuery: _hasQuery,
              navBottom: navTotal,
              onOpen: _openSite,
              onSearch: _onSearch,
              onSearchChanged: () => setState(() {}),
              onDownloads: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DownloadsPage())),
              onSettings: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage())),
              onColorExtracted: _onColorExtracted,
            ),
            _ShortsTab(navBottom: navTotal),
          ]),

          // ── Bottom Nav com gradiente adaptativo ───────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _AdaptiveNav(
              color: navColor,
              navH: _kNavH,
              tab: _tab,
              onTab: (i) => setState(() => _tab = i),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AdaptiveNav  —  bottom nav com gradiente transparente no topo
// A cor base adapta-se ao wallpaper (tab Início) ou fica preta (tab Shorts)
// ─────────────────────────────────────────────────────────────────────────────
class _AdaptiveNav extends StatelessWidget {
  final Color color;
  final double navH;
  final int tab;
  final void Function(int) onTab;

  const _AdaptiveNav({
    required this.color,
    required this.navH,
    required this.tab,
    required this.onTab,
  });

  // Determina se a cor base é clara ou escura, para ajustar o tom sólido em baixo
  bool get _isLight {
    final lum = color.computeLuminance();
    return lum > 0.35;
  }

  @override
  Widget build(BuildContext context) {
    // ── Tab Shorts: nav preta sólida, SEM BackdropFilter ──────────────────
    // BackdropFilter sobre WebView no Android faz blur em toda a tab
    if (tab == 1) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.black,
          border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: navH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavItem(
                  svgFilled: _svgHomeFilled,
                  svgOutline: _svgHomeOutline,
                  active: false,
                  onTap: () => onTab(0),
                ),
                _NavItem(
                  svgFilled: _svgShortsFilled,
                  svgOutline: _svgShortsOutline,
                  active: true,
                  onTap: () => onTab(1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── Tab Home: gradiente adaptativo SEM BackdropFilter ────────────────
    // IMPORTANTE: BackdropFilter + InAppWebView no Android causa blur em
    // toda a tela (bug flutter_inappwebview >= 6.0.0-beta.6). Solução:
    // nunca usar BackdropFilter quando há WebView na árvore (IndexedStack
    // mantém o tab Shorts montado em background mesmo quando invisível).
    final solidColor = _isLight
        ? Color.lerp(color, Colors.white, 0.15)!.withOpacity(0.96)
        : Color.lerp(color, Colors.black, 0.60)!.withOpacity(0.96);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            solidColor.withOpacity(0.0),
            solidColor.withOpacity(0.55),
            solidColor,
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navH,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                svgFilled: _svgHomeFilled,
                svgOutline: _svgHomeOutline,
                active: true,
                onTap: () => onTab(0),
                isLightBg: _isLight,
              ),
              _NavItem(
                svgFilled: _svgShortsFilled,
                svgOutline: _svgShortsOutline,
                active: false,
                onTap: () => onTab(1),
                isLightBg: _isLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final String svgFilled, svgOutline;
  final bool active, isLightBg;
  final VoidCallback onTap;

  const _NavItem({
    required this.svgFilled,
    required this.svgOutline,
    required this.active,
    required this.onTap,
    this.isLightBg = false,
  });

  @override
  Widget build(BuildContext context) {
    // Em fundo claro, o ícone inativo fica mais escuro para contrastar
    final inactiveColor = isLightBg
        ? Colors.black.withOpacity(0.45)
        : Colors.white.withOpacity(0.38);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80, height: 60,
        child: Center(
          child: SvgPicture.string(
            active ? svgFilled : svgOutline,
            width: 24, height: 24,
            colorFilter: ColorFilter.mode(
              active ? kPrimaryColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WallpaperColorExtractor
// Usa uma WebView invisível com HTML/Canvas para extrair a cor dominante
// do wallpaper sem depender de nenhum package Flutter de processamento de imagem
// ─────────────────────────────────────────────────────────────────────────────
class _WallpaperColorExtractor extends StatefulWidget {
  final String imageUrl;
  final void Function(Color) onColor;
  const _WallpaperColorExtractor({
    required this.imageUrl,
    required this.onColor,
  });
  @override
  State<_WallpaperColorExtractor> createState() =>
      _WallpaperColorExtractorState();
}

class _WallpaperColorExtractorState
    extends State<_WallpaperColorExtractor> {
  InAppWebViewController? _ctrl;
  bool _done = false;

  String get _html => '''
<!DOCTYPE html>
<html>
<head><meta charset="utf-8"></head>
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
    // Calcula a cor média (ignora pixels muito escuros)
    var r=0, g=0, b=0, n=0;
    for (var i = 0; i < data.length; i += 4) {
      var pr = data[i], pg = data[i+1], pb = data[i+2];
      var brightness = (pr + pg + pb) / 3;
      if (brightness > 20) { r+=pr; g+=pg; b+=pb; n++; }
    }
    if (n === 0) { window.flutter_inappwebview.callHandler("color", "0,0,0"); return; }
    r = Math.round(r/n); g = Math.round(g/n); b = Math.round(b/n);
    window.flutter_inappwebview.callHandler("color", r+","+g+","+b);
  };
  img.onerror = function() {
    window.flutter_inappwebview.callHandler("color", "0,0,0");
  };
  img.src = "${widget.imageUrl}";
})();
</script>
</body>
</html>
''';

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: 1, height: 1,
      child: InAppWebView(
        initialData: InAppWebViewInitialData(data: _html, mimeType: 'text/html'),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          transparentBackground: true,
        ),
        onWebViewCreated: (ctrl) {
          _ctrl = ctrl;
          ctrl.addJavaScriptHandler(
            handlerName: 'color',
            callback: (args) {
              if (_done) return;
              _done = true;
              try {
                final parts = (args[0] as String).split(',');
                final r = int.parse(parts[0]);
                final g = int.parse(parts[1]);
                final b = int.parse(parts[2]);
                widget.onColor(Color.fromARGB(255, r, g, b));
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
// _HomeTab  —  tab de início: sem feed, espaço vazio abaixo dos sites
// SearchBar em cima, botões Downloads/Settings abaixo na mesma linha
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final TextEditingController searchCtrl;
  final bool hasQuery;
  final double navBottom;
  final void Function(SiteModel) onOpen;
  final VoidCallback onSearch, onSearchChanged, onDownloads, onSettings;
  final void Function(Color) onColorExtracted;

  // URL do wallpaper vem do ThemeService (definido nas Settings)

  const _HomeTab({
    required this.fadeIn,
    required this.searchCtrl,
    required this.hasQuery,
    required this.navBottom,
    required this.onOpen,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onDownloads,
    required this.onSettings,
    required this.onColorExtracted,
  });

  // Raio idêntico ao search bar (pill)
  static const _kRadius = 14.0;
  static const _kBtnHeight = 46.0;

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // ── Fundo ─────────────────────────────────────────────────────────────
      Container(color: const Color(0xFF0C0C0C)),

      // ── WebView invisível para extrair cor do wallpaper ───────────────────
      Builder(builder: (ctx) {
        final wpUrl = ThemeService.instance.bg;
        if (wpUrl.isEmpty) return const SizedBox.shrink();
        return Positioned(
          left: -1, top: -1, width: 1, height: 1,
          child: _WallpaperColorExtractor(
            imageUrl: wpUrl,
            onColor: onColorExtracted,
          ),
        );
      }),

      // ── Conteúdo ──────────────────────────────────────────────────────────
      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Search bar ───────────────────────────────────────────
                    _SearchBar(
                      ctrl: searchCtrl,
                      hasQuery: hasQuery,
                      onSearch: onSearch,
                      onChanged: onSearchChanged,
                      radius: _kRadius,
                    ),

                    const SizedBox(height: 10),

                    // ── Botões Downloads + Settings  (mesma linha, mesmo estilo) ─
                    _ActionRow(
                      onDownloads: onDownloads,
                      onSettings: onSettings,
                      height: _kBtnHeight,
                      radius: _kRadius,
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ),

          // ── Sites grid ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _SitesGrid(sites: kSites, onTap: onOpen),
          ),

          // ── Espaço vazio (sem feed) ───────────────────────────────────────
          SliverToBoxAdapter(child: SizedBox(height: navBottom + 16)),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchBar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController ctrl;
  final bool hasQuery;
  final VoidCallback onSearch;
  final VoidCallback onChanged;
  final double radius;

  const _SearchBar({
    required this.ctrl,
    required this.hasQuery,
    required this.onSearch,
    required this.onChanged,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(children: [
        const SizedBox(width: 14),
        Icon(Icons.search_rounded,
            color: Colors.white.withOpacity(0.45), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: ctrl,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            textInputAction: TextInputAction.search,
            onChanged: (_) => onChanged(),
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              hintText: 'Pesquisar vídeos, sites...',
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.32), fontSize: 15),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
        if (hasQuery)
          GestureDetector(
            onTap: onSearch,
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: kPrimaryColor,
                borderRadius: BorderRadius.circular(radius - 2),
              ),
              child: const Text('Ir',
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
            ),
          )
        else
          const SizedBox(width: 8),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionRow  —  Downloads + Settings na mesma linha, estilo idêntico ao search bar
// ─────────────────────────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final VoidCallback onDownloads, onSettings;
  final double height, radius;

  const _ActionRow({
    required this.onDownloads,
    required this.onSettings,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _ActionBtn(
          svg: _svgDownload,
          label: 'Downloads',
          onTap: onDownloads,
          height: height,
          radius: radius,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ActionBtn(
          svg: _svgSettings,
          label: 'Definições',
          onTap: onSettings,
          height: height,
          radius: radius,
        ),
      ),
    ]);
  }
}

class _ActionBtn extends StatelessWidget {
  final String svg, label;
  final VoidCallback onTap;
  final double height, radius;

  const _ActionBtn({
    required this.svg,
    required this.label,
    required this.onTap,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          SvgPicture.string(svg, width: 17, height: 17,
              colorFilter: ColorFilter.mode(
                  Colors.white.withOpacity(0.75), BlendMode.srcIn)),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShortsTab
// ─────────────────────────────────────────────────────────────────────────────
class _ShortsTab extends StatefulWidget {
  final double navBottom;
  const _ShortsTab({required this.navBottom});
  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}

class _ShortsTabState extends State<_ShortsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _cookiesSet = false;

  Future<void> _setCookies() async {
    if (_cookiesSet) return;
    _cookiesSet = true;
    final mgr = CookieManager.instance();
    final uri = WebUri('https://www.pornhub.com');
    final exp = DateTime.now().add(const Duration(days: 365));
    for (final e in {
      'age_verified': '1',
      'accessAgeDisclaimerPH': '1',
      'accessPH': '1',
      'hasVisited': '1',
      'platform': 'pc',
      '_tc': '1',
      'cookieConsent': '1',
    }.entries) {
      await mgr.setCookie(
          url: uri,
          name: e.key,
          value: e.value,
          domain: '.pornhub.com',
          path: '/',
          expiresDate: exp.millisecondsSinceEpoch,
          isSecure: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.of(context).padding.top;
    return FutureBuilder(
      future: _setCookies(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
              child: CircularProgressIndicator(
                  color: kPrimaryColor, strokeWidth: 1.5));
        }
        return Padding(
          padding: EdgeInsets.only(top: topPad, bottom: widget.navBottom),
          child: InAppWebView(
            initialUrlRequest: URLRequest(
              url: WebUri('https://www.pornhub.com/shorties'),
              headers: {
                'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8',
                'Cookie':
                    'age_verified=1; accessAgeDisclaimerPH=1; accessPH=1; hasVisited=1; platform=pc; _tc=1',
              },
            ),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              domStorageEnabled: true,
              databaseEnabled: true,
              mediaPlaybackRequiresUserGesture: false,
              allowsInlineMediaPlayback: true,
              useShouldOverrideUrlLoading: true,
              supportZoom: false,
              transparentBackground: false,
              cacheEnabled: true,
              clearCache: false,
              userAgent:
                  'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
                  '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
            ),
            onLoadStart: (ctrl, _) async =>
                ctrl.evaluateJavascript(source: _shortsJsCookies),
            onLoadStop: (ctrl, url) async {
              final u = url?.toString() ?? '';
              if (!u.contains('shorties')) {
                await Future.delayed(const Duration(milliseconds: 400));
                await ctrl.loadUrl(
                    urlRequest: URLRequest(
                  url: WebUri('https://www.pornhub.com/shorties'),
                  headers: {
                    'Cookie':
                        'age_verified=1; accessAgeDisclaimerPH=1; accessPH=1; hasVisited=1; platform=pc; _tc=1',
                  },
                ));
                return;
              }
              await ctrl.evaluateJavascript(source: _shortsJs);
            },
            shouldOverrideUrlLoading: (_, action) async {
              final url =
                  action.request.url?.toString().toLowerCase() ?? '';
              if (url.startsWith('about:') ||
                  url.startsWith('blob:') ||
                  url.startsWith('data:') ||
                  url.contains('pornhub.com') ||
                  url.contains('phncdn.com') ||
                  url.contains('aylo.com')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.CANCEL;
            },
            onPermissionRequest: (_, req) async => PermissionResponse(
                resources: req.resources,
                action: PermissionResponseAction.GRANT),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SitesGrid  —  grelha de sites com glassmorphism
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
          border: Border.all(
              color: Colors.white.withOpacity(0.08), width: 0.5),
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
        children:
            sites.map((s) => _SiteCell(site: s, onTap: () => onTap(s))).toList(),
      );
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
        builder: (_, child) =>
            Transform.scale(scale: _s.value, child: child),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SiteIconWidget(
              site: widget.site, size: iconSize, showShadow: true),
          const SizedBox(height: 5),
          SizedBox(
            width: iconSize + 10,
            child: Text(widget.site.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.65),
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FreeBrowserPage  —  helper para abrir qualquer URL no BrowserPage
// ─────────────────────────────────────────────────────────────────────────────
class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(
          id: 'free',
          name: title,
          baseUrl: url,
          allowedDomain: '',
          searchUrl: url,
          primaryColor: kPrimaryColor),
      freeNavigation: true,
    );
  }
}
