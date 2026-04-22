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
        id: 'free',
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

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> _history = [];
  static const _kHistory = 'search_history_v3';

  // Imagens neutras/abstratas que combinam visualmente com cada categoria
  static const _categories = [
    _Category(
      label: 'Heterossexual',
      imageUrl: 'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=400&q=80',
    ),
    _Category(
      label: 'Homossexual',
      imageUrl: 'https://images.unsplash.com/photo-1502082553048-f009c37129b9?w=400&q=80',
    ),
    _Category(
      label: 'Lésbicas',
      imageUrl: 'https://images.unsplash.com/photo-1490750967868-88df5691cc8d?w=400&q=80',
    ),
    _Category(
      label: 'Anal',
      imageUrl: 'https://images.unsplash.com/photo-1528360983277-13d401cdc186?w=400&q=80',
    ),
    _Category(
      label: 'Amador',
      imageUrl: 'https://images.unsplash.com/photo-1464820453369-31d2c0b651af?w=400&q=80',
    ),
    _Category(
      label: 'MILF',
      imageUrl: 'https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=400&q=80',
    ),
    _Category(
      label: 'Teen',
      imageUrl: 'https://images.unsplash.com/photo-1523049673857-eb18f1d7b578?w=400&q=80',
    ),
    _Category(
      label: 'Hentai',
      imageUrl: 'https://images.unsplash.com/photo-1542831371-29b0f74f9713?w=400&q=80',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

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
        final t       = AppTheme.current;
        final isDark  = ThemeService.instance.isDark;
        final cardBg  = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
        final mutedIc = isDark ? Colors.white30 : Colors.black26;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: t.statusBar,
          ),
          child: Scaffold(
            backgroundColor: t.bg,
            // ── AppBar fixo — não sobe ao deslizar ───────────────────────
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // AppBar sempre fixo no topo
                Container(
                  color: t.appBar,
                  padding: EdgeInsets.only(
                    top: topPad + 8,
                    left: 16,
                    right: 16,
                    bottom: 10,
                  ),
                  child: Row(
                    children: [
                      // Título à esquerda
                      Text(
                        'Pesquisar',
                        style: TextStyle(
                          color: t.text,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Input mais curto — ocupa o espaço restante
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
                              Icon(Icons.search, size: 16,
                                  color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 6),
                              Text(
                                'Pesquisar...',
                                style: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.black38,
                                  fontSize: 14,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Conteúdo scrollável
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [

                      const SizedBox(height: 16),

                      // ── Sites ───────────────────────────────────────────
                      SizedBox(
                        height: 88,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: kSites.length,
                          itemBuilder: (_, i) => _SiteCell(
                            site: kSites[i],
                            onTap: () => Navigator.push(
                              context,
                              iosRoute(FreeBrowserPage(
                                url: kSites[i].baseUrl,
                                title: kSites[i].name,
                              )),
                            ),
                          ),
                        ),
                      ),

                      // ── Categorias ──────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                        child: Text(
                          'Categorias',
                          style: TextStyle(
                            color: t.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.55,
                          ),
                          itemCount: _categories.length,
                          itemBuilder: (_, i) {
                            final cat = _categories[i];
                            return GestureDetector(
                              onTap: () => _goSearch(cat.label),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      cat.imageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: isDark
                                            ? const Color(0xFF1E1E1E)
                                            : const Color(0xFFEEEEEE),
                                      ),
                                    ),
                                    // Gradiente escuro por baixo do texto
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withOpacity(0.65),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Texto no canto inferior esquerdo
                                    Positioned(
                                      left: 10,
                                      bottom: 8,
                                      right: 10,
                                      child: Text(
                                        cat.label,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          shadows: [
                                            Shadow(
                                              blurRadius: 6,
                                              color: Colors.black54,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // ── Histórico ───────────────────────────────────────
                      if (_history.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Histórico',
                                style: TextStyle(
                                  color: t.text,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              GestureDetector(
                                onTap: _clearHistory,
                                child: Text(
                                  'Limpar',
                                  style: TextStyle(
                                    color: AppTheme.ytRed,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _IosGroupedList(
                            bg: cardBg,
                            mutedColor: mutedIc,
                            textColor: t.text,
                            items: _history,
                            onTap: _goSearch,
                            onRemove: _removeHistory,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
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

// ─── _SiteCell ────────────────────────────────────────────────────────────────
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
      upperBound: 1,
    );
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
    const double iconSize = 52;
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
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
              child: Text(
                widget.site.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.current.iconSub,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── _IosGroupedList — sem X, só swipe para remover ──────────────────────────
class _IosGroupedList extends StatelessWidget {
  final Color bg;
  final Color textColor;
  final Color mutedColor;
  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;

  const _IosGroupedList({
    required this.bg,
    required this.textColor,
    required this.mutedColor,
    required this.items,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.length;

    return Column(
      children: items.asMap().entries.map((e) {
        final i     = e.key;
        final label = e.value;
        final isOnly  = total == 1;
        final isFirst = i == 0;
        final isLast  = i == total - 1;

        const big   = Radius.circular(12);
        const small = Radius.circular(6);

        final BorderRadius radius = isOnly
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

        return Dismissible(
          key: ValueKey(label),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onRemove(label),
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white, size: 20),
          ),
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 2),
            child: ClipRRect(
              borderRadius: radius,
              child: Container(
                color: bg,
                height: 58,
                child: GestureDetector(
                  onTap: () => onTap(label),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(children: [
                      Icon(Icons.access_time, size: 16, color: mutedColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── _Category ────────────────────────────────────────────────────────────────
class _Category {
  final String label;
  final String imageUrl;
  const _Category({required this.label, required this.imageUrl});
}