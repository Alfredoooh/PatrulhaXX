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

  static const _trending = [
    'milf', 'latina', 'amador', 'teen', 'loira',
    'lésbicas', 'asiática', 'boquete', 'caseiro', 'anal',
  ];

  // Categorias com cor de fundo fallback e label
  static const _categories = [
    _Category(label: 'Heterossexual', color: Color(0xFF1a1a2e)),
    _Category(label: 'Homossexual',   color: Color(0xFF16213e)),
    _Category(label: 'Lésbicas',      color: Color(0xFF0f3460)),
    _Category(label: 'Anal',          color: Color(0xFF533483)),
    _Category(label: 'Amador',        color: Color(0xFF2d6a4f)),
    _Category(label: 'MILF',          color: Color(0xFF1b4332)),
  ];

  @override void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _history = p.getStringList(_kHistory) ?? []);
  }

  Future<void> _removeHistory(String q) async {
    _history.remove(q); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
  }

  Future<void> _clearHistory() async {
    _history.clear(); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHistory);
  }

  void _goSearch(String q) =>
      Navigator.push(context, iosRoute(SearchResultsPage(query: q)));

  void _goToInput() =>
      Navigator.push(context, iosRoute(SearchResultsPage(query: '')));

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t      = AppTheme.current;
        final topPad = MediaQuery.of(context).padding.top;
        final isDark = t.statusBar == Brightness.light;

        final cardBg  = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF0F0F0);
        final divCol  = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
        final mutedIc = isDark ? Colors.white30          : Colors.black26;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: t.statusBar),
          child: Scaffold(
            backgroundColor: t.bg,
            body: ListView(
              padding: EdgeInsets.only(
                top: topPad + 8,
                left: 16, right: 16,
                bottom: 40),
              children: [

                // ── Título + menu ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pesquisa',
                      style: TextStyle(
                        color: t.text, fontSize: 22,
                        fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    Icon(LucideIcons.ellipsisVertical, color: t.text, size: 20),
                  ],
                ),

                const SizedBox(height: 14),

                // ── Input falso ──
                GestureDetector(
                  onTap: _goToInput,
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const SizedBox(width: 12),
                      Icon(LucideIcons.search, size: 16,
                          color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 8),
                      Text('Pesquisar...',
                        style: TextStyle(
                          color: isDark ? Colors.white30 : Colors.black38,
                          fontSize: 15)),
                    ]),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Chips de cor ──
                SizedBox(
                  height: 56,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none,
                    children: const [
                      _ColorChip(accent: Color(0xFFE53935), bg: Color(0xFFFFEBEE)),
                      _ColorChip(accent: Color(0xFFFDD835), bg: Color(0xFFFFFDE7)),
                      _ColorChip(accent: Color(0xFF3949AB), bg: Color(0xFFE8EAF6)),
                      _ColorChip(accent: Color(0xFF212121), bg: Color(0xFF424242)),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // ══ CATEGORIAS ══
                Text('Categorias',
                  style: TextStyle(
                    color: t.text, fontSize: 17,
                    fontWeight: FontWeight.w700)),

                const SizedBox(height: 12),

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
                            // fundo de cor sólida (substitui imagem)
                            Container(color: cat.color),
                            // gradiente escuro em baixo para o texto
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
                                    ]),
                                ),
                              ),
                            ),
                            // label
                            Positioned(
                              left: 8, right: 8, bottom: 7,
                              child: Text(cat.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(blurRadius: 4, color: Colors.black54)
                                  ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 28),

                // ══ HISTÓRICO ══
                if (_history.isNotEmpty) ...[
                  _SectionHeader(
                    label: 'Histórico',
                    isDark: isDark,
                    textColor: t.textSecondary,
                    action: GestureDetector(
                      onTap: _clearHistory,
                      child: Text('Limpar',
                        style: TextStyle(
                          color: AppTheme.ytRed,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500))),
                  ),
                  const SizedBox(height: 6),
                  _GroupedCard(
                    bg: cardBg,
                    divColor: divCol,
                    items: _history.asMap().entries.map((e) {
                      return _CardRow(
                        leading: Icon(LucideIcons.clock3, size: 15, color: mutedIc),
                        label: e.value,
                        labelColor: t.text,
                        trailing: GestureDetector(
                          onTap: () => _removeHistory(e.value),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 10, 0, 10),
                            child: Icon(LucideIcons.x, size: 13, color: mutedIc))),
                        onTap: () => _goSearch(e.value),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                ],

                // ══ TENDÊNCIAS ══
                _SectionHeader(
                  label: 'Tendências',
                  isDark: isDark,
                  textColor: t.textSecondary,
                ),
                const SizedBox(height: 6),
                _GroupedCard(
                  bg: cardBg,
                  divColor: divCol,
                  items: _trending.asMap().entries.map((e) {
                    return _CardRow(
                      leading: Icon(LucideIcons.trendingUp, size: 15,
                          color: AppTheme.ytRed),
                      label: e.value,
                      labelColor: t.text,
                      trailing: Icon(LucideIcons.arrowUpLeft, size: 13,
                          color: mutedIc),
                      onTap: () => _goSearch(e.value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Modelo de categoria ──────────────────────────────────────────────────────

class _Category {
  final String label;
  final Color color;
  const _Category({required this.label, required this.color});
}

// ─── Chip de cor (filtros horizontais) ───────────────────────────────────────

class _ColorChip extends StatelessWidget {
  final Color accent;
  final Color bg;
  const _ColorChip({required this.accent, required this.bg});

  @override Widget build(BuildContext context) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10)),
      child: Center(
        child: Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(6)),
        ),
      ),
    );
  }
}

// ─── Cabeçalho de secção ──────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color textColor;
  final Widget? action;

  const _SectionHeader({
    required this.label,
    required this.isDark,
    required this.textColor,
    this.action,
  });

  @override Widget build(BuildContext context) => Row(
    children: [
      Text(label.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9)),
      const Spacer(),
      if (action != null) action!,
    ],
  );
}

// ─── Card agrupado com cantos redondos ────────────────────────────────────────

class _GroupedCard extends StatelessWidget {
  final Color bg;
  final Color divColor;
  final List<_CardRow> items;

  const _GroupedCard({
    required this.bg,
    required this.divColor,
    required this.items,
  });

  @override Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: bg,
        child: Column(
          children: items.asMap().entries.map((e) {
            final isLast = e.key == items.length - 1;
            final row = e.value;
            return Column(
              children: [
                _RowTile(row: row),
                if (!isLast)
                  Divider(
                    height: 0,
                    thickness: 0.4,
                    indent: 42,
                    color: divColor),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Modelo de row ────────────────────────────────────────────────────────────

class _CardRow {
  final Widget leading;
  final String label;
  final Color labelColor;
  final Widget trailing;
  final VoidCallback onTap;

  const _CardRow({
    required this.leading,
    required this.label,
    required this.labelColor,
    required this.trailing,
    required this.onTap,
  });
}

// ─── Row tile ─────────────────────────────────────────────────────────────────

class _RowTile extends StatelessWidget {
  final _CardRow row;
  const _RowTile({required this.row});

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: row.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          row.leading,
          const SizedBox(width: 11),
          Expanded(
            child: Text(row.label,
              style: TextStyle(
                color: row.labelColor,
                fontSize: 14,
                fontWeight: FontWeight.w400))),
          row.trailing,
        ]),
      ),
    );
  }
}