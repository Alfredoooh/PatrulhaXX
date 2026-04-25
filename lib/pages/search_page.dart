import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_model.dart';
import '../widgets/site_icon_widget.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'browser_page.dart';
import 'search_results_page.dart';

const kPrimaryColor = Color(0xFFFF9000);

Route<T> iosRoute<T>(Widget page) => CupertinoPageRoute<T>(builder: (_) => page);

class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});
  @override
  Widget build(BuildContext context) => BrowserPage(
    site: SiteModel(
      id: 'free', name: title, baseUrl: url,
      allowedDomain: '', searchUrl: url, primaryColor: kPrimaryColor,
    ),
    freeNavigation: true,
  );
}

// ─── Dados estáticos ───────────────────────────────────────────────────────────
class _Category {
  final String label;
  final String asset; // assets/imagens/search_page/xxx.jpg
  const _Category({required this.label, required this.asset});
}

const _categories = [
  _Category(label: 'Heterossexual', asset: 'assets/imagens/search_page/hetero.jpg'),
  _Category(label: 'Homossexual',   asset: 'assets/imagens/search_page/homo.jpg'),
  _Category(label: 'Lésbicas',      asset: 'assets/imagens/search_page/lesbicas.jpg'),
  _Category(label: 'Anal',          asset: 'assets/imagens/search_page/anal.jpg'),
  _Category(label: 'Amador',        asset: 'assets/imagens/search_page/amador.jpg'),
  _Category(label: 'MILF',          asset: 'assets/imagens/search_page/milf.jpg'),
  _Category(label: 'Teen',          asset: 'assets/imagens/search_page/teen.jpg'),
  _Category(label: 'Hentai',        asset: 'assets/imagens/search_page/hentai.jpg'),
];

// ─── SearchPage ───────────────────────────────────────────────────────────────
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> _history = [];
  static const _kHistory = 'search_history_v3';

  @override void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _history = p.getStringList(_kHistory) ?? []);
  }

  Future<void> _removeHistory(String q) async {
    _history.remove(q);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
  }

  Future<void> _clearHistory() async {
    _history.clear();
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHistory);
  }

  void _goSearch(String q) =>
      Navigator.push(context, iosRoute(SearchResultsPage(query: q)));

  void _goSearchPage() =>
      Navigator.push(context, iosRoute(const SearchResultsPage()));

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t      = AppTheme.current;
        final isDark = ThemeService.instance.isDark;
        final cardBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
        final mutedIc = isDark ? Colors.white30 : Colors.black26;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: t.statusBar,
          ),
          child: Scaffold(
            backgroundColor: t.bg,
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // ── AppBar fixo ──────────────────────────────────────────
                Container(
                  color: t.appBar,
                  padding: EdgeInsets.only(
                    top: topPad + 8, left: 16, right: 16, bottom: 10),
                  child: Row(children: [
                    Text('Pesquisar', style: TextStyle(
                      color: t.text, fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: _goSearchPage,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : const Color(0xFFE8E8E8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const SizedBox(width: 10),
                            Image.asset('assets/icons/svg/search.svg',
                              width: 16, height: 16,
                              color: isDark ? Colors.white38 : Colors.black38,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.search, size: 16,
                                color: isDark ? Colors.white38 : Colors.black38),
                            ),
                            const SizedBox(width: 6),
                            Text('Pesquisar...', style: TextStyle(
                              color: isDark ? Colors.white30 : Colors.black38,
                              fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),

                // ── Conteúdo com efeito elástico ─────────────────────────
                Expanded(
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics()),
                    slivers: [

                      // Sites
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: SizedBox(
                            height: 88,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: kSites.length,
                              itemBuilder: (_, i) => _SiteCell(
                                site: kSites[i],
                                onTap: () => Navigator.push(context,
                                  iosRoute(FreeBrowserPage(
                                    url: kSites[i].baseUrl,
                                    title: kSites[i].name))),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Título Categorias
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                          child: Text('Categorias', style: TextStyle(
                            color: t.text, fontSize: 17,
                            fontWeight: FontWeight.w700)),
                        ),
                      ),

                      // Grid categorias
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _CategoryCard(
                              category: _categories[i],
                              onTap: () => _goSearch(_categories[i].label),
                            ),
                            childCount: _categories.length,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.55,
                          ),
                        ),
                      ),

                      // Histórico
                      if (_history.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Histórico', style: TextStyle(
                                  color: t.text, fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                                GestureDetector(
                                  onTap: _clearHistory,
                                  child: Text('Limpar', style: TextStyle(
                                    color: AppTheme.ytRed, fontSize: 14,
                                    fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) {
                                final label = _history[i];
                                final total = _history.length;
                                final isOnly  = total == 1;
                                final isFirst = i == 0;
                                final isLast  = i == total - 1;
                                const big   = Radius.circular(12);
                                const small = Radius.circular(6);
                                final radius = isOnly
                                  ? const BorderRadius.all(big)
                                  : isFirst
                                    ? const BorderRadius.only(
                                        topLeft: big, topRight: big,
                                        bottomLeft: small, bottomRight: small)
                                    : isLast
                                      ? const BorderRadius.only(
                                          topLeft: small, topRight: small,
                                          bottomLeft: big, bottomRight: big)
                                      : const BorderRadius.all(small);

                                return Padding(
                                  padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
                                  child: Dismissible(
                                    key: ValueKey(label),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (_) => _removeHistory(label),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 16),
                                      child: const Icon(Icons.delete,
                                          color: Colors.white, size: 20),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: radius,
                                      child: Container(
                                        color: cardBg,
                                        height: 58,
                                        child: GestureDetector(
                                          onTap: () => _goSearch(label),
                                          behavior: HitTestBehavior.opaque,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 14),
                                            child: Row(children: [
                                              Image.asset(
                                                'assets/icons/svg/history.svg',
                                                width: 16, height: 16,
                                                color: mutedIc,
                                                errorBuilder: (_, __, ___) =>
                                                  Icon(Icons.access_time,
                                                      size: 16, color: mutedIc),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(child: Text(label,
                                                style: TextStyle(
                                                  color: t.text, fontSize: 15,
                                                  fontWeight: FontWeight.w400))),
                                            ]),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                              childCount: _history.length,
                            ),
                          ),
                        ),
                      ],

                      const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── _CategoryCard — imagem local de asset ────────────────────────────────────
class _CategoryCard extends StatelessWidget {
  final _Category category;
  final VoidCallback onTap;
  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(fit: StackFit.expand, children: [

          // Imagem local — sem rede, sem lag
          Image.asset(
            category.asset,
            fit: BoxFit.cover,
            cacheWidth: 400, // limita memória de decode
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1E1E1E)),
          ),

          // Gradiente
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xA6000000)],
              ),
            ),
          ),

          // Label
          Positioned(
            left: 10, bottom: 8, right: 10,
            child: Text(category.label,
              style: const TextStyle(
                color: Colors.white, fontSize: 13,
                fontWeight: FontWeight.w700,
                shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
              )),
          ),
        ]),
      ),
    );
  }
}

// ─── _SiteCell ────────────────────────────────────────────────────────────────
class _SiteCell extends StatefulWidget {
  final SiteModel site;
  final VoidCallback onTap;
  const _SiteCell({required this.site, required this.onTap});
  @override State<_SiteCell> createState() => _SiteCellState();
}

class _SiteCellState extends State<_SiteCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _s;

  @override void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _s = Tween<double>(begin: 1.0, end: 0.86)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 52;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) { _c.reverse(); widget.onTap(); },
      onTapCancel: () => _c.reverse(),
      child: AnimatedBuilder(
        animation: _s,
        builder: (_, child) => Transform.scale(scale: _s.value, child: child),
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
                  fontSize: 10, fontWeight: FontWeight.w500)),
            ),
          ]),
        ),
      ),
    );
  }
}