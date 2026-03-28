import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_theme.dart';
import 'search_results_page.dart';
import 'home_page.dart' show iosRoute;

// ─────────────────────────────────────────────────────────────────────────────
// SearchPage
// ─────────────────────────────────────────────────────────────────────────────
class SearchPage extends StatefulWidget {
  const SearchPage();
  @override
  State<SearchPage> createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {
  final _ctrl = TextEditingController();
  bool get _hasQuery => _ctrl.text.trim().isNotEmpty;

  static const _suggestions = [
    'amador português', 'milf', 'latina', 'caseiro', 'teen',
    'loira', 'morena', 'asiática', 'lésbicas', 'threesome',
    'maduro', 'college', 'office', 'massage', 'outdoor',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 320), () {
      if (mounted) FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  void _search() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context, iosRoute(SearchResultsPage(query: q)));
  }

  void _searchFor(String q) {
    _ctrl.text = q;
    setState(() {});
    FocusScope.of(context).unfocus();
    Navigator.pushReplacement(context, iosRoute(SearchResultsPage(query: q)));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(children: [
          SizedBox(height: topPad + 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: t.btnGhost,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      'assets/icons/svg/back_arrow.svg',
                      width: 18, height: 18,
                      colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: t.inputBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: t.inputBorder),
                  ),
                  child: Row(children: [
                    const SizedBox(width: 16),
                    SvgPicture.asset('assets/icons/svg/search.svg', width: 18, height: 18,
                        colorFilter: ColorFilter.mode(t.textSecondary, BlendMode.srcIn)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        autofocus: true,
                        style: TextStyle(color: t.inputText, fontSize: 15),
                        textInputAction: TextInputAction.search,
                        cursorColor: AppTheme.ytRed,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Pesquisar...',
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                    if (_hasQuery)
                      GestureDetector(
                        onTap: _search,
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.ytRed,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: const Text('Ir',
                              style: TextStyle(
                                  color: Colors.white, fontSize: 13,
                                  fontWeight: FontWeight.w700)),
                        ),
                      )
                    else
                      const SizedBox(width: 8),
                  ]),
                ),
              ),
            ]),
          ),

          const SizedBox(height: 20),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Text('Sugestões',
                    style: TextStyle(
                        color: t.textSecondary, fontSize: 12,
                        fontWeight: FontWeight.w600, letterSpacing: 0.3)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: _suggestions.map((s) => GestureDetector(
                    onTap: () => _searchFor(s),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: t.chipBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: t.borderSoft),
                      ),
                      child: Text(s,
                          style: TextStyle(
                              color: t.text, fontSize: 13,
                              fontWeight: FontWeight.w400)),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
