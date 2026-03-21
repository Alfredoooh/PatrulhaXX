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

// ─── SVGs ────────────────────────────────────────────────────────────────────
const _svgShortsActive =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48px" height="48px" baseProfile="basic">'
    '<path fill="#ff3d00" d="M29.103,2.631c4.217-2.198,9.438-0.597,11.658,3.577c2.22,4.173,0.6,9.337-3.617,11.534'
    'l-3.468,1.823c2.987,0.109,5.836,1.75,7.328,4.555c2.22,4.173,0.604,9.337-3.617,11.534L18.897,45.37'
    'c-4.217,2.198-9.438,0.597-11.658-3.577s-0.6-9.337,3.617-11.534l3.468-1.823c-2.987-0.109-5.836-1.75-7.328-4.555'
    'c-2.22-4.173-0.6-9.337,3.617-11.534C10.612,12.346,29.103,2.631,29.103,2.631z'
    'M19.122,17.12l11.192,6.91l-11.192,6.877C19.122,30.907,19.122,17.12,19.122,17.12z"/>'
    '<path fill="#fff" d="M19.122,17.12v13.787l11.192-6.877L19.122,17.12z"/>'
    '</svg>';

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


const svgExibicaoFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Layer_1" viewBox="0 0 24 24">'
    '<path d="M8,20c1.105,0,2,.895,2,2s-.895,2-2,2-2-.895-2-2,.895-2,2-2Zm2.36-13.463'
    'c-.188-.095-.4,.006-.412,.243v4.441c.023,.235,.196,.337,.412,.243l3.997-2.221'
    'c.2-.138,.2-.348,0-.485l-3.997-2.221Zm13.64-1.537V13c0,2.757-2.243,5-5,5H5'
    'c-2.757,0-5-2.243-5-5V5C0,2.243,2.243,0,5,0h14c2.757,0,5,2.243,5,5Zm-7.5,4'
    'c0-.826-.449-1.589-1.171-1.991l-3.997-2.221c-1.444-.867-3.44,.307-3.384,1.991v4.441'
    'c-.057,1.684,1.94,2.857,3.384,1.991l3.998-2.221c.722-.402,1.171-1.165,1.171-1.991Z'
    'm7.5,13c0-.553-.448-1-1-1H13c-.552,0-1,.447-1,1s.448,1,1,1h10c.552,0,1-.447,1-1Z'
    'm-20,0c0-.553-.448-1-1-1H1c-.552,0-1,.447-1,1s.448,1,1,1H3c.552,0,1,.447,1,1Z"/>'
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

// Ícone Início filled — enviado pelo utilizador (casa sólida com janelas)
const _svgBrowseFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21.743,7.4l-7-6.533a4.027,4.027,0,0,0-5.487,0L2.257,7.4A4.013,4.013,0,0,0,1,10.268V21a2,2,0,0,0,2,2H9.5a1,1,0,0,0,1-1V16.5a1.5,1.5,0,0,1,3,0V22a1,1,0,0,0,1,1H21a2,2,0,0,0,2-2V10.268A4.013,4.013,0,0,0,21.743,7.4Z"/>'
    '</svg>';

// Ícone Início outline — enviado pelo utilizador (casa com contorno e interior vazio)
const _svgBrowseOutline =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M21.743,7.4l-7-6.533a4.027,4.027,0,0,0-5.487,0L2.257,7.4A4.013,4.013,0,0,0,1,10.268V21a2,2,0,0,0,2,2H9.5a1,1,0,0,0,1-1V16.5a1.5,1.5,0,0,1,3,0V22a1,1,0,0,0,1,1H21a2,2,0,0,0,2-2V10.268A4.013,4.013,0,0,0,21.743,7.4ZM21,21H15.5V16.5a3.5,3.5,0,0,0-7,0V21H3V10.268a2.013,2.013,0,0,1,.629-1.46l7-6.533a2.027,2.027,0,0,1,2.742,0l7,6.533A2.013,2.013,0,0,1,21,10.268Z"/>'
    '</svg>';

// Ícone hambúrguer (três linhas) — nunca vira X
const _svgHamburger =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M1,4h22a1,1,0,0,0,0-2H1A1,1,0,0,0,1,4Z"/>'
    '<path d="M23,11H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,20H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '</svg>';

// SVGs do drawer
const _svgDrawerDownload =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M19,3h-6.528c-.154,0-.31-.036-.447-.105l-3.156-1.578c-.415-.207-.878-.316-1.341-.316h-2.528'
    'C2.243,1,0,3.243,0,6v12c0,2.757,2.243,5,5,5h1c.552,0,1-.447,1-1s-.448-1-1-1h-1c-1.654,0-3-1.346-3-3V9H22v9'
    'c0,1.654-1.346,3-3,3h-1c-.553,0-1,.447-1,1s.447,1,1,1h1c2.757,0,5-2.243,5-5V8c0-2.757-2.243-5-5-5Z'
    'M2,6c0-1.654,1.346-3,3-3h2.528c.154,0,.31,.036,.447,.105l3.156,1.578c.415,.207,.878,.316,1.341,.316h6.528'
    'c1.302,0,2.402,.839,2.816,2H2v-1Zm13.707,13.105c.391,.391,.391,1.023,0,1.414l-1.613,1.613'
    'c-.577,.577-1.335,.865-2.094,.865s-1.516-.288-2.093-.865l-1.614-1.613c-.391-.391-.391-1.023,0-1.414'
    's1.023-.391,1.414,0l1.293,1.293v-7.398c0-.553,.448-1,1-1s1,.447,1,1v7.398l1.293-1.293'
    'c.391-.391,1.023-.391,1.414,0Z"/></svg>';

const _svgDrawerSettings =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M12,8a4,4,0,1,0,4,4A4,4,0,0,0,12,8Zm0,6a2,2,0,1,1,2-2A2,2,0,0,1,12,14Z"/>'
    '<path d="M21.294,13.9l-.444-.256a9.1,9.1,0,0,0,0-3.29l.444-.256a3,3,0,1,0-3-5.2l-.445.257A8.977,8.977,0,0,0,15,3.513V3a3,3,0,0,0-6,0v.513A8.977,8.977,0,0,0,6.152,5.159L5.705,4.9a3,3,0,0,0-3,5.2l.444.256a9.1,9.1,0,0,0,0,3.29L2.7,13.9a3,3,0,0,0,3,5.2l.445-.257A8.977,8.977,0,0,0,9,20.487V21a3,3,0,0,0,6,0v-.513a8.977,8.977,0,0,0,2.848-1.646L18.294,19.1a3,3,0,0,0,3-5.2Z"/>'
    '</svg>';

// SVG settings gradiente Android (para o corpo do Início)
const _svgSettingsGradient =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48" width="48px" height="48px">'
    '<defs>'
    '<linearGradient id="sg_a" x1="32.012" x2="15.881" y1="32.012" y2="15.881" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#fff"/><stop offset=".242" stop-color="#f2f2f2"/><stop offset="1" stop-color="#ccc"/>'
    '</linearGradient>'
    '<linearGradient id="sg_b" x1="17.45" x2="28.94" y1="17.45" y2="28.94" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#0d61a9"/><stop offset=".363" stop-color="#0e5fa4"/>'
    '<stop offset=".78" stop-color="#135796"/><stop offset="1" stop-color="#16528c"/>'
    '</linearGradient>'
    '<linearGradient id="sg_c" x1="5.326" x2="38.082" y1="5.344" y2="38.099" gradientUnits="userSpaceOnUse">'
    '<stop offset="0" stop-color="#889097"/><stop offset=".331" stop-color="#848c94"/>'
    '<stop offset=".669" stop-color="#78828b"/><stop offset="1" stop-color="#64717c"/>'
    '</linearGradient>'
    '</defs>'
    '<circle cx="24" cy="24" r="11.5" fill="url(#sg_a)"/>'
    '<circle cx="24" cy="24" r="7" fill="url(#sg_b)"/>'
    '<path fill="url(#sg_c)" d="M43.407,19.243c-2.389-0.029-4.702-1.274-5.983-3.493'
    'c-1.233-2.136-1.208-4.649-0.162-6.693c-2.125-1.887-4.642-3.339-7.43-4.188'
    'C28.577,6.756,26.435,8,24,8s-4.577-1.244-5.831-3.131c-2.788,0.849-5.305,2.301-7.43,4.188'
    'c1.046,2.044,1.071,4.557-0.162,6.693c-1.281,2.219-3.594,3.464-5.983,3.493'
    'C4.22,20.77,4,22.358,4,24c0,1.284,0.133,2.535,0.364,3.752c2.469-0.051,4.891,1.208,6.213,3.498'
    'c1.368,2.37,1.187,5.204-0.22,7.345c2.082,1.947,4.573,3.456,7.34,4.375'
    'C18.827,40.624,21.221,39,24,39s5.173,1.624,6.303,3.971c2.767-0.919,5.258-2.428,7.34-4.375'
    'c-1.407-2.141-1.588-4.975-0.22-7.345c1.322-2.29,3.743-3.549,6.213-3.498'
    'C43.867,26.535,44,25.284,44,24C44,22.358,43.78,20.77,43.407,19.243z'
    'M24,34.5c-5.799,0-10.5-4.701-10.5-10.5c0-5.799,4.701-10.5,10.5-10.5'
    'S34.5,18.201,34.5,24C34.5,29.799,29.799,34.5,24,34.5z"/>'
    '</svg>';

// SVG lupa personalizado para a pesquisa
const _svgSearch =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M23.707,22.293l-5.969-5.969a10.016,10.016,0,1,0-1.414,1.414l5.969,5.969a1,1,0,0,0,1.414-1.414ZM10,18a8,8,0,1,1,8-8A8.009,8.009,0,0,1,10,18Z"/>'
    '</svg>';


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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 1;
  String? _selectedEmbedUrl;
  FeedVideo? _selectedVideo;
  bool _miniPlayerActive = false;
  late final AnimationController _fadeIn;

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
    // Não chama setState ao resumir — evita reiniciar as telas quando o app
    // está bloqueado e o utilizador desbloqueia
    if (state == AppLifecycleState.resumed && mounted) {
      if (!_fadeIn.isAnimating && _fadeIn.value < 1.0) {
        _fadeIn.forward();
      }
      // Não chama setState() — o IndexedStack mantém o estado de cada tab
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

  void _openDownloads() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const DownloadsPage()));

  void _openSettings() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => const SettingsPage()));

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
        // Drawer no Scaffold raiz — o Flutter garante que não cobre o bottomNavigationBar
        drawer: _NavDrawer(
          onDownloads: () { _scaffoldKey.currentState?.closeDrawer(); _openDownloads(); },
          onSettings:  () { _scaffoldKey.currentState?.closeDrawer(); _openSettings(); },
        ),
        body: Column(children: [
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
            onTab: (i) {
              setState(() {
                // Ao sair da Exibição para outro tab — activa mini player se há vídeo
                if (i != 2 && _tab == 2 && _selectedVideo != null) {
                  _miniPlayerActive = true;
                } else if (i == 2) {
                  // Ao entrar na Exibição — desactiva mini player mas NÃO apaga o vídeo
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
// _BottomNav — reactivo ao tema via ListenableBuilder
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
    // ListenableBuilder garante rebuild imediato quando o tema muda,
    // sem depender do setState do pai
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        return Container(
          decoration: BoxDecoration(
            color: t.navBg,
            border: Border(top: BorderSide(color: t.navBorder, width: 0.5)),
          ),
          padding: EdgeInsets.only(bottom: safeBottom),
          height: navH + safeBottom,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavIcon(
                label: 'Início',
                svgFilled: _svgBrowseFilled,
                svgOutline: _svgBrowseOutline,
                active: tab == 0,
                onTap: () => onTab(0),
              ),
              _NavFeedPill(
                active: tab == 1,
                onTap: () => onTab(1),
              ),
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
      },
    );
  }
}

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
    final color = active ? AppTheme.current.navActive : AppTheme.current.navInactive;
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

// ─── Feed pill — pill redondo original ───────────────────────────────────────
class _NavFeedPill extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  const _NavFeedPill({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final activeBg = t.isDark
        ? Colors.white.withOpacity(0.13)
        : Colors.black.withOpacity(0.10);
    final inactiveBg = t.isDark
        ? Colors.transparent
        : t.bgTertiary;
    final borderColor = t.isDark
        ? t.navBorder.withOpacity(active ? 0.0 : 1.0)
        : t.border.withOpacity(active ? 0.0 : 1.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: active ? activeBg : inactiveBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          SvgPicture.string(_svgShortsActive, width: 22, height: 22),
          const SizedBox(width: 7),
          Text('Feed',
            style: TextStyle(
              color: t.text.withOpacity(active ? 1.0 : 0.70),
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
            child: SvgPicture.string(
              _svgHamburger, width: 22, height: 22,
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
// _NavDrawer — no Scaffold raiz, o Flutter garante que não cobre o bottom bar
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

          // Header logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              SvgPicture.string(_svgShortsActive, width: 28, height: 28),
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
            svgData: _svgDrawerDownload,
            label: 'Downloads',
            onTap: () { Navigator.pop(context); onDownloads(); },
          ),
          _DrawerItemSvg(
            svgData: _svgDrawerSettings,
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

// ─── DrawerItem com SVG inline ────────────────────────────────────────────────
class _DrawerItemSvg extends StatelessWidget {
  final String svgData;
  final String label;
  final VoidCallback onTap;
  const _DrawerItemSvg({
    required this.svgData, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return InkWell(
      onTap: onTap,
      // Sem borderRadius nos itens — bordes retas como YouTube
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(children: [
          SvgPicture.string(
            svgData,
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
// _HomeTab — sem Scaffold com drawer próprio; drawer está no Scaffold raiz
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ts = ThemeService.instance;
    // Sem Scaffold aninhado — usa o Scaffold raiz que tem o drawer e o bottomNavigationBar
    return Stack(fit: StackFit.expand, children: [
      Container(color: AppTheme.current.bg),

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
            imageUrl: ts.bg, onColor: onColorExtracted),
        ),

      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: Column(children: [

          // ── AppBar FIXO — não desliza ─────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _NavAppBar(onMenu: onMenu),
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

          // ── Conteúdo scrollável ───────────────────────────────────────────
          Expanded(
            child: CustomScrollView(slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: _SitesGrid(sites: kSites, onTap: onOpen),
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: navBottom + 16)),
            ]),
          ),
        ]),
      ),
    ]);
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// _SearchTrigger
// ─────────────────────────────────────────────────────────────────────────────
class _SearchTrigger extends StatelessWidget {
  final Color navColor;
  final bool navIsLight;
  const _SearchTrigger({required this.navColor, required this.navIsLight});

  // Cores correctas para tema claro e escuro
  Color get _bgColor {
    final t = AppTheme.current;
    return t.inputBg;
  }
  Color get _borderColor {
    final t = AppTheme.current;
    return t.inputBorder;
  }
  Color get _hintColor {
    final t = AppTheme.current;
    return t.inputHint;
  }

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
            SvgPicture.string(_svgSearch, width: 18, height: 18,
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

  // Sugestões sempre visíveis
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
              // Back arrow — mesmo tamanho que o input
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: t.btnGhost,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: SvgPicture.string(
                      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
                      '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
                      'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
                      '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>',
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
                    // Ícone lupa personalizado
                    SvgPicture.string(_svgSearch, width: 18, height: 18,
                        colorFilter: ColorFilter.mode(t.textSecondary, BlendMode.srcIn)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(color: t.inputText, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.ytRed,
                        cursorWidth: 1.5,
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          hintText: 'Pesquisar...',
                          hintStyle: TextStyle(color: t.inputHint, fontSize: 15),
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
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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

          // Sugestões sempre visíveis
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
// _ActionRow — botões Downloads + Definições, visíveis em claro e escuro
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
    // Usa cores do AppTheme em vez de opacidades fixas — funciona em claro e escuro
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
        svg: _svgSettingsGradient, label: 'Definições', onTap: onSettings,
        bgColor: bgColor, borderColor: borderColor, contentColor: contentColor,
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
      iconWidget = Image.asset('assets/icons/downloads_folder.png', width: 38, height: 38);
    } else if (isSettings) {
      // Renderiza com gradiente original — sem colorFilter
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
                  color: contentColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
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

  // BravoTube, DrTuber, TXXX, GotPorn, PornDig — via RSS, já trazem embedUrl calculado
  static FeedVideo fromRss({
    required String title,
    required String thumb,
    required String embedUrl,
    required VideoSource source,
    String duration = '',
    String views = '',
  }) {
    return FeedVideo(
      title: cleanTitle(title.isEmpty ? 'Vídeo' : title),
      thumb: thumb,
      embedUrl: embedUrl,
      duration: duration,
      views: views,
      source: source,
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
// FeedFetcher
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

  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
  ];

  // ── RSS helper ───────────────────────────────────────────────────────────────
  static String _xml(dynamic el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); } catch (_) { return ''; }
  }

  static String _firstOf(List<String?> values) {
    for (final v in values) { if (v != null && v.isNotEmpty) return v; }
    return '';
  }

  // ── BravoTube RSS ────────────────────────────────────────────────────────────
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
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
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

  // ── DrTuber RSS ──────────────────────────────────────────────────────────────
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
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
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

  // ── TXXX RSS ─────────────────────────────────────────────────────────────────
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
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
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

  // ── GotPorn RSS ──────────────────────────────────────────────────────────────
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
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
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

  // ── PornDig RSS ──────────────────────────────────────────────────────────────
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
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
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
// _ShortsTab — Feed multi-fonte estilo YouTube
// ─────────────────────────────────────────────────────────────────────────────
class _ShortsTab extends StatefulWidget {
  final double navBottom;
  final void Function(FeedVideo) onVideoTap;
  const _ShortsTab({required this.navBottom, required this.onVideoTap});

  @override
  State<_ShortsTab> createState() => _ShortsTabState();
}

// Mapeamento chip → termo de pesquisa
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
  bool _loading = true;
  bool _error = false;
  int _page = 1;
  bool _fetching = false;
  int _selectedChip = 0;
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

  // Vídeos filtrados pelo chip activo
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
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: t.bg,
      child: Column(children: [
        // AppBar FORA de qualquer condicional
        _FeedAppBar(
          topPad: topPad,
          selectedChip: _selectedChip,
          onChipChanged: _onChipChanged,
          onSearchTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const _SearchPage())),
        ),

        Expanded(
          child: RefreshIndicator(
            color: AppTheme.ytRed,
            backgroundColor: t.surface,
            onRefresh: _fetch,
            child: _loading
                // Skeletons dentro do ListView — AppBar não é tocado
                ? ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    children: List.generate(5, (_) => _FeedCardSkeleton()),
                  )
                : _error
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.55,
                            child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.wifi_off_rounded, color: t.iconSub, size: 48),
                              const SizedBox(height: 16),
                              Text('Sem ligação à internet',
                                  style: TextStyle(color: t.textSecondary, fontSize: 14)),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onTap: _fetch,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: AppTheme.ytRed,
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child: const Text('Tentar novamente',
                                      style: TextStyle(
                                          color: Colors.white, fontWeight: FontWeight.w700)),
                                ),
                              ),
                            ])),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scroll,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 24),
                        itemCount: _filtered.length + 1,
                        itemBuilder: (_, i) {
                          final list = _filtered;
                          if (i == list.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: AppTheme.ytRed))),
                            );
                          }
                          return _VideoCard(
                              video: list[i],
                              onTap: () => widget.onVideoTap(list[i]));
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


// ─── AppBar do Feed — chips funcionais, botão pesquisa, estilo YouTube ────────
class _FeedAppBar extends StatelessWidget {
  final double topPad;
  final int selectedChip;
  final void Function(int) onChipChanged;
  final VoidCallback onSearchTap;

  static const _chips = [
    'Todos', 'Mais vistos', 'Recentes', 'Avaliação',
    'Amador', 'MILF', 'Asiática', 'Latina', 'Loira',
  ];

  const _FeedAppBar({
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      color: t.bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad),

        // Título + botão de pesquisa
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 8),
          child: Row(children: [
            SvgPicture.string(_svgShortsActive, width: 26, height: 26),
            const SizedBox(width: 8),
            Text('Feed',
              style: TextStyle(
                color: t.text, fontSize: 20,
                fontWeight: FontWeight.w700, letterSpacing: -0.5,
              )),
            const Spacer(),
            // Botão pesquisar
            GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: SvgPicture.string(_svgSearch, width: 20, height: 20,
                    colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
              ),
            ),
          ]),
        ),

        // Chips — altura 30, bordas mais curvas (radius 8)
        SizedBox(
          height: 30,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 14, right: 14),
            itemCount: _chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final selected = selectedChip == i;
              return GestureDetector(
                onTap: () => onChipChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? t.chipBgActive : t.chipBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(_chips[i],
                    style: TextStyle(
                      color: selected ? t.chipTextActive : t.chipText,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    )),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),
        Divider(color: t.divider, height: 1, thickness: 1),
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

  // Headers completos — evita 403 em sites que verificam Referer/Accept
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
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Thumbnail ──────────────────────────────────────────────────────
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              _ThumbImage(
                url: video.thumb,
                headers: _headers(video.source),
                placeholder: t.thumbBg,
              ),
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 6, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              Center(child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.45),
                    shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 28),
              )),
            ]),
          ),

          // ── Info ────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FaviconAvatar(source: video.source),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(video.title,
                    style: TextStyle(color: t.text, fontSize: 13.5,
                        fontWeight: FontWeight.w500, height: 1.3),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(
                    '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                    style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
                ],
              )),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _showVideoMenu(context, video, d.globalPosition, t),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: SvgPicture.string(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
                    '<circle cx="12" cy="2.5" r="2.5"/>'
                    '<circle cx="12" cy="12" r="2.5"/>'
                    '<circle cx="12" cy="21.5" r="2.5"/></svg>',
                    width: 18, height: 18,
                    colorFilter: ColorFilter.mode(t.iconTertiary, BlendMode.srcIn)),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Widget de thumbnail com retry automático ─────────────────────────────────
// Resolve: timeout, 403, headers incorrectos, imagens presas em loading
class _ThumbImage extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final Color placeholder;
  const _ThumbImage({required this.url, required this.headers, required this.placeholder});
  @override
  State<_ThumbImage> createState() => _ThumbImageState();
}

class _ThumbImageState extends State<_ThumbImage> {
  // Chave para forçar rebuild do Image.network em retry
  int _attempt = 0;
  bool _failed = false;

  // Tempo máximo de espera por imagem — se demorar mais, trata como erro
  static const _kTimeout = Duration(seconds: 12);

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (widget.url.isEmpty || _failed) {
      return _placeholder(t);
    }

    return Image.network(
      // Adiciona o attempt como query param para forçar novo pedido no retry
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover,
      // SEM cacheWidth — deixa o Flutter gerir o decode nativamente (mais rápido)
      headers: widget.headers,
      // Timeout via frameCallback — Image.network não tem timeout nativo
      // mas ao usar key+attempt o Image é recriado limpo
      errorBuilder: (_, __, ___) {
        // Tenta mais uma vez automaticamente (máx 2 tentativas)
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
        if (progress == null) return child; // carregado
        // Shimmer enquanto carrega
        return _ThumbShimmer();
      },
    );
  }

  Widget _placeholder(AppTheme t) => Container(
    color: t.thumbBg,
    child: Center(child: Icon(Icons.play_circle_outline_rounded,
        color: t.iconSub, size: 40)),
  );
}

// Shimmer específico para a thumbnail
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
        // Sem headers extras — favicons são públicos
        // Sem cacheWidth para não bloquear
        gaplessPlayback: true, // não pisca ao recarregar
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

// Popup menu dos três pontinhos do VideoCard
void _showVideoMenu(BuildContext context, FeedVideo video, Offset pos, AppTheme t) {
  const _svgSaveLater =
      '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
      '<path d="m14.181.207a1 1 0 0 0 -1.181.983v2.879a8.053 8.053 0 1 0 6.931 6.931h2.886'
      'a1 1 0 0 0 .983-1.181 12.047 12.047 0 0 0 -9.619-9.612zm1.819 12.793h-2.277'
      'a1.994 1.994 0 1 1 -2.723-2.723v-3.277a1 1 0 0 1 2 0v3.277a2 2 0 0 1 .723.723h2.277'
      'a1 1 0 0 1 0 2z"/></svg>';
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
      '<path d="m5,20c0,1.381-1.119,2.5-2.5,2.5s-2.5-1.119-2.5-2.5,1.119-2.5,2.5-2.5,2.5,1.119,2.5,2.5Z'
      'M21.5,6.5c1.381,0,2.5-1.119,2.5-2.5s-1.119-2.5-2.5-2.5-2.5,1.119-2.5,2.5,1.119,2.5,2.5,2.5Z'
      'm-7.216-1.207c-.391-.391-1.023-.391-1.414,0s-.391,1.023,0,1.414l1.293,1.293h-6.163'
      'c-.552,0-1,.448-1,1s.448,1,1,1h6.228l-1.293,1.293c-.391.391-.391,1.023,0,1.414'
      '.195.195.451.293.707.293s.512-.098.707-.293l1.972-1.972c.939-.938.939-2.466,0-3.405l-2.037-2.037Z"/>'
      '</svg>';

  PopupMenuItem<String> _item(String val, String svg, String label) =>
      PopupMenuItem<String>(
        value: val, height: 46,
        child: Row(children: [
          SvgPicture.string(svg, width: 17, height: 17,
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
      _item('save',     _svgSaveLater, 'Guardar para assistir mais tarde'),
      _item('playlist', _svgPlaylist,  'Adicionar na minha playlist'),
      _item('next',     _svgPlayNext,  'Exibir como próximo vídeo'),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(children: [
        _SiteRow(sites: row1, onTap: onTap),
        if (row2.isNotEmpty) ...[
          const SizedBox(height: 18),
          _SiteRow(sites: row2, onTap: onTap),
        ],
      ]),
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
                    fontSize: 10,
                    fontWeight: FontWeight.w500)),
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
