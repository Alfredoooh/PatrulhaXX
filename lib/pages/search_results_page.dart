import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/feed_service.dart';
import '../models/site_model.dart';
import 'browser_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _q;
  List<FeedItem> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _q = TextEditingController(text: widget.query);
    _load();
  }

  @override
  void dispose() { _tabs.dispose(); _q.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    await FeedService.instance.load();
    _applyQuery();
    if (mounted) setState(() => _loading = false);
  }

  void _applyQuery() {
    _all = FeedService.instance.search(_q.text.trim());
  }

  void _search() {
    FocusScope.of(context).unfocus();
    _applyQuery();
    setState(() {});
  }

  List<FeedItem> get _videos  => _all.where((i) => i.type == 'video').toList();
  List<FeedItem> get _articles => _all.where((i) => i.type == 'article').toList();

  List<SiteModel> get _sites {
    final q = _q.text.trim().toLowerCase();
    if (q.isEmpty) return kSites;
    return kSites.where((s) =>
      s.name.toLowerCase().contains(q) ||
      s.baseUrl.toLowerCase().contains(q)
    ).toList();
  }

  void _open(FeedItem item) => Navigator.push(
    context,
    _slide(BrowserPage(
      freeNavigation: true,
      site: SiteModel(id: 'feed', name: item.title,
          baseUrl: item.url, allowedDomain: '',
          searchUrl: item.url, primaryColor: const Color(0xFF1A1A1A)),
    )),
  );

  void _openSite(SiteModel site) => Navigator.push(
    context, _slide(BrowserPage(site: site, initialQuery: _q.text.trim())));

  Route _slide(Widget page) => PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (_, a, __, child) => SlideTransition(
      position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
          .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _q,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _search(),
          decoration: InputDecoration(
            hintText: 'Pesquisar...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 15),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 22),
            onPressed: _search,
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          indicatorWeight: 2,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Todos'),
            Tab(text: 'Vídeos'),
            Tab(text: 'Artigos'),
            Tab(text: 'Sites'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.white30, strokeWidth: 2))
          : TabBarView(
              controller: _tabs,
              children: [
                _GridFeed(items: _all, onTap: _open),
                _GridFeed(items: _videos, onTap: _open),
                _ListFeed(items: _articles, onTap: _open),
                _SitesGrid(sites: _sites, onTap: _openSite),
              ],
            ),
    );
  }
}

// ── Grid de vídeos/artigos ─────────────────────────────────────────────────
class _GridFeed extends StatelessWidget {
  final List<FeedItem> items;
  final void Function(FeedItem) onTap;
  const _GridFeed({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _empty('Sem resultados');
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 11,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _Card(item: items[i], onTap: () => onTap(items[i])),
    );
  }
}

class _Card extends StatelessWidget {
  final FeedItem item;
  final VoidCallback onTap;
  const _Card({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(fit: StackFit.expand, children: [
          item.thumb.isNotEmpty
            ? CachedNetworkImage(imageUrl: item.thumb, fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _ph())
            : _ph(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
              ),
            ),
          ),
          Positioned(bottom: 6, left: 8, right: 8,
            child: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3))),
          Positioned(top: 5, right: 5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4)),
              child: Text(item.source, style: const TextStyle(color: Colors.white60, fontSize: 8.5)),
            )),
          if (item.duration.isNotEmpty)
            Positioned(bottom: 6, right: 5,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(3)),
                child: Text(item.duration, style: const TextStyle(color: Colors.white, fontSize: 9)),
              )),
        ]),
      ),
    );
  }

  Widget _ph() => Container(color: Colors.white.withOpacity(0.06),
      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white24, size: 32)));
}

// ── Lista de artigos ───────────────────────────────────────────────────────
class _ListFeed extends StatelessWidget {
  final List<FeedItem> items;
  final void Function(FeedItem) onTap;
  const _ListFeed({required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return _empty('Sem artigos');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.white.withOpacity(0.06)),
      itemBuilder: (_, i) {
        final item = items[i];
        return InkWell(
          onTap: () => onTap(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.thumb.isNotEmpty
                  ? CachedNetworkImage(imageUrl: item.thumb,
                      width: 80, height: 56, fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _phSmall())
                  : _phSmall(),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)),
                const SizedBox(height: 4),
                Text(item.source, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11)),
              ])),
            ]),
          ),
        );
      },
    );
  }

  Widget _phSmall() => Container(width: 80, height: 56,
    color: Colors.white.withOpacity(0.06),
    child: const Icon(Icons.article_outlined, color: Colors.white24, size: 22));
}

// ── Grelha de sites ─────────────────────────────────────────────────────────
class _SitesGrid extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _SitesGrid({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (sites.isEmpty) return _empty('Nenhum site encontrado');
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, childAspectRatio: 1,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: sites.length,
      itemBuilder: (_, i) {
        final s = sites[i];
        return GestureDetector(
          onTap: () => onTap(s),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: s.primaryColor.withOpacity(0.15),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: s.hasLocalIcon
                  ? Image.asset(s.localIconAsset!, fit: BoxFit.cover)
                  : Center(child: Text(s.name[0].toUpperCase(),
                      style: TextStyle(color: s.primaryColor, fontSize: 22,
                          fontWeight: FontWeight.w700))),
              ),
            ),
            const SizedBox(height: 6),
            Text(s.name, textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ]),
        );
      },
    );
  }
}

Widget _empty(String msg) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded, color: Colors.white.withOpacity(0.12), size: 52),
    const SizedBox(height: 12),
    Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)),
  ]),
);
