// search_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  void _goSearch(String q) {
    Navigator.push(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _goToInput() {
    Navigator.push(context, iosRoute(SearchResultsPage(query: '')));
  }

  @override Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (_, __) {
        final t      = AppTheme.current;
        final topPad = MediaQuery.of(context).padding.top;
        final isDark = t.statusBar == Brightness.light;

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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text('Pesquisa',
                  style: TextStyle(color: t.text, fontSize: 22,
                      fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              ),

              // ── Input falso — ao tocar vai para SearchResultsPage ──
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
                    Icon(Icons.search_rounded, size: 18,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 8),
                    Text('Pesquisar...',
                      style: TextStyle(
                        color: isDark ? Colors.white30 : Colors.black38,
                        fontSize: 15)),
                  ]),
                ),
              ),

              const SizedBox(height: 24),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [

                    // ── Histórico ──
                    if (_history.isNotEmpty) ...[
                      Row(children: [
                        Text('Recentes',
                          style: TextStyle(color: t.textSecondary, fontSize: 12,
                              fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                        const Spacer(),
                        GestureDetector(
                          onTap: _clearHistory,
                          child: Text('Limpar',
                            style: TextStyle(color: AppTheme.ytRed, fontSize: 12,
                                fontWeight: FontWeight.w600))),
                      ]),
                      const SizedBox(height: 8),
                      ..._history.asMap().entries.map((e) {
                        final i     = e.key;
                        final s     = e.value;
                        final first = i == 0;
                        final last  = i == _history.length - 1;
                        return GestureDetector(
                          onTap: () => _goSearch(s),
                          child: Container(
                            margin: EdgeInsets.only(bottom: last ? 0 : 1),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1E1E1E)
                                  : const Color(0xFFF7F7F7),
                              borderRadius: BorderRadius.only(
                                topLeft:     Radius.circular(first ? 12 : 4),
                                topRight:    Radius.circular(first ? 12 : 4),
                                bottomLeft:  Radius.circular(last  ? 12 : 4),
                                bottomRight: Radius.circular(last  ? 12 : 4)),
                              border: Border(bottom: last
                                  ? BorderSide.none
                                  : BorderSide(color: t.divider, width: 0.5))),
                            child: Row(children: [
                              Icon(Icons.history_rounded, size: 16,
                                  color: isDark ? Colors.white38 : Colors.black38),
                              const SizedBox(width: 10),
                              Expanded(child: Text(s,
                                style: TextStyle(color: t.text, fontSize: 14))),
                              GestureDetector(
                                onTap: () => _removeHistory(s),
                                behavior: HitTestBehavior.opaque,
                                child: Icon(Icons.close_rounded, size: 14,
                                    color: isDark ? Colors.white30 : Colors.black26)),
                            ]),
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // ── Tendências ──
                    Text('Tendências',
                      style: TextStyle(color: t.textSecondary, fontSize: 12,
                          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(height: 8),
                    ..._trending.asMap().entries.map((e) {
                      final i     = e.key;
                      final s     = e.value;
                      final first = i == 0;
                      final last  = i == _trending.length - 1;
                      return GestureDetector(
                        onTap: () => _goSearch(s),
                        child: Container(
                          margin: EdgeInsets.only(bottom: last ? 0 : 1),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.only(
                              topLeft:     Radius.circular(first ? 12 : 4),
                              topRight:    Radius.circular(first ? 12 : 4),
                              bottomLeft:  Radius.circular(last  ? 12 : 4),
                              bottomRight: Radius.circular(last  ? 12 : 4)),
                            border: Border(bottom: last
                                ? BorderSide.none
                                : BorderSide(color: t.divider, width: 0.5))),
                          child: Row(children: [
                            Icon(Icons.local_fire_department_rounded, size: 16,
                                color: AppTheme.ytRed),
                            const SizedBox(width: 10),
                            Expanded(child: Text(s,
                              style: TextStyle(color: t.text, fontSize: 14))),
                            Icon(Icons.north_west_rounded, size: 14,
                                color: isDark ? Colors.white24 : Colors.black26),
                          ]),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
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