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

        final subColor  = isDark ? Colors.white38 : Colors.black38;
        final rowBg     = isDark ? const Color(0xFF161616) : const Color(0xFFF5F5F5);
        final divColor  = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE8E8E8);

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: t.statusBar),
          child: Scaffold(
            backgroundColor: t.bg,
            body: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(height: topPad + 8),

              // ── Título ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Text('Pesquisa',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5)),
              ),

              // ── Input falso (intocável) ──
              GestureDetector(
                onTap: _goToInput,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFF2F2F2),
                    borderRadius: BorderRadius.circular(10)),
                  child: Row(children: [
                    const SizedBox(width: 12),
                    Icon(LucideIcons.search, size: 16, color: subColor),
                    const SizedBox(width: 8),
                    Text('Pesquisar...',
                      style: TextStyle(
                        color: subColor,
                        fontSize: 15)),
                  ]),
                ),
              ),

              const SizedBox(height: 28),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [

                    // ── Histórico ──
                    if (_history.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                        child: Row(children: [
                          Text('Recentes',
                            style: TextStyle(
                              color: t.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.6)),
                          const Spacer(),
                          GestureDetector(
                            onTap: _clearHistory,
                            child: Text('Limpar tudo',
                              style: TextStyle(
                                color: AppTheme.ytRed,
                                fontSize: 12,
                                fontWeight: FontWeight.w500))),
                        ]),
                      ),

                      Container(
                        color: rowBg,
                        child: Column(
                          children: _history.asMap().entries.map((e) {
                            final isLast = e.key == _history.length - 1;
                            return _RowItem(
                              label: e.value,
                              leading: Icon(LucideIcons.clock3, size: 15, color: subColor),
                              trailing: GestureDetector(
                                onTap: () => _removeHistory(e.value),
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(LucideIcons.x, size: 13, color: subColor),
                                ),
                              ),
                              divColor: isLast ? Colors.transparent : divColor,
                              textColor: t.text,
                              onTap: () => _goSearch(e.value),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 28),
                    ],

                    // ── Tendências ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Text('Tendências',
                        style: TextStyle(
                          color: t.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6)),
                    ),

                    Container(
                      color: rowBg,
                      child: Column(
                        children: _trending.asMap().entries.map((e) {
                          final isLast = e.key == _trending.length - 1;
                          return _RowItem(
                            label: e.value,
                            leading: Icon(LucideIcons.trendingUp, size: 15,
                                color: AppTheme.ytRed),
                            trailing: Icon(LucideIcons.arrowUpLeft, size: 13,
                                color: subColor),
                            divColor: isLast ? Colors.transparent : divColor,
                            textColor: t.text,
                            onTap: () => _goSearch(e.value),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Row reutilizável ─────────────────────────────────────────────────────────

class _RowItem extends StatelessWidget {
  final String label;
  final Widget leading;
  final Widget trailing;
  final Color divColor;
  final Color textColor;
  final VoidCallback onTap;

  const _RowItem({
    required this.label,
    required this.leading,
    required this.trailing,
    required this.divColor,
    required this.textColor,
    required this.onTap,
  });

  @override Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(children: [
              leading,
              const SizedBox(width: 12),
              Expanded(
                child: Text(label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w400)),
              ),
              trailing,
            ]),
          ),
          if (divColor != Colors.transparent)
            Divider(
              height: 0,
              thickness: 0.5,
              indent: 16 + 15 + 12, // alinha com o texto
              color: divColor),
        ],
      ),
    );
  }
}