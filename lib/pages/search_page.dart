// search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'search_results_page.dart';
import 'home_page.dart' show iosRoute;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<String> _history = [];
  static const _kHistory = 'search_history_v3';

  static const _categories = [
    _Category(label: 'Heterossexual', color: Color(0xFF1a1a2e)),
    _Category(label: 'Homossexual',   color: Color(0xFF16213e)),
    _Category(label: 'Lésbicas',      color: Color(0xFF0f3460)),
    _Category(label: 'Anal',          color: Color(0xFF533483)),
    _Category(label: 'Amador',        color: Color(0xFF2d6a4f)),
    _Category(label: 'MILF',          color: Color(0xFF1b4332)),
  ];

  static const _colorChips = [
    (outer: Color(0xFFFFCDD2), inner: Color(0xFFE53935)),
    (outer: Color(0xFFFFF9C4), inner: Color(0xFFFDD835)),
    (outer: Color(0xFFE8EAF6), inner: Color(0xFF3949AB)),
    (outer: Color(0xFF424242), inner: Color(0xFF212121)),
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

  void _goToInput() =>
      Navigator.push(context, iosRoute(SearchResultsPage(query: '')));

  void _showPopup(BuildContext btnCtx, bool isDark) async {
    final popupBg = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final textCol = isDark ? Colors.white : Colors.black87;

    final RenderBox box = btnCtx.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(btnCtx).overlay!.context
        .findRenderObject() as RenderBox;
    final RelativeRect pos = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<String>(
      context: btnCtx,
      position: pos,
      color: popupBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(
          value: 'filmes',
          height: 46,
          child: Text('Filmes', style: TextStyle(color: textCol, fontSize: 14)),
        ),
        PopupMenuItem(
          value: 'meus_videos',
          height: 46,
          child: Text('Meus vídeos', style: TextStyle(color: textCol, fontSize: 14)),
        ),
        PopupMenuItem(
          value: 'shows',
          height: 46,
          child: Text('Shows', style: TextStyle(color: textCol, fontSize: 14)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t = AppTheme.current;
        final topPad = MediaQuery.of(context).padding.top;
        final isDark = t.statusBar == Brightness.light;

        final cardBg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
        final mutedIc = isDark ? Colors.white30 : Colors.black26;
        final divCol = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: t.bg,
            statusBarIconBrightness: t.statusBar,
          ),
          child: Scaffold(
            backgroundColor: t.bg,
            body: ListView(
              padding: EdgeInsets.only(
                top: topPad + 8,
                left: 16,
                right: 16,
                bottom: 40,
              ),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesquisa',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Builder(
                      builder: (btnCtx) => GestureDetector(
                        onTap: () => _showPopup(btnCtx, isDark),
                        child: Icon(Icons.more_vert, color: t.text, size: 22),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _goToInput,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 12),
                        Icon(
                          LucideIcons.search,
                          size: 16,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pesquisar...',
                          style: TextStyle(
                            color: isDark ? Colors.white30 : Colors.black38,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    itemCount: _colorChips.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) {
                      final chip = _colorChips[i];
                      return Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: chip.outer,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: chip.inner,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Categorias',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1.45,
                  ),
                  itemBuilder: (_, i) {
                    final cat = _categories[i];
                    return GestureDetector(
                      onTap: () => _goSearch(cat.label),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Container(color: cat.color),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.82),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 8,
                              right: 8,
                              bottom: 7,
                              child: Text(
                                cat.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black54,
                                    )
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
                const SizedBox(height: 28),
                if (_history.isNotEmpty) ...[
                  Row(
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
                  const SizedBox(height: 8),
                  _IosGroupedList(
                    bg: cardBg,
                    divColor: divCol,
                    mutedColor: mutedIc,
                    textColor: t.text,
                    items: _history,
                    onTap: _goSearch,
                    onRemove: _removeHistory,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _IosGroupedList extends StatelessWidget {
  final Color bg;
  final Color divColor;
  final Color mutedColor;
  final Color textColor;
  final List<String> items;
  final ValueChanged<String> onTap;
  final ValueChanged<String> onRemove;

  const _IosGroupedList({
    required this.bg,
    required this.divColor,
    required this.mutedColor,
    required this.textColor,
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
                ? const BorderRadius.only(
                    topLeft: big,
                    topRight: big,
                    bottomLeft: small,
                    bottomRight: small,
                  )
                : isLast
                    ? const BorderRadius.only(
                        topLeft: small,
                        topRight: small,
                        bottomLeft: big,
                        bottomRight: big,
                      )
                    : const BorderRadius.all(small);

        return Padding(
          padding: EdgeInsets.only(bottom: i == total - 1 ? 0 : 2),
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              color: bg,
              child: GestureDetector(
                onTap: () => onTap(label),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(
                    children: [
                      Icon(LucideIcons.clock3, size: 15, color: mutedColor),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => onRemove(label),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
                          child: Icon(LucideIcons.x, size: 13, color: mutedColor),
                        ),
                      ),
                    ],
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