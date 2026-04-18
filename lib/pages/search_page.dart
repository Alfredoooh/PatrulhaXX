import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'search_results_page.dart';
import 'home_page.dart' show iosRoute;

const _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

const _suggestions = [
  'amador português', 'milf', 'latina', 'caseiro', 'teen',
  'loira', 'morena', 'asiática', 'lésbicas', 'threesome',
  'maduro', 'college', 'office', 'massage', 'outdoor',
  'boquete', 'anal', 'gangbang', 'squirt', 'compilação',
];

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  bool get _hasQuery => _ctrl.text.trim().isNotEmpty;

  @override void initState() {
    super.initState();
    _ctrl.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _focus.requestFocus();
    });
  }

  @override void dispose() { _ctrl.dispose(); _focus.dispose(); super.dispose(); }

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.push(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _searchFor(String q) {
    FocusScope.of(context).unfocus();
    Navigator.push(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _showEngineSheet() {
    final t = AppTheme.current;
    showModalBottomSheet(
      context: context,
      backgroundColor: t.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: t.divider, borderRadius: BorderRadius.circular(100))),
          const SizedBox(height: 16),
          Text('Pesquisar com',
            style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFDE5833), shape: BoxShape.circle),
              child: const Center(child: Text('D',
                style: TextStyle(color: Colors.white,
                    fontSize: 15, fontWeight: FontWeight.w900)))),
            title: Text('DuckDuckGo',
              style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: Icon(Icons.check_rounded, color: AppTheme.ytRed, size: 20),
          ),
        ]),
      ));
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
            body: Column(children: [
              SizedBox(height: topPad + 10),

              // ── Search bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  // Ícone Google → sheet motor
                  GestureDetector(
                    onTap: _showEngineSheet,
                    child: Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.circular(10)),
                      child: Center(
                        child: SvgPicture.string(_googleSvg, width: 22, height: 22)),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Input
                  Expanded(
                    child: Container(
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
                        Expanded(
                          child: TextField(
                            controller: _ctrl,
                            focusNode: _focus,
                            style: TextStyle(color: t.inputText, fontSize: 15),
                            textInputAction: TextInputAction.search,
                            cursorColor: AppTheme.ytRed,
                            cursorWidth: 1.5,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Pesquisar...',
                              hintStyle: TextStyle(
                                  color: isDark ? Colors.white30 : Colors.black38,
                                  fontSize: 15),
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onSubmitted: (_) => _search(),
                          ),
                        ),
                        if (_hasQuery) ...[
                          GestureDetector(
                            onTap: () { _ctrl.clear(); setState(() {}); },
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Icon(Icons.close_rounded, size: 17,
                                  color: isDark ? Colors.white54 : Colors.black38))),
                        ] else
                          const SizedBox(width: 8),
                      ]),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Cancelar / Pesquisar
                  GestureDetector(
                    onTap: _hasQuery ? _search : () => Navigator.pop(context),
                    child: Text(
                      _hasQuery ? 'Pesquisar' : 'Cancelar',
                      style: TextStyle(
                        color: _hasQuery ? AppTheme.ytRed : t.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),

              const SizedBox(height: 20),

              // ── Sugestões ──
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Text('Sugestões',
                      style: TextStyle(color: t.textSecondary, fontSize: 12,
                          fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                    const SizedBox(height: 8),
                    _SuggestionList(
                      suggestions: _suggestions,
                      isDark: isDark,
                      divColor: t.divider,
                      textColor: t.text,
                      subColor: t.textSecondary,
                      onTap: _searchFor),
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

// ─── Lista de sugestões agrupada ──────────────────────────────────────────────
class _SuggestionList extends StatelessWidget {
  final List<String> suggestions;
  final bool isDark;
  final Color divColor, textColor, subColor;
  final void Function(String) onTap;

  const _SuggestionList({
    required this.suggestions,
    required this.isDark,
    required this.divColor,
    required this.textColor,
    required this.subColor,
    required this.onTap,
  });

  @override Widget build(BuildContext context) {
    return Column(
      children: suggestions.asMap().entries.map((e) {
        final i     = e.key;
        final s     = e.value;
        final first = i == 0;
        final last  = i == suggestions.length - 1;

        final radius = BorderRadius.only(
          topLeft:     Radius.circular(first ? 12 : 4),
          topRight:    Radius.circular(first ? 12 : 4),
          bottomLeft:  Radius.circular(last  ? 12 : 4),
          bottomRight: Radius.circular(last  ? 12 : 4),
        );

        return GestureDetector(
          onTap: () => onTap(s),
          child: Container(
            margin: EdgeInsets.only(bottom: last ? 0 : 1),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
              borderRadius: radius,
              border: Border(
                bottom: last
                    ? BorderSide.none
                    : BorderSide(color: divColor, width: 0.5)),
            ),
            child: Row(children: [
              Icon(Icons.search_rounded, size: 16,
                  color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 10),
              Expanded(child: Text(s,
                style: TextStyle(color: textColor, fontSize: 14,
                    fontWeight: FontWeight.w400))),
              Icon(Icons.north_west_rounded, size: 14,
                  color: isDark ? Colors.white24 : Colors.black26),
            ]),
          ),
        );
      }).toList(),
    );
  }
}