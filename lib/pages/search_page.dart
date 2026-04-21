// search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'search_results_page.dart';
import 'browser_page.dart';
import '../models/site_model.dart';

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
      site: SiteModel(id: 'free', name: title, baseUrl: url, allowedDomain: '', searchUrl: url, primaryColor: kPrimaryColor),
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

  static const _categories = [
    _Category(label: 'Heterossexual', color: Color(0xFF1a1a2e)),
    _Category(label: 'Homossexual', color: Color(0xFF16213e)),
    _Category(label: 'Lésbicas', color: Color(0xFF0f3460)),
    _Category(label: 'Anal', color: Color(0xFF533483)),
    _Category(label: 'Amador', color: Color(0xFF2d6a4f)),
    _Category(label: 'MILF', color: Color(0xFF1b4332)),
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

  void _goSearch(String q) => Navigator.push(context, iosRoute(SearchResultsPage(query: q)));

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final cardBg = ThemeService.instance.isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
    final mutedIc = ThemeService.instance.isDark ? Colors.white30 : Colors.black26;

    return Scaffold(
      backgroundColor: t.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: t.bg,
            elevation: 0,
            title: GestureDetector(
              onTap: () {},
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: ThemeService.instance.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(LucideIcons.search, size: 16, color: ThemeService.instance.isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 8),
                    Text('Pesquisar...', style: TextStyle(color: ThemeService.instance.isDark ? Colors.white30 : Colors.black38, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: kSites.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final site = kSites[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, iosRoute(FreeBrowserPage(url: site.baseUrl, title: site.name))),
                      child: Column(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: site.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(child: Text(site.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          ),
                          const SizedBox(height: 6),
                          SizedBox(
                            width: 52,
                            child: Text(site.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: t.text, fontSize: 12, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
              child: Text('Categorias', style: TextStyle(color: t.text, fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.45,
              ),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat = _categories[i];
                final imageUrl = [
                  'https://picsum.photos/id/1015/200/200',
                  'https://picsum.photos/id/1020/200/200',
                  'https://picsum.photos/id/1033/200/200',
                  'https://picsum.photos/id/1041/200/200',
                  'https://picsum.photos/id/1050/200/200',
                  'https://picsum.photos/id/1062/200/200',
                ][i % 6];

                return GestureDetector(
                  onTap: () => _goSearch(cat.label),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(imageUrl, fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                            ),
                          ),
                        ),
                        Center(
                          child: Text(cat.label,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700, shadows: [Shadow(blurRadius: 4, color: Colors.black54)])),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_history.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Histórico', style: TextStyle(color: t.text, fontSize: 17, fontWeight: FontWeight.w700)),
                    GestureDetector(onTap: _clearHistory, child: Text('Limpar', style: TextStyle(color: AppTheme.ytRed, fontSize: 14, fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
            ),
          if (_history.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: _IosGroupedList(
                  bg: cardBg,
                  mutedColor: mutedIc,
                  textColor: t.text,
                  items: _history,
                  onTap: _goSearch,
                  onRemove: _removeHistory,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

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
        final i = e.key;
        final label = e.value;
        final isOnly = total == 1;
        final isFirst = i == 0;
        final isLast = i == total - 1;

        const big = Radius.circular(12);
        const small = Radius.circular(6);

        final BorderRadius radius = isOnly
            ? const BorderRadius.all(big)
            : isFirst
                ? const BorderRadius.only(topLeft: big, topRight: big, bottomLeft: small, bottomRight: small)
                : isLast
                    ? const BorderRadius.only(topLeft: small, topRight: small, bottomLeft: big, bottomRight: big)
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
            padding: EdgeInsets.only(bottom: isLast ? 0 : 2), // CORRIGIDO: removido const
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
                    child: Row(
                      children: [
                        Icon(LucideIcons.clock3, size: 16, color: mutedColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label, style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w400)),
                        ),
                      ],
                    ),
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

class _Category {
  final String label;
  final Color color;
  const _Category({required this.label, required this.color});
}