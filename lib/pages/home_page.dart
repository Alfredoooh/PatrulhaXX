import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import '../services/feed_service.dart';
import '../services/theme_service.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';
import 'search_results_page.dart';

// ─── Cor primária: amarelo PornHub ────────────────────────────────────────────
const kPrimaryColor = Color(0xFFFF9000);

// ─── Ícones SVG ───────────────────────────────────────────────────────────────

// Início — filled (RSS-style)
const _svgHomeFilled =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="m1.5,19c.828,0,1.5.672,1.5,1.5s-.672,1.5-1.5,1.5S0,21.328,0,20.5s.672-1.5,1.5-1.5Z'
    'M8,21c0-3.86-3.14-7-7-7-.552,0-1,.448-1,1s.448,1,1,1c2.757,0,5,2.243,5,5,0,.552.448,1,1,1s1-.448,1-1Z'
    'm5,0c0-6.617-5.362-12-11.953-12-.552,0-1,.448-1,1s.448,1,1,1c5.488,0,9.953,4.486,9.953,10,0,.552.448,1,1,1s1-.448,1-1Z'
    'm11-4V7c0-2.757-2.243-5-5.001-5l-14.129.018C2.598,2.018.609,3.551.033,5.746c-.079.3.01.619.199.865'
    '.189.246.505.389.815.389,7.685,0,13.936,6.28,13.936,14,0,.552.465,1,1.017,1h3c2.757,0,5-2.243,5-5Z"/>'
    '</svg>';

// Início — outline
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

// Shorts — filled
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

// Shorts — outline
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
    // Remove age gates, cookie banners, consent walls
    document.querySelectorAll(
      '.age-gate,#age-gate,.AgeGate,[class*="ageGate"],[class*="age-gate"],' +
      '[id*="age-gate"],.cookieBanner,.cookie-banner,[class*="cookie-banner"],' +
      '.gdpr-banner,[class*="gdpr"],[class*="consent"],[class*="Consent"],' +
      '.limited-functionality,.tabs-container,.age-wall,[class*="ageWall"]'
    ).forEach(function(el) { el.remove(); });
    document.body.style.overflow = '';
    document.documentElement.style.overflow = '';
    // Oculta header/footer/nav
    ['header','footer','.header','.footer','nav#top','#header'].forEach(function(s) {
      var el = document.querySelector(s);
      if (el) el.style.display = 'none';
    });
    // Substitui texto "PornHub" pelo nome do app
    (function walkText(node) {
      if (node.nodeType === 3) {
        node.textContent = node.textContent.replace(/PornHub|Pornhub|pornhub/g, 'patrulhaXX');
      } else if (node.nodeType === 1 &&
          !['SCRIPT','STYLE','INPUT','TEXTAREA'].includes(node.tagName)) {
        node.childNodes.forEach(walkText);
      }
    })(document.body);
    // Oculta logos
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

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _tab = 0;
  List<FeedItem> _feed = [];
  bool _feedLoading = true;
  final _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;
  late final AnimationController _fadeIn;
  static const _kNavH = 60.0;

  @override
  void initState() {
    super.initState();
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600))
      ..forward();
    _loadFeed();
  }

  @override
  void dispose() {
    _fadeIn.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFeed({bool force = false}) async {
    if (mounted) setState(() => _feedLoading = true);
    final items = await FeedService.instance.load(force: force);
    if (mounted) setState(() { _feed = items; _feedLoading = false; });
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => SearchResultsPage(query: q)));
  }

  void _openFeed(FeedItem item) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BrowserPage(
                freeNavigation: true,
                site: SiteModel(
                    id: 'feed',
                    name: item.title,
                    baseUrl: item.url,
                    allowedDomain: '',
                    searchUrl: item.url,
                    primaryColor: kPrimaryColor),
              )));

  void _openSite(SiteModel site) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => BrowserPage(site: site)));

  @override
  Widget build(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final navTotal = _kNavH + safeBottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.black,
        body: Stack(children: [
          IndexedStack(index: _tab, children: [
            _HomeTab(
              fadeIn: _fadeIn,
              searchCtrl: _searchCtrl,
              hasQuery: _hasQuery,
              feed: _feed,
              feedLoading: _feedLoading,
              navBottom: navTotal,
              onOpen: _openSite,
              onFeedItem: _openFeed,
              onSearch: _onSearch,
              onSearchChanged: () => setState(() {}),
              onDownloads: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DownloadsPage())),
              onSettings: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SettingsPage())),
              onReload: () => _loadFeed(force: true),
            ),
            _ShortsTab(navBottom: navTotal),
          ]),

          // ── Bottom Nav — sempre preto sólido ─────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.black,
                border: Border(
                  top: BorderSide(color: Color(0xFF1F1F1F), width: 0.5),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: _kNavH,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NavItem(
                        svgFilled: _svgHomeFilled,
                        svgOutline: _svgHomeOutline,
                        active: _tab == 0,
                        onTap: () => setState(() => _tab = 0),
                      ),
                      _NavItem(
                        svgFilled: _svgShortsFilled,
                        svgOutline: _svgShortsOutline,
                        active: _tab == 1,
                        onTap: () => setState(() => _tab = 1),
                      ),
                    ],
                  ),
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
// Nav Item — usa SVG custom (filled/outline)
// ─────────────────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final String svgFilled;
  final String svgOutline;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.svgFilled,
    required this.svgOutline,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        height: 60,
        child: Center(
          child: SvgPicture.string(
            active ? svgFilled : svgOutline,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(
              active ? kPrimaryColor : Colors.white.withOpacity(0.38),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shorts Tab
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
                        'age_verified=1; accessAgeDisclaimerPH=1; accessPH=1; hasVisited=1; platform=pc; _tc=1'
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
// Home Tab
// ─────────────────────────────────────────────────────────────────────────────

class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final TextEditingController searchCtrl;
  final bool hasQuery;
  final List<FeedItem> feed;
  final bool feedLoading;
  final double navBottom;
  final void Function(SiteModel) onOpen;
  final void Function(FeedItem) onFeedItem;
  final VoidCallback onSearch, onSearchChanged, onDownloads, onSettings,
      onReload;

  const _HomeTab({
    required this.fadeIn,
    required this.searchCtrl,
    required this.hasQuery,
    required this.feed,
    required this.feedLoading,
    required this.navBottom,
    required this.onOpen,
    required this.onFeedItem,
    required this.onSearch,
    required this.onSearchChanged,
    required this.onDownloads,
    required this.onSettings,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Wallpaper
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Image.asset(
          ThemeService.instance.bg,
          key: ValueKey(ThemeService.instance.bg),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) =>
              Container(color: const Color(0xFF0C0C0C)),
        ),
      ),
      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Downloads + Settings
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(children: [
                      _CircleBtn(svg: _svgDownload, onTap: onDownloads),
                      const Spacer(),
                      _CircleBtn(svg: _svgSettings, onTap: onSettings),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search_rounded,
                            color: Colors.white.withOpacity(0.45),
                            size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: searchCtrl,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => onSearchChanged(),
                            onSubmitted: (_) => onSearch(),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Pesquisar vídeos, sites...',
                              hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 15),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 11),
                            ),
                          ),
                        ),
                        if (hasQuery)
                          GestureDetector(
                            onTap: onSearch,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: kPrimaryColor.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text('Ir',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                      ]),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _SitesGrid(sites: kSites, onTap: onOpen),
                  const SizedBox(height: 24),
                  // Feed header
                  Padding(
                    padding: const EdgeInsets.only(
                        left: 18, right: 18, bottom: 12),
                    child: Row(children: [
                      Text('Em destaque',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.65),
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      if (feedLoading)
                        SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Colors.white.withOpacity(0.3)))
                      else
                        GestureDetector(
                          onTap: onReload,
                          child: Icon(Icons.refresh_rounded,
                              color: kPrimaryColor.withOpacity(0.7),
                              size: 16),
                        ),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // Feed — cards com margens laterais e bordas curvas
          if (feedLoading)
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                  child: CircularProgressIndicator(
                      color: kPrimaryColor.withOpacity(0.4),
                      strokeWidth: 1.5)),
            ))
          else if (feed.isEmpty)
            SliverToBoxAdapter(
                child: Padding(
              padding: const EdgeInsets.only(top: 60),
              child: Center(
                  child: Text('Sem resultados de feed',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 13))),
            ))
          else
            SliverPadding(
              // ← margem lateral nos cards
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _FeedCard(
                        item: feed[i], onTap: () => onFeedItem(feed[i])),
                  ),
                  childCount: feed.length,
                ),
              ),
            ),

          SliverToBoxAdapter(child: SizedBox(height: navBottom + 8)),
        ]),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Feed Card — estilo da imagem de referência (bordas curvas, margens, sombra)
// ─────────────────────────────────────────────────────────────────────────────

String _faviconUrl(FeedItem item) {
  try {
    return 'https://www.google.com/s2/favicons?domain=${Uri.parse(item.url).host}&sz=32';
  } catch (_) {
    return '';
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  const _FeedCard({required this.item, required this.onTap});

  void _showMenu(BuildContext ctx) {
    final box = ctx.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    showMenu<String>(
      context: ctx,
      color: const Color(0xFF1C1C1E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromLTRB(
        offset.dx + box.size.width - 200,
        offset.dy + 40,
        offset.dx + box.size.width - 10,
        offset.dy + 80,
      ),
      items: [
        PopupMenuItem(
            value: 'share',
            child: Row(children: [
              const Icon(Icons.share_rounded,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 10),
              const Text('Partilhar',
                  style:
                      TextStyle(color: Colors.white, fontSize: 14)),
            ])),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = _faviconUrl(item);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Card com fundo escuro sólido
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Imagem 16:9 com header sobreposto ──────────────────────
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(children: [
                // Imagem
                Positioned.fill(
                  child: item.thumb.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.thumb,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                              color: const Color(0xFF252525)),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF252525),
                            child: const Center(
                                child: Icon(Icons.play_circle_outline,
                                    color: Colors.white24, size: 42)),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF252525),
                          child: const Center(
                              child: Icon(Icons.play_circle_outline,
                                  color: Colors.white24, size: 42)),
                        ),
                ),
                // Gradiente top (para o header ficar legível)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // Header: favicon + nome + bookmark/menu
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(children: [
                      // Avatar/favicon circular
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1),
                        ),
                        child: ClipOval(
                          child: fav.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: fav,
                                  width: 30,
                                  height: 30,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) =>
                                      _fallbackFavicon())
                              : _fallbackFavicon(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Fonte / domínio
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item.source.isNotEmpty
                                  ? item.source
                                  : _domainOf(item.url),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                      color: Colors.black54,
                                      blurRadius: 4)
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Botão 3-dot / menu
                      Builder(
                          builder: (ctx) => GestureDetector(
                                onTap: () => _showMenu(ctx),
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: kPrimaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.bookmark_rounded,
                                    color: Colors.white,
                                    size: 15,
                                  ),
                                ),
                              )),
                    ]),
                  ),
                ),
                // Badge de duração
                if (item.duration.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(item.duration,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
              ]),
            ),

            // ── Rodapé: dois botões como na imagem de referência ────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Botão "Copiar link"
                  _CardBtn(
                    label: 'Copiar link',
                    icon: Icons.link_rounded,
                    bg: const Color(0xFF252525),
                    textColor: Colors.white,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.url));
                    },
                  ),
                  const SizedBox(height: 8),
                  // Botão "Abrir vídeo"
                  _CardBtn(
                    label: 'Abrir vídeo',
                    icon: Icons.play_arrow_rounded,
                    bg: Colors.white,
                    textColor: Colors.black,
                    onTap: onTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackFavicon() => Container(
        color: Colors.white.withOpacity(0.12),
        child: const Icon(Icons.language, color: Colors.white38, size: 14),
      );

  String _domainOf(String url) {
    try {
      return Uri.parse(url).host.replaceFirst('www.', '');
    } catch (_) {
      return '';
    }
  }
}

// ─── Botão dentro do card ─────────────────────────────────────────────────────
class _CardBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bg;
  final Color textColor;
  final VoidCallback onTap;
  const _CardBtn({
    required this.label,
    required this.icon,
    required this.bg,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 16),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle button (download / settings)
// ─────────────────────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  const _CircleBtn({required this.svg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border:
              Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Center(
            child: SvgPicture.string(svg,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                    Colors.white, BlendMode.srcIn))),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sites grid
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                  color: Colors.white.withOpacity(0.08), width: 0.5),
            ),
            child: Column(children: [
              _Row(sites: row1, onTap: onTap),
              if (row2.isNotEmpty) ...[
                const SizedBox(height: 18),
                _Row(sites: row2, onTap: onTap)
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _Row({required this.sites, required this.onTap});
  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children:
            sites.map((s) => _Cell(site: s, onTap: () => onTap(s))).toList(),
      );
}

class _Cell extends StatefulWidget {
  final SiteModel site;
  final VoidCallback onTap;
  const _Cell({required this.site, required this.onTap});
  @override
  State<_Cell> createState() => _CellState();
}

class _CellState extends State<_Cell> with SingleTickerProviderStateMixin {
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
    final iconSize = MediaQuery.of(context).size.width * 0.13;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
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
// Free browser helper
// ─────────────────────────────────────────────────────────────────────────────

class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});
  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(
          id: 'feed',
          name: title,
          baseUrl: url,
          allowedDomain: '',
          searchUrl: url,
          primaryColor: kPrimaryColor),
      freeNavigation: true,
    );
  }
}
