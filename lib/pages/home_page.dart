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

// Primary color do app
const kPrimaryColor = Color(0xFFf5a992);

const _svgDownload = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M19,3h-6.528c-.154,0-.31-.036-.447-.105l-3.156-1.578c-.415-.207-.878-.316-1.341-.316h-2.528C2.243,1,0,3.243,0,6v12c0,2.757,2.243,5,5,5h1c.552,0,1-.447,1-1s-.448-1-1-1h-1c-1.654,0-3-1.346-3-3V9H22v9c0,1.654-1.346,3-3,3h-1c-.553,0-1,.447-1,1s.447,1,1,1h1c2.757,0,5-2.243,5-5V8c0-2.757-2.243-5-5-5ZM2,6c0-1.654,1.346-3,3-3h2.528c.154,0,.31,.036,.447,.105l3.156,1.578c.415,.207,.878,.316,1.341,.316h6.528c1.302,0,2.402,.839,2.816,2H2v-1Zm13.707,13.105c.391,.391,.391,1.023,0,1.414l-1.613,1.613c-.577,.577-1.335,.865-2.094,.865s-1.516-.288-2.093-.865l-1.614-1.613c-.391-.391-.391-1.023,0-1.414s1.023-.391,1.414,0l1.293,1.293v-7.398c0-.553,.448-1,1-1s1,.447,1,1v7.398l1.293-1.293c.391-.391,1.023-.391,1.414,0Z"/></svg>''';

const _svgSettings = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1,4.75H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2ZM7.333,2a1.75,1.75,0,1,1-1.75,1.75A1.752,1.752,0,0,1,7.333,2Z"/><path d="M23,11H20.264a3.727,3.727,0,0,0-7.194,0H1a1,1,0,0,0,0,2H13.07a3.727,3.727,0,0,0,7.194,0H23a1,1,0,0,0,0-2Zm-6.333,2.75A1.75,1.75,0,1,1,18.417,12,1.752,1.752,0,0,1,16.667,13.75Z"/><path d="M23,19.25H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2ZM7.333,22a1.75,1.75,0,1,1,1.75-1.75A1.753,1.753,0,0,1,7.333,22Z"/></svg>';

// JS injetado nos Shorts: remove dialogs + substitui textos PornHub + bloqueia nav fora de shorties
const _shortsJs = r"""
(function() {
  if (window.__pxShortsInit) return;
  window.__pxShortsInit = true;

  function cleanPage() {
    const selectors = [
      '.age-gate','#age-gate','.AgeGate','[class*="ageGate"]','[class*="age-gate"]',
      '[id*="age-gate"]','.cookieBanner','.cookie-banner','[class*="cookie"]',
      '.js-modal','.ReactModal__Overlay','.overlay-transition','[class*="modal"]',
      '[class*="Modal"]','.popup','.Popup','[class*="popup"]',
      '[class*="notification"]','.notification-bar','.adblock-warning',
      '.premium-promo','[class*="premium"]','[class*="Premium"]',
      '.gdpr-banner','[class*="gdpr"]','[class*="consent"]','[class*="Consent"]',
    ];
    selectors.forEach(function(sel) {
      document.querySelectorAll(sel).forEach(function(el) {
        var st = window.getComputedStyle(el);
        if (st.position === 'fixed' || st.position === 'absolute' ||
            st.zIndex > 100) {
          el.remove();
        }
      });
    });
    document.body.style.overflow = '';
    document.documentElement.style.overflow = '';

    // Substitui texto PornHub → patrulhaXX
    function walkText(node) {
      if (node.nodeType === 3) {
        node.textContent = node.textContent
          .replace(/PornHub/gi, 'patrulhaXX')
          .replace(/Pornhub/gi, 'patrulhaXX')
          .replace(/PORNHUB/g, 'PATRULHAXX');
      } else if (node.nodeType === 1 &&
          !['SCRIPT','STYLE','INPUT','TEXTAREA'].includes(node.tagName)) {
        node.childNodes.forEach(walkText);
      }
    }
    walkText(document.body);

    // Oculta logos
    document.querySelectorAll('img, svg').forEach(function(el) {
      var src = el.src || el.getAttribute('data-src') || '';
      if (src && src.toLowerCase().includes('logo')) {
        el.style.visibility = 'hidden';
      }
    });
    // Oculta header do PornHub
    var header = document.querySelector('header, #header, .header, nav#top');
    if (header) header.style.display = 'none';
  }

  cleanPage();

  var obs = new MutationObserver(function() { cleanPage(); });
  obs.observe(document.documentElement, { childList: true, subtree: true });

  // Tenta clicar em botões de confirmar idade automaticamente
  setTimeout(function() {
    ['[data-role="age-gate-submit"]','.age-gate__submit',
     'button[class*="confirm"]','button[class*="accept"]',
     'button[class*="age"]','.js-accept','.enter-btn'].forEach(function(sel) {
      var btn = document.querySelector(sel);
      if (btn) btn.click();
    });
    cleanPage();
  }, 600);

  setTimeout(cleanPage, 1500);
  setTimeout(cleanPage, 3000);
})();
""";

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _tab = 0;

  final _searchCtrl = TextEditingController();
  bool _hasQuery = false;
  late final AnimationController _fadeIn;
  List<FeedItem> _feed = [];
  bool _feedLoading = true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final has = _searchCtrl.text.trim().isNotEmpty;
      if (has != _hasQuery) setState(() => _hasQuery = has);
    });
    _fadeIn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500))
      ..forward();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final items = await FeedService.instance.load();
    if (mounted) setState(() { _feed = items; _feedLoading = false; });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeIn.dispose();
    super.dispose();
  }

  Route _up(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionDuration: const Duration(milliseconds: 380),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  void _open(SiteModel site) {
    final q = _hasQuery ? _searchCtrl.text.trim() : null;
    Navigator.push(context, _up(BrowserPage(site: site, initialQuery: q)));
  }

  void _openFeedItem(FeedItem item) =>
      Navigator.push(context, _up(FreeBrowserPage(url: item.url, title: item.title)));

  void _doSearch() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(context, _up(SearchResultsPage(query: q)));
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (ctx, _) => _buildShell(ctx),
    );
  }

  Widget _buildShell(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    const navH = 64.0;
    final navTotal = navH + bottomPad + 12.0;

    return Scaffold(
      backgroundColor: Colors.black,
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        // ── Conteúdo das tabs ────────────────────────────────────────────────
        Positioned.fill(
          child: IndexedStack(
            index: _tab,
            children: [
              // Tab 0 — Home
              _HomeTab(
                fadeIn: _fadeIn,
                searchCtrl: _searchCtrl,
                hasQuery: _hasQuery,
                feed: _feed,
                feedLoading: _feedLoading,
                navBottom: navTotal,
                onOpen: _open,
                onFeedItem: _openFeedItem,
                onSearch: _doSearch,
                onDownloads: () => Navigator.push(context, _up(const DownloadsPage())),
                onSettings: () => Navigator.push(context, _up(const SettingsPage())),
                onReload: () {
                  FeedService.instance.load(force: true).then((_) {
                    if (mounted) setState(() { _feed = FeedService.instance.items; });
                  });
                },
              ),
              // Tab 1 — Shorts
              _ShortsTab(navBottom: navTotal),
            ],
          ),
        ),

        // ── Bottom Nav Pill ──────────────────────────────────────────────────
        Positioned(
          left: 24,
          right: 24,
          bottom: bottomPad + 12,
          child: _BottomNav(
            currentTab: _tab,
            onTab: (i) => setState(() => _tab = i),
          ),
        ),
      ]),
    );
  }
}

// ── Bottom Nav Pill estilo Apple ──────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentTab;
  final ValueChanged<int> onTab;
  const _BottomNav({required this.currentTab, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final isShorts = currentTab == 1;
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: isShorts
            ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
            : ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: isShorts
                ? Colors.black.withOpacity(0.96)
                : Colors.black.withOpacity(0.32),
            border: Border.all(
              color: Colors.white.withOpacity(isShorts ? 0.07 : 0.14),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavItem(
                icon: Icons.grid_view_rounded,
                label: 'Home',
                active: currentTab == 0,
                onTap: () => onTab(0),
              ),
              _NavItem(
                icon: Icons.play_circle_fill_rounded,
                label: 'Shorts',
                active: currentTab == 1,
                onTap: () => onTab(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon, required this.label,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 10),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 24,
              color: active ? kPrimaryColor : Colors.white.withOpacity(0.32)),
          const SizedBox(height: 3),
          Text(label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? kPrimaryColor : Colors.white.withOpacity(0.32),
            )),
        ]),
      ),
    );
  }
}

// ── Shorts Tab ─────────────────────────────────────────────────────────────────
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: EdgeInsets.only(bottom: widget.navBottom),
      child: InAppWebView(
        initialUrlRequest:
            URLRequest(url: WebUri('https://pt.pornhub.com/shorties')),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          domStorageEnabled: true,
          databaseEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
          useShouldOverrideUrlLoading: true,
          useOnDownloadStart: false,
          supportZoom: false,
          userAgent:
              'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
              '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
        ),
        onLoadStop: (ctrl, _) async {
          await ctrl.evaluateJavascript(source: _shortsJs);
        },
        // Só permite URLs com "shorties"
        shouldOverrideUrlLoading: (ctrl, action) async {
          final url = action.request.url?.toString() ?? '';
          final lower = url.toLowerCase();
          if (lower.contains('shorties') ||
              lower.startsWith('about:') ||
              lower.startsWith('blob:') ||
              lower.startsWith('data:') ||
              lower.contains('cdn') ||
              lower.contains('.js') ||
              lower.contains('.css') ||
              lower.contains('.png') ||
              lower.contains('.jpg') ||
              lower.contains('.mp4') ||
              lower.contains('api.') ||
              lower.contains('/api/')) {
            return NavigationActionPolicy.ALLOW;
          }
          return NavigationActionPolicy.CANCEL;
        },
        onPermissionRequest: (_, req) async => PermissionResponse(
          resources: req.resources,
          action: PermissionResponseAction.GRANT,
        ),
      ),
    );
  }
}

// ── Home Tab ───────────────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final AnimationController fadeIn;
  final TextEditingController searchCtrl;
  final bool hasQuery;
  final List<FeedItem> feed;
  final bool feedLoading;
  final double navBottom;
  final void Function(SiteModel) onOpen;
  final void Function(FeedItem) onFeedItem;
  final VoidCallback onSearch;
  final VoidCallback onDownloads;
  final VoidCallback onSettings;
  final VoidCallback onReload;

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
    required this.onDownloads,
    required this.onSettings,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      // Wallpaper (funcionalidade mantida)
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Image.asset(
          ThemeService.instance.bg,
          key: ValueKey(ThemeService.instance.bg),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) =>
              Image.asset('assets/images/background.png', fit: BoxFit.cover),
        ),
      ),
      Container(color: Colors.black.withOpacity(0.52)),

      FadeTransition(
        opacity: CurvedAnimation(parent: fadeIn, curve: Curves.easeOut),
        child: SafeArea(
          bottom: false,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top bar
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
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded,
                      color: Colors.white.withOpacity(0.45), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: searchCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => onSearch(),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Pesquisar vídeos, sites...',
                        hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.35), fontSize: 15),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 11),
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

            // Sites grid
            _SitesGrid(sites: kSites, onTap: onOpen),
            const SizedBox(height: 24),

            // Feed header
            Padding(
              padding: const EdgeInsets.only(left: 18, bottom: 12),
              child: Row(children: [
                Text('Em destaque',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                if (feedLoading)
                  SizedBox(
                      width: 12, height: 12,
                      child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white.withOpacity(0.3)))
                else
                  GestureDetector(
                    onTap: onReload,
                    child: Icon(Icons.refresh_rounded,
                        color: kPrimaryColor.withOpacity(0.7), size: 16),
                  ),
              ]),
            ),

            // Feed list
            Expanded(
              child: feedLoading
                  ? Center(
                      child: CircularProgressIndicator(
                          color: kPrimaryColor.withOpacity(0.4),
                          strokeWidth: 1.5))
                  : feed.isEmpty
                      ? Center(
                          child: Text('Sem resultados de feed',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.25),
                                  fontSize: 13)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(left: 16, right: 16),
                          itemCount: feed.length,
                          itemBuilder: (_, i) => _FeedCard(
                            item: feed[i],
                            onTap: () => onFeedItem(feed[i]),
                          ),
                        ),
            ),

            SizedBox(height: navBottom),
          ]),
        ),
      ),
    ]);
  }
}

// ── Botão redondo ─────────────────────────────────────────────────────────────
class _CircleBtn extends StatelessWidget {
  final String svg;
  final VoidCallback onTap;
  const _CircleBtn({required this.svg, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.3),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Center(
          child: SvgPicture.string(svg, width: 18, height: 18,
              colorFilter:
                  const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
        ),
      ),
    );
  }
}

// ── Sites grid ────────────────────────────────────────────────────────────────
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
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
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
                _Row(sites: row2, onTap: onTap),
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
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: sites.map((s) => _Cell(site: s, onTap: () => onTap(s))).toList(),
    );
  }
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

// ── Feed card ─────────────────────────────────────────────────────────────────
class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  const _FeedCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150, margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              item.thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumb,
                      width: 150, height: 90, fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 150, height: 90,
                          color: Colors.white.withOpacity(0.05)),
                      errorWidget: (_, __, ___) => Container(
                          width: 150, height: 90,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.play_circle_outline,
                              color: Colors.white24)),
                    )
                  : Container(
                      width: 150, height: 90,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.play_circle_outline,
                          color: Colors.white24)),
              if (item.duration.isNotEmpty)
                Positioned(
                  bottom: 4, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(item.duration,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 9.5)),
                  ),
                ),
              Positioned(
                top: 4, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: kPrimaryColor.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(item.source,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 5),
          Text(item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65),
                  fontSize: 11,
                  height: 1.3)),
        ]),
      ),
    );
  }
}

// ── Free browser ──────────────────────────────────────────────────────────────
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
        primaryColor: kPrimaryColor,
      ),
      freeNavigation: true,
    );
  }
}
