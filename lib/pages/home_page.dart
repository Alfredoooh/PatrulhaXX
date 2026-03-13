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

const kPrimaryColor = Color(0xFFFF9000);

// ─── SVGs ────────────────────────────────────────────────────────────────────
// Shorts — ícone TikTok-style, vermelho quando ativo
const _svgShortsActive =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48px" height="48px" baseProfile="basic">'
    '<path fill="#ff3d00" d="M29.103,2.631c4.217-2.198,9.438-0.597,11.658,3.577c2.22,4.173,0.6,9.337-3.617,11.534'
    'l-3.468,1.823c2.987,0.109,5.836,1.75,7.328,4.555c2.22,4.173,0.604,9.337-3.617,11.534L18.897,45.37'
    'c-4.217,2.198-9.438,0.597-11.658-3.577s-0.6-9.337,3.617-11.534l3.468-1.823c-2.987-0.109-5.836-1.75-7.328-4.555'
    'c-2.22-4.173-0.6-9.337,3.617-11.534C10.612,12.346,29.103,2.631,29.103,2.631z'
    'M19.122,17.12l11.192,6.91l-11.192,6.877C19.122,30.907,19.122,17.12,19.122,17.12z"/>'
    '<path fill="#fff" d="M19.122,17.12v13.787l11.192-6.877L19.122,17.12z"/>'
    '</svg>';

// Outline neutro para estado inativo
const _svgShortsInactive =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48px" height="48px" baseProfile="basic">'
    '<path fill="currentColor" d="M29.103,2.631c4.217-2.198,9.438-0.597,11.658,3.577c2.22,4.173,0.6,9.337-3.617,11.534'
    'l-3.468,1.823c2.987,0.109,5.836,1.75,7.328,4.555c2.22,4.173,0.604,9.337-3.617,11.534L18.897,45.37'
    'c-4.217,2.198-9.438,0.597-11.658-3.577s-0.6-9.337,3.617-11.534l3.468-1.823c-2.987-0.109-5.836-1.75-7.328-4.555'
    'c-2.22-4.173-0.6-9.337,3.617-11.534C10.612,12.346,29.103,2.631,29.103,2.631z'
    'M19.122,17.12l11.192,6.91l-11.192,6.877C19.122,30.907,19.122,17.12,19.122,17.12z"/>'
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
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48px" height="48px">'
    '<linearGradient id="sg_a" x1="32.012" x2="15.881" y1="32.012" y2="15.881" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#fff"/><stop offset=".242" stop-color="#f2f2f2"/><stop offset="1" stop-color="#ccc"/>'
    '</linearGradient>'
    '<circle cx="24" cy="24" r="11.5" fill="url(#sg_a)"/>'
    '<linearGradient id="sg_b" x1="17.45" x2="28.94" y1="17.45" y2="28.94" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#0d61a9"/><stop offset=".363" stop-color="#0e5fa4"/>'
    '<stop offset=".78" stop-color="#135796"/><stop offset="1" stop-color="#16528c"/>'
    '</linearGradient>'
    '<circle cx="24" cy="24" r="7" fill="url(#sg_b)"/>'
    '<linearGradient id="sg_c" x1="5.326" x2="38.082" y1="5.344" y2="38.099" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#889097"/><stop offset=".331" stop-color="#848c94"/>'
    '<stop offset=".669" stop-color="#78828b"/><stop offset="1" stop-color="#64717c"/>'
    '</linearGradient>'
    '<path fill="url(#sg_c)" d="M43.407,19.243c-2.389-0.029-4.702-1.274-5.983-3.493'
    'c-1.233-2.136-1.208-4.649-0.162-6.693c-2.125-1.887-4.642-3.339-7.43-4.188C28.577,6.756,26.435,8,24,8'
    's-4.577-1.244-5.831-3.131c-2.788,0.849-5.305,2.301-7.43,4.188c1.046,2.044,1.071,4.557-0.162,6.693'
    'c-1.281,2.219-3.594,3.464-5.983,3.493C4.22,20.77,4,22.358,4,24c0,1.284,0.133,2.535,0.364,3.752'
    'c2.469-0.051,4.891,1.208,6.213,3.498c1.368,2.37,1.187,5.204-0.22,7.345c2.082,1.947,4.573,3.456,7.34,4.375'
    'C18.827,40.624,21.221,39,24,39s5.173,1.624,6.303,3.971c2.767-0.919,5.258-2.428,7.34-4.375'
    'c-1.407-2.141-1.588-4.975-0.22-7.345c1.322-2.29,3.743-3.549,6.213-3.498C43.867,26.535,44,25.284,44,24'
    'C44,22.358,43.78,20.77,43.407,19.243z M24,34.5c-5.799,0-10.5-4.701-10.5-10.5c0-5.799,4.701-10.5,10.5-10.5'
    'S34.5,18.201,34.5,24C34.5,29.799,29.799,34.5,24,34.5z"/>'
    '</svg>';

const svgExibicaoFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Layer_1" viewBox="0 0 24 24">'
    '<path d="M8,20c1.105,0,2,.895,2,2s-.895,2-2,2-2-.895-2-2,.895-2,2-2Zm2.36-13.463'
    'c-.188-.095-.4,.006-.412,.243v4.441c.023,.235,.196,.337,.412,.243l3.997-2.221'
    'c.2-.138,.2-.348,0-.485l-3.997-2.221Zm13.64-1.537V13c0,2.757-2.243,5-5,5H5'
    'c-2.757,0-5-2.243-5-5V5C0,2.243,2.243,0,5,0h14c2.757,0,5,2.243,5,5Zm-7.5,4'
    'c0-.826-.449-1.589-1.171-1.991l-3.997-2.221c-1.444-.867-3.44,.307-3.384,1.991v4.441'
    'c-.057,1.684,1.94,2.857,3.384,1.991l3.998-2.221c.722-.402,1.171-1.165,1.171-1.991Z'
    'm7.5,13c0-.553-.448-1-1-1H13c-.552,0-1,.447-1,1s.448,1,1,1h10c.552,0,1-.447,1-1Z'
    'm-20,0c0-.553-.448-1-1-1H1c-.552,0-1,.447-1,1s.448,1,1,1H3c.552,0,1-.447,1-1Z"/>'
    '</svg>';

const svgExibicaoOutline =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Layer_1" viewBox="0 0 24 24">'
    '<path d="M19,0H5C2.243,0,0,2.243,0,5V13c0,2.757,2.243,5,5,5h14c2.757,0,5-2.243,5-5V5'
    'c0-2.757-2.243-5-5-5Zm3,13c0,1.654-1.346,3-3,3H5c-1.654,0-3-1.346-3-3V5'
    'c0-1.654,1.346-3,3-3h14c1.654,0,3,1.346,3,3V13Zm-12,9c0,1.105-.895,2-2,2s-2-.895-2-2'
    ',.895-2,2-2,2,.895,2,2ZM15.329,7.009l-3.997-2.221c-1.444-.867-3.44,.307-3.384,1.991v4.441'
    'c-.057,1.684,1.94,2.857,3.384,1.991l3.998-2.221c1.539-.795,1.539-3.187,0-3.981Z'
    'm-.972,2.233l-3.997,2.221c-.115,.064-.213,.033-.275-.003-.062-.037-.137-.108-.137-.239'
    'V6.779c0-.131,.074-.203,.137-.239,.036-.021,.084-.041,.141-.041,.041,0,.086,.01,.135,.037'
    'l3.997,2.221c.119,.066,.144,.168,.144,.243s-.025,.177-.143,.243Z'
    'm9.643,12.757c0,.553-.448,1-1,1H13c-.552,0-1-.447-1-1s.448-1,1-1h10c.552,0,1,.447,1,1Z'
    'm-20,0c0,.553-.448,1-1,1H1c-.552,0-1-.447-1-1s.448-1,1-1H3c.552,0,1,.447,1,1Z"/>'
    '</svg>';

const _svgBrowseFilled =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m20.167 18.753c.524-.791.833-1.736.833-2.753 0-2.757-2.243-5-5-5s-5 2.243-5 5 2.243 5 5 5'
    'c1.017 0 1.962-.309 2.753-.833l3.54 3.54c.195.195.451.293.707.293s.512-.098.707-.293'
    'c.391-.391.391-1.023 0-1.414zm-12.667-6.753c0-1.04.187-2.046.48-3h13.556c.299.948.464 1.955.464 3'
    'c0 .552.447 1 1 1s1-.448 1-1c0-6.617-5.383-12-12-12-.016 0-.031.002-.047.002-.004 0-.008 0-.013 0'
    'c-6.589.034-11.94 5.402-11.94 11.998s5.383 12 12 12c.414 0 .786-.256.934-.643s.042-.825-.267-1.102'
    'c-.052-.046-5.167-4.691-5.167-10.255zm-1.605 3h-3.427c-.299-.948-.468-1.954-.468-3s.169-2.052.468-3h3.427'
    'c-.246.955-.395 1.959-.395 3s.15 2.045.395 3zm6.105-12.586c.814.864 2.207 2.506 3.229 4.586h-6.457'
    'c1.024-2.082 2.415-3.723 3.228-4.586zm8.645 4.586h-3.221c-.79-1.88-1.88-3.478-2.821-4.646'
    'c2.573.695 4.733 2.391 6.042 4.646zm-11.245-4.657c-.942 1.167-2.026 2.776-2.816 4.657h-3.234'
    'c1.31-2.258 3.473-3.963 6.05-4.657zm-6.05 14.657h3.234c.79 1.881 1.875 3.49 2.816 4.657'
    'c-2.577-.694-4.74-2.399-6.05-4.657z"/></svg>';

const _svgBrowseOutline =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m20.167 18.753c.524-.791.833-1.736.833-2.753 0-2.757-2.243-5-5-5s-5 2.243-5 5 2.243 5 5 5'
    'c1.017 0 1.962-.309 2.753-.833l3.54 3.54c.195.195.451.293.707.293s.512-.098.707-.293'
    'c.391-.391.391-1.023 0-1.414zm-7.167-2.753c0-1.654 1.346-3 3-3s3 1.346 3 3-1.346 3-3 3-3-1.346-3-3z'
    'm-.029 7.145c.084-.321-.092-.655-.304-.89-.052-.046-5.167-4.691-5.167-10.255 0-1.039.18-2.047.472-3h13.567'
    'c.299.948.461 1.955.461 3 0 .552.447 1 1 1s1-.448 1-1c0-6.596-5.35-11.964-11.939-11.997'
    'c-6.631-.038-12.065 5.359-12.061 11.997 0 6.617 5.383 12 12 12 .478.002.925-.38.971-.855z'
    'm-7.068-8.145h-3.442c-.299-.948-.461-1.955-.461-3s.163-2.052.461-3h3.442c-.246.956-.403 1.958-.403 3'
    's.157 2.044.403 3zm6.098-12.586c.814.864 2.207 2.506 3.229 4.586h-6.452c1.025-2.082 2.411-3.724 3.223-4.586z'
    'm8.646 4.586h-3.223c-.789-1.879-1.879-3.476-2.819-4.644 2.572.696 4.733 2.389 6.041 4.644z'
    'm-11.259-4.642c-.94 1.167-2.024 2.767-2.81 4.642h-3.225c1.308-2.253 3.466-3.945 6.035-4.642z'
    'm-6.035 14.642h3.225c.787 1.875 1.87 3.475 2.81 4.642-2.569-.697-4.728-2.39-6.035-4.642z"/></svg>';

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
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: false,
        backgroundColor: Colors.black,
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

          // ── Bottom Nav fixo ────────────────────────────────────────────
          _BottomNav(
            tab: _tab,
            onTab: (i) {
              setState(() {
                if (i == 2 && i != _tab) { _selectedEmbedUrl = null; _selectedVideo = null; }
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
// _BottomNav
// Feed: pill sempre activo com SVG vermelho sempre ligado
// Navegar + Exibição: sem pill, ícone + label em baixo
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int tab;
  final void Function(int) onTab;
  final double navH, safeBottom;
  static const _kBg = Color(0xFF111111);

  const _BottomNav({
    required this.tab, required this.onTab,
    required this.navH, required this.safeBottom,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kBg,
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
    final color = active ? Colors.white : Colors.white.withOpacity(0.38);
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
          color: active ? Colors.white.withOpacity(0.13) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? Colors.transparent : Colors.white.withOpacity(0.22),
            width: 1.2,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.string(_svgShortsActive, width: 22, height: 22),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            child: active
                ? const Row(children: [
                    SizedBox(width: 7),
                    Text('Feed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      )),
                  ])
                : const SizedBox.shrink(),
          ),
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
    return Stack(fit: StackFit.expand, children: [
      // Fundo
      Container(color: const Color(0xFF0C0C0C)),

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
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Search bar — abre SearchResultsPage com SharedAxisTransition
                    _SearchTrigger(
                      navColor: navColor,
                      navIsLight: navIsLight,
                    ),
                    const SizedBox(height: 10),
                    // ── Botões Downloads + Settings com cor adaptativa
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
    ]);
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
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
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
                    color: Colors.white.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 18),
                    Icon(Icons.search_rounded,
                        color: Colors.white.withOpacity(0.45), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
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
                              color: Colors.white.withOpacity(0.32), fontSize: 15),
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
                                  color: Colors.black, fontSize: 13,
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
enum VideoSource { eporner, pornhub, redtube, youporn }

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
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:  return 'E';
      case VideoSource.pornhub:  return 'P';
      case VideoSource.redtube:  return 'R';
      case VideoSource.youporn:  return 'Y';
    }
  }

  Color get sourceColor => const Color(0xFF222222);

  // ── Eporner ────────────────────────────────────────────────────────────────
  static FeedVideo? fromEporner(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    if (id.isEmpty) return null;
    final thumb = (j['thumbs'] as List?)?.isNotEmpty == true
        ? ((j['thumbs'] as List).first['src'] as String? ?? '') : '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: j['title'] as String? ?? '',
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
      title: j['title'] as String? ?? '',
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
      title: j['title'] as String? ?? '',
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
      title: j['title'] as String? ?? '',
      thumb: thumb,
      embedUrl: 'https://www.youporn.com/embed/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.youporn,
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
      final r = await http.get(
        Uri.parse('https://www.eporner.com/api/v2/video/search/'
            '?query=&per_page=20&page=$page&thumbsize=big&order=$order&format=json'),
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
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/search'
            '?search=&ordering=$order&page=$page&thumbsize=medium&format=json'),
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
      final r = await http.get(
        Uri.parse('https://api.redtube.com/'
            '?data=redtube.Videos.searchVideos&output=json'
            '&search=&ordering=$order&page=$page&thumbsize=big'),
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

  /// Busca todas as fontes em paralelo, mistura e baralha
  static Future<List<FeedVideo>> fetchAll(int page) async {
    final rng = Random();
    // Página aleatória por fonte para não repetir sempre o mesmo conteúdo
    final epPage  = rng.nextInt(60) + 1;
    final phPage  = rng.nextInt(40) + 1;
    final rtPage  = rng.nextInt(30) + 1;
    final ypPage  = rng.nextInt(20) + 1;

    final results = await Future.wait([
      fetchEporner(epPage),
      fetchPornhub(phPage),
      fetchRedtube(rtPage),
      fetchYouporn(ypPage),
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
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: kPrimaryColor, strokeWidth: 1.5),
        ),
      );
    }

    if (_error) {
      return Container(
        color: Colors.black,
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white24, size: 48),
          const SizedBox(height: 16),
          const Text('Sem ligação', style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: kPrimaryColor, borderRadius: BorderRadius.circular(100)),
              child: const Text('Tentar novamente',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ),
          ),
        ])),
      );
    }

    return Container(
      color: Colors.black,
      child: RefreshIndicator(
        color: kPrimaryColor,
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: _fetch,
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.only(top: topPad + 8, bottom: widget.navBottom + 16),
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
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1A1A),
                  child: const Center(child: Icon(Icons.play_circle_outline_rounded,
                      color: Colors.white24, size: 40)),
                ),
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
                        style: const TextStyle(color: Colors.white,
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
                        style: const TextStyle(color: Colors.white54, fontSize: 13,
                            fontWeight: FontWeight.w600))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13.5,
                        fontWeight: FontWeight.w500, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} views" : ""}',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11.5),
                  ),
                ],
              )),
              Icon(Icons.more_vert_rounded,
                  color: Colors.white.withOpacity(0.38), size: 20),
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
          border: Border.all(color: Colors.white.withOpacity(0.08), width: 0.5),
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
                    color: Colors.white.withOpacity(0.65),
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
