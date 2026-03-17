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

const kPrimaryColor = Color(0xFFFF0000); // YouTube Red

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

  var st = setInterval(function() {
    var v = document.querySelector('video');
    if (v) {
      clearInterval(st);
      function cV() {
        if (!v || v.readyState < 3) return;
        v.muted = false;
        v.volume = 1.0;
        v.play().catch(function(){});
      }
      v.addEventListener('loadeddata', cV);
      cV();

      var obs = new MutationObserver(function() {
        var vn = document.querySelector('video');
        if (vn && vn !== v) {
          v = vn;
          v.addEventListener('loadeddata', cV);
          cV();
        }
      });
      obs.observe(document.body, { childList: true, subtree: true });
    }
  }, 500);

  var cc = document.querySelector('.cookie-container, [class*="cookie"], [class*="consent"]');
  if (cc && cc.style) cc.style.display = 'none';
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final TabController _tabController;
  final GlobalKey<ExibicaoPageState> _exibicaoKey = GlobalKey<ExibicaoPageState>();

  final List<SiteModel> _demoSites = [
    SiteModel(id: 'x', name: 'Xvideos', baseUrl: 'https://www.xvideos.com',
        allowedDomain: 'xvideos.com',
        searchUrl: 'https://www.xvideos.com/?k=', primaryColor: const Color(0xFFE61B23)),
    SiteModel(id: 'ph', name: 'Pornhub', baseUrl: 'https://pt.pornhub.com',
        allowedDomain: 'pornhub.com',
        searchUrl: 'https://pt.pornhub.com/video/search?search=',
        primaryColor: const Color(0xFFFF9000)),
    SiteModel(id: 'xnx', name: 'XNXX', baseUrl: 'https://www.xnxx.com',
        allowedDomain: 'xnxx.com',
        searchUrl: 'https://www.xnxx.com/search/', primaryColor: const Color(0xFFD32F2F)),
    SiteModel(id: 'xh', name: 'xHamster', baseUrl: 'https://xhamster.com',
        allowedDomain: 'xhamster.com',
        searchUrl: 'https://xhamster.com/search/', primaryColor: const Color(0xFFFF6D00)),
    SiteModel(id: 'yp', name: 'YouPorn', baseUrl: 'https://www.youporn.com',
        allowedDomain: 'youporn.com',
        searchUrl: 'https://www.youporn.com/search/?query=',
        primaryColor: const Color(0xFF000000)),
    SiteModel(id: 'tx', name: 'Txxx', baseUrl: 'https://www.txxx.com',
        allowedDomain: 'txxx.com',
        searchUrl: 'https://www.txxx.com/search/?q=', primaryColor: const Color(0xFF5D4037)),
    SiteModel(id: 'rt', name: 'RedTube', baseUrl: 'https://www.redtube.com',
        allowedDomain: 'redtube.com',
        searchUrl: 'https://www.redtube.com/?search=', primaryColor: const Color(0xFFE53935)),
    SiteModel(id: 'ep', name: 'Eporner', baseUrl: 'https://www.eporner.com',
        allowedDomain: 'eporner.com',
        searchUrl: 'https://www.eporner.com/search/', primaryColor: const Color(0xFF000000)),
  ];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onNavTap(int idx) {
    // Pausa o player ao sair do tab de exibição
    if (_currentIndex == 1 && idx != 1) {
      _exibicaoKey.currentState?.pausePlayer();
    }
    // Resume se voltar para exibição
    if (idx == 1 && _currentIndex != 1) {
      _exibicaoKey.currentState?.resumeIfNeeded();
    }
    setState(() => _currentIndex = idx);
  }

  void _openBrowser(SiteModel s) =>
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => BrowserPage(site: s, freeNavigation: false)));

  void _openSiteInFreeBrowser(String url, String title) {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FreeBrowserPage(url: url, title: title)));
  }

  void _doSearch() {
    final q = _searchController.text.trim();
    if (q.isEmpty) return;
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => SearchResultsPage(query: q, sites: _demoSites)));
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Scaffold(
        backgroundColor: theme.bg,
        drawer: _buildDrawer(theme),
        body: _currentIndex == 0
            ? _HomeTab(
                sites: _demoSites,
                onTap: _openBrowser,
                onSearch: _doSearch,
                searchController: _searchController,
                tabController: _tabController,
                onSiteTap: _openSiteInFreeBrowser,
              )
            : _currentIndex == 1
                ? ExibicaoPage(key: _exibicaoKey)
                : _currentIndex == 2
                    ? const DownloadsPage()
                    : const SettingsPage(),
        bottomNavigationBar: _buildBottomNav(theme),
      );
    });
  }

  // ── Drawer estilo YouTube (sem bordas arredondadas, fica na frente do bottom bar) ──
  Widget _buildDrawer(AppTheme theme) {
    return Drawer(
      backgroundColor: theme.drawerBg,
      width: MediaQuery.of(context).size.width * 0.75,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // SEM bordas arredondadas como YouTube
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header do drawer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.menu, color: theme.icon, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    'Menu',
                    style: TextStyle(
                      color: theme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // Items do drawer
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(
                    theme,
                    icon: Icons.home,
                    title: 'Início',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 0);
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.slideshow,
                    title: 'Exibição',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 1);
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: Icons.download,
                    title: 'Downloads',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 2);
                    },
                  ),
                  Divider(color: theme.divider, height: 1),
                  _drawerItem(
                    theme,
                    icon: Icons.settings,
                    title: 'Configurações',
                    onTap: () {
                      Navigator.pop(context);
                      setState(() => _currentIndex = 3);
                    },
                  ),
                  _drawerItem(
                    theme,
                    icon: ThemeService.instance.isDark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                    title: ThemeService.instance.isDark
                        ? 'Modo Claro'
                        : 'Modo Escuro',
                    onTap: () {
                      ThemeService.instance.setDark(!ThemeService.instance.isDark);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    AppTheme theme, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: theme.iconSub, size: 24),
            const SizedBox(width: 24),
            Text(
              title,
              style: TextStyle(
                color: theme.text,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(AppTheme theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.navBg,
        border: Border(top: BorderSide(color: theme.navBorder, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_outlined, Icons.home, 'Início', theme),
              _navItem(1, Icons.slideshow_outlined, Icons.slideshow, 'Exibição', theme),
              _navItem(2, Icons.download_outlined, Icons.download, 'Downloads', theme),
              _navItem(3, Icons.settings_outlined, Icons.settings, 'Definições', theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData iconOutline, IconData iconFilled,
      String label, AppTheme theme) {
    final isActive = idx == _currentIndex;
    return Expanded(
      child: InkWell(
        onTap: () => _onNavTap(idx),
        splashColor: theme.splash,
        highlightColor: theme.highlight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? iconFilled : iconOutline,
              color: isActive ? theme.navActive : theme.navInactive,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? theme.navActive : theme.navInactive,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HomeTab
// ─────────────────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  final VoidCallback onSearch;
  final TextEditingController searchController;
  final TabController tabController;
  final void Function(String, String) onSiteTap;

  const _HomeTab({
    required this.sites,
    required this.onTap,
    required this.onSearch,
    required this.searchController,
    required this.tabController,
    required this.onSiteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: theme.appBar,
            elevation: 0,
            pinned: true,
            floating: true,
            leading: Builder(
              builder: (context) => IconButton(
                icon: Icon(Icons.menu, color: theme.icon, size: 26),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Text(
              'PixlHub',
              style: TextStyle(
                color: theme.text,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: theme.icon, size: 26),
                onPressed: () => _showSearchSheet(context, theme),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: theme.divider,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _SitesGrid(sites: sites, onTap: onTap),
                const SizedBox(height: 24),
                _TabSection(
                  tabController: tabController,
                  onSiteTap: onSiteTap,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  void _showSearchSheet(BuildContext context, AppTheme theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.sheet,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              autofocus: true,
              style: TextStyle(color: theme.inputText),
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                hintStyle: TextStyle(color: theme.inputHint),
                filled: true,
                fillColor: theme.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.inputBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.inputBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.borderFocused, width: 2),
                ),
                suffixIcon: IconButton(
                  icon: Icon(Symbols.search, color: theme.icon),
                  onPressed: () {
                    Navigator.pop(ctx);
                    onSearch();
                  },
                ),
              ),
              onSubmitted: (_) {
                Navigator.pop(ctx);
                onSearch();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TabSection
// ─────────────────────────────────────────────────────────────────────────────
class _TabSection extends StatelessWidget {
  final TabController tabController;
  final void Function(String, String) onSiteTap;

  const _TabSection({
    required this.tabController,
    required this.onSiteTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.bg,
              border: Border(
                bottom: BorderSide(color: theme.divider, width: 0.5),
              ),
            ),
            child: TabBar(
              controller: tabController,
              labelColor: theme.text,
              unselectedLabelColor: theme.textSub,
              indicatorColor: kPrimaryColor,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'Vídeos Recentes'),
                Tab(text: 'Shorts'),
              ],
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: TabBarView(
              controller: tabController,
              children: [
                _VideosTab(onSiteTap: onSiteTap),
                _ShortsTab(onSiteTap: onSiteTap),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VideosTab
// ─────────────────────────────────────────────────────────────────────────────
class _VideosTab extends StatefulWidget {
  final void Function(String, String) onSiteTap;
  const _VideosTab({required this.onSiteTap});

  @override
  State<_VideosTab> createState() => _VideosTabState();
}

class _VideosTabState extends State<_VideosTab> {
  List<_VideoInfo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchVideos();
  }

  Future<void> _fetchVideos() async {
    setState(() => _loading = true);
    try {
      final res = await http
          .get(Uri.parse('https://www.eporner.com/api/v2/video/search/?query=&per_page=10&page=1'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List items = json['videos'] ?? [];
        setState(() {
          _videos = items.map((v) => _VideoInfo.fromJson(v)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      if (_loading) {
        return Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentBlue),
          ),
        );
      }
      if (_videos.isEmpty) {
        return Center(
          child: Text(
            'Nenhum vídeo encontrado',
            style: TextStyle(color: theme.textSub),
          ),
        );
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _videos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (ctx, i) => _VideoCard(
          video: _videos[i],
          onTap: () => widget.onSiteTap(_videos[i].url, _videos[i].title),
        ),
      );
    });
  }
}

class _VideoInfo {
  final String id, title, thumb, url, views, sourceLabel, sourceInitial;
  _VideoInfo({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    required this.views,
    required this.sourceLabel,
    required this.sourceInitial,
  });

  factory _VideoInfo.fromJson(Map<String, dynamic> j) => _VideoInfo(
        id: j['id']?.toString() ?? '',
        title: j['title'] ?? 'Sem título',
        thumb: j['default_thumb']?['src'] ?? '',
        url: j['url'] ?? '',
        views: j['views']?.toString() ?? '',
        sourceLabel: 'Eporner',
        sourceInitial: 'E',
      );
}

class _VideoCard extends StatelessWidget {
  final _VideoInfo video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return InkWell(
        onTap: onTap,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: theme.thumbBg,
              child: video.thumb.isNotEmpty
                  ? Image.network(video.thumb, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.play_circle_outline, color: theme.thumbIcon, size: 48))
                  : Icon(Icons.play_circle_outline, color: theme.thumbIcon, size: 48),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: theme.chipBg, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      video.sourceInitial,
                      style: TextStyle(
                        color: theme.textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                      style: TextStyle(color: theme.textSub, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: theme.iconSub, size: 18),
            ]),
          ),
        ]),
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ShortsTab
// ─────────────────────────────────────────────────────────────────────────────
class _ShortsTab extends StatelessWidget {
  final void Function(String, String) onSiteTap;
  const _ShortsTab({required this.onSiteTap});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Center(
        child: Text(
          'Shorts em breve...',
          style: TextStyle(color: theme.textSub, fontSize: 16),
        ),
      );
    });
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
    return AppThemeBuilder(builder: (context, theme) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 4),
          decoration: BoxDecoration(
            color: theme.cardElevated,
            borderRadius: BorderRadius.circular(12), // Menos curvado (era 22)
            border: Border.all(color: theme.borderSubtle, width: 0.5),
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
    });
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
    return AppThemeBuilder(builder: (context, theme) {
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
                      color: theme.iconSub,
                      fontSize: 10, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      );
    });
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
