import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import '../services/feed_service.dart';
import '../services/theme_service.dart';
import 'browser_page.dart';
import 'downloads_page.dart';
import 'settings_page.dart';

// ── Custom SVG icons ──────────────────────────────────────────────────────────
const _svgDownload = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M19,3h-6.528c-.154,0-.31-.036-.447-.105l-3.156-1.578c-.415-.207-.878-.316-1.341-.316h-2.528C2.243,1,0,3.243,0,6v12c0,2.757,2.243,5,5,5h1c.552,0,1-.447,1-1s-.448-1-1-1h-1c-1.654,0-3-1.346-3-3V9H22v9c0,1.654-1.346,3-3,3h-1c-.553,0-1,.447-1,1s.447,1,1,1h1c2.757,0,5-2.243,5-5V8c0-2.757-2.243-5-5-5ZM2,6c0-1.654,1.346-3,3-3h2.528c.154,0,.31,.036,.447,.105l3.156,1.578c.415,.207,.878,.316,1.341,.316h6.528c1.302,0,2.402,.839,2.816,2H2v-1Zm13.707,13.105c.391,.391,.391,1.023,0,1.414l-1.613,1.613c-.577,.577-1.335,.865-2.094,.865s-1.516-.288-2.093-.865l-1.614-1.613c-.391-.391-.391-1.023,0-1.414s1.023-.391,1.414,0l1.293,1.293v-7.398c0-.553,.448-1,1-1s1,.447,1,1v7.398l1.293-1.293c.391-.391,1.023-.391,1.414,0Z"/></svg>''';

const _svgSettings = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M1,4.75H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2ZM7.333,2a1.75,1.75,0,1,1-1.75,1.75A1.752,1.752,0,0,1,7.333,2Z"/><path d="M23,11H20.264a3.727,3.727,0,0,0-7.194,0H1a1,1,0,0,0,0,2H13.07a3.727,3.727,0,0,0,7.194,0H23a1,1,0,0,0,0-2Zm-6.333,2.75A1.75,1.75,0,1,1,18.417,12,1.752,1.752,0,0,1,16.667,13.75Z"/><path d="M23,19.25H10.931a3.728,3.728,0,0,0-7.195,0H1a1,1,0,0,0,0,2H3.736a3.728,3.728,0,0,0,7.195,0H23a1,1,0,0,0,0-2ZM7.333,22a1.75,1.75,0,1,1,1.75-1.75A1.753,1.753,0,0,1,7.333,22Z"/></svg>';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
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
    _fadeIn = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
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

  // Slide-up route
  Route _up(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 320),
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

  void _openFeedItem(FeedItem item) {
    Navigator.push(context, _up(FreeBrowserPage(url: item.url, title: item.title)));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeService.instance,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            child: Image.asset(
              ThemeService.instance.bg,
              key: ValueKey(ThemeService.instance.bg),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/images/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.55)),
          FadeTransition(
            opacity: CurvedAnimation(parent: _fadeIn, curve: Curves.easeOut),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top bar ────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(
                      children: [
                        _CircleBtn(
                          svg: _svgDownload,
                          onTap: () => Navigator.push(context,
                              _up(const DownloadsPage())),
                        ),
                        const Spacer(),
                        _CircleBtn(
                          svg: _svgSettings,
                          onTap: () => Navigator.push(context,
                              _up(const SettingsPage())),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ── Search bar ─────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _SearchBar(
                      controller: _searchCtrl,
                      hasQuery: _hasQuery,
                      onClear: () {
                        _searchCtrl.clear();
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── App grid 2×5 ──────────────────────────────────────
                  _SitesGrid(sites: kSites, onTap: _open),

                  const SizedBox(height: 20),

                  // ── Feed ───────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Text(
                      'Descobrir',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _feedLoading
                        ? const Center(child: SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 1.5,
                                color: Colors.white24)))
                        : _feed.isEmpty
                            ? Center(child: Text('Sem feed disponível',
                                style: TextStyle(color: Colors.white12, fontSize: 12)))
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _feed.length,
                                itemBuilder: (_, i) => _FeedCard(
                                    item: _feed[i],
                                    onTap: () => _openFeedItem(_feed[i])),
                              ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Circular top button ───────────────────────────────────────────────────────
class _CircleBtn extends StatefulWidget {
  final String svg;
  final VoidCallback onTap;
  const _CircleBtn({required this.svg, required this.onTap});

  @override
  State<_CircleBtn> createState() => _CircleBtnState();
}

class _CircleBtnState extends State<_CircleBtn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 90),
        reverseDuration: const Duration(milliseconds: 180),
        lowerBound: 0, upperBound: 1);
    _s = Tween<double>(begin: 1, end: 0.85)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.1),
            border: Border.all(color: Colors.white.withOpacity(0.12), width: 1),
          ),
          child: Center(
            child: SvgPicture.string(widget.svg,
                width: 20, height: 20,
                colorFilter: const ColorFilter.mode(Colors.white70, BlendMode.srcIn)),
          ),
        ),
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasQuery;
  final VoidCallback onClear;

  const _SearchBar({required this.controller, required this.hasQuery, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: hasQuery ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(children: [
        const SizedBox(width: 18),
        Icon(Icons.search_rounded,
            color: Colors.white.withOpacity(hasQuery ? 0.7 : 0.35), size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Pesquisar...',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
              border: InputBorder.none, isDense: true,
            ),
            textInputAction: TextInputAction.search,
            cursorColor: Colors.white70,
          ),
        ),
        if (hasQuery)
          GestureDetector(
            onTap: onClear,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Icon(Icons.cancel_rounded,
                  color: Colors.white.withOpacity(0.4), size: 20),
            ),
          )
        else
          const SizedBox(width: 16),
      ]),
    );
  }
}

// ── Sites grid 2 × 5 ─────────────────────────────────────────────────────────
class _SitesGrid extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SitesGrid({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
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
              _Row(sites: sites.sublist(0, 5), onTap: onTap),
              const SizedBox(height: 18),
              _Row(sites: sites.sublist(5, 10), onTap: onTap),
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
    _c = AnimationController(vsync: this,
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
              style: TextStyle(color: Colors.white.withOpacity(0.65),
                  fontSize: 10, fontWeight: FontWeight.w500)),
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
        width: 150,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(children: [
              item.thumb.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.thumb,
                      width: 150, height: 90,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                          width: 150, height: 90,
                          color: Colors.white.withOpacity(0.05)),
                      errorWidget: (_, __, ___) => Container(
                          width: 150, height: 90,
                          color: Colors.white.withOpacity(0.05),
                          child: const Icon(Icons.play_circle_outline,
                              color: Colors.white24)),
                    )
                  : Container(width: 150, height: 90,
                      color: Colors.white.withOpacity(0.05),
                      child: const Icon(Icons.play_circle_outline, color: Colors.white24)),
              if (item.duration.isNotEmpty)
                Positioned(bottom: 4, right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(4)),
                    child: Text(item.duration,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5)),
                  ),
                ),
              Positioned(top: 4, left: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text(item.source,
                      style: const TextStyle(color: Colors.white60, fontSize: 9)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 5),
          Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withOpacity(0.65),
                  fontSize: 11, height: 1.3)),
        ]),
      ),
    );
  }
}

// ── Free browser (for feed items — sem restrição de domínio) ──────────────────
class FreeBrowserPage extends StatefulWidget {
  final String url;
  final String title;
  const FreeBrowserPage({super.key, required this.url, required this.title});

  @override
  State<FreeBrowserPage> createState() => _FreeBrowserPageState();
}

class _FreeBrowserPageState extends State<FreeBrowserPage> {
  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(
        id: 'feed',
        name: widget.title,
        baseUrl: widget.url,
        allowedDomain: '',
        searchUrl: widget.url,
        primaryColor: const Color(0xFF1A1A1A),
      ),
      freeNavigation: true,
    );
  }
}
