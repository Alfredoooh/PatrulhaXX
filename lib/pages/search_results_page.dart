// search_results_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'home_page.dart' show iosRoute;
import '../models/site_model.dart';
import '../models/feed_video_model.dart';
import 'browser_page.dart';

// Ícone back
const _iBack = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

// Enum tabs
enum _WebTab { tudo, imagens, videos }

// Plataformas multi-vídeo (excluindo Xvideos)
final kVideoSites = <SiteModel>[
  SiteModel(id: 'pornhub', name: 'Pornhub', baseUrl: 'https://www.pornhub.com', allowedDomain: 'pornhub.com', searchUrl: 'https://www.pornhub.com/video/search?search=', primaryColor: const Color(0xFFFF9000)),
  SiteModel(id: 'redtube', name: 'RedTube', baseUrl: 'https://www.redtube.com', allowedDomain: 'redtube.com', searchUrl: 'https://www.redtube.com/?search=', primaryColor: const Color(0xFFD40000)),
  SiteModel(id: 'youporn', name: 'YouPorn', baseUrl: 'https://www.youporn.com', allowedDomain: 'youporn.com', searchUrl: 'https://www.youporn.com/search/video/?query=', primaryColor: const Color(0xFF0D0D0D)),
];

// Página principal de resultados de pesquisa
class SearchResultsPage extends StatefulWidget {
  final void Function(FeedVideo)? onVideoTap;
  final String? query;
  const SearchResultsPage({super.key, this.query, this.onVideoTap});
  @override State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  late final TextEditingController _q;
  final _focus = FocusNode();

  bool _searching = false;
  bool _editingQuery = false;

  List<String> _suggestions = [];
  List<String> _history = [];
  static const _kHistory = 'search_history_v3';

  _WebTab _activeTab = _WebTab.tudo;

  final Map<_WebTab, InAppWebViewController?> _webCtrls = {for (final t in _WebTab.values) t: null};
  final Map<_WebTab, bool> _webLoading = {for (final t in _WebTab.values) t: false};

  @override
  void initState() {
    super.initState();
    _q = TextEditingController(text: widget.query ?? '');
    _q.addListener(_onTyping);
    _loadHistory();
    if ((widget.query ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(widget.query!));
    }
  }

  @override
  void dispose() {
    _q.removeListener(_onTyping);
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _history = p.getStringList(_kHistory) ?? []);
  }

  Future<void> _saveHistory(String q) async {
    if (q.isEmpty) return;
    _history.remove(q);
    _history.insert(0, q);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
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

  void _onTyping() {
    setState(() {});
    final q = _q.text.trim();
    if (q.length >= 2) _fetchSuggestions(q);
    else setState(() => _suggestions = []);
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      final uri = Uri.parse('https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeComponent(q)}');
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (!mounted) return;
      final data = jsonDecode(r.body);
      setState(() => _suggestions = (data[1] as List).map((e) => e.toString()).take(7).toList());
    } catch (_) {}
  }

  Future<void> _doSearch(String q) async {
    q = q.trim(); if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
    await _saveHistory(q);

    setState(() {
      _searching = true;
      _editingQuery = false;
      _suggestions = [];
      _activeTab = _WebTab.tudo;
    });
  }

  void _activateEditing() {
    setState(() => _editingQuery = true);
    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) _focus.requestFocus();
    });
  }

  void _clearSearch() {
    _q.clear();
    setState(() {
      _searching = false;
      _editingQuery = false;
      _suggestions = [];
    });
    _focus.requestFocus();
  }

  Future<bool> _onWillPop() async {
    return true;
  }

  void _goBack() => Navigator.pop(context);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;
    final showEditable = !_searching || _editingQuery;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(
          children: [

            // AppBar fixo
            Container(
              color: t.appBar,
              child: Column(children: [
                SizedBox(height: topPad),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(children: [
                    GestureDetector(
                      onTap: _goBack,
                      behavior: HitTestBehavior.opaque,
                      child: SvgPicture.string(_iBack, width: 20, height: 20, colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: !showEditable ? _activateEditing : null,
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(children: [
                            const SizedBox(width: 10),
                            Icon(LucideIcons.search, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                            const SizedBox(width: 7),
                            if (!showEditable)
                              Text(_q.text, style: TextStyle(color: t.inputText, fontSize: 14))
                            else
                              Expanded(
                                child: TextField(
                                  controller: _q,
                                  focusNode: _focus,
                                  autofocus: !_searching,
                                  style: TextStyle(color: t.inputText, fontSize: 14),
                                  textInputAction: TextInputAction.search,
                                  cursorColor: AppTheme.ytRed,
                                  onSubmitted: (_) {},
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Pesquisar...', isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                                ),
                              ),
                          ]),
                        ),
                      ),
                    ),
                  ]),
                ),
                Divider(height: 1, color: t.divider),
              ]),
            ),

            // Corpo
            Expanded(
              child: showEditable
                  ? _HistorySuggestionsView(
                      history: _history,
                      onSelect: (q) => Navigator.push(context, iosRoute(FreeBrowserPage(url: 'https://duckduckgo.com/?q=$q', title: q))),
                      onRemove: _removeHistory,
                      onClear: _clearHistory,
                    )
                  : _VideoCardsView(
                      sites: kVideoSites,
                      onTap: (site) => Navigator.push(context, iosRoute(FreeBrowserPage(url: site.baseUrl, title: site.name))),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// Histórico com cards maiores, swipe para remover
class _HistorySuggestionsView extends StatelessWidget {
  final List<String> history;
  final void Function(String) onSelect;
  final void Function(String) onRemove;
  final VoidCallback onClear;
  const _HistorySuggestionsView({required this.history, required this.onSelect, required this.onRemove, required this.onClear});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final item = history[i];
        return Dismissible(
          key: ValueKey(item),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onRemove(item),
          background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.white)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Container(
              height: 56,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: AppTheme.current.cardBg),
              child: InkWell(
                onTap: () => onSelect(item),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Icon(LucideIcons.clock3, size: 16, color: AppTheme.current.iconSub),
                      const SizedBox(width: 12),
                      Expanded(child: Text(item, style: TextStyle(color: AppTheme.current.text, fontSize: 15))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Grid de vídeos multi-plataforma
class _VideoCardsView extends StatelessWidget {
  final List<SiteModel> sites;
  final void Function(SiteModel) onTap;
  const _VideoCardsView({required this.sites, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sites.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 1.1),
      itemBuilder: (_, i) {
        final site = sites[i];
        return InkWell(
          onTap: () => onTap(site),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(color: site.primaryColor, borderRadius: BorderRadius.circular(10)),
            child: Center(child: Text(site.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ),
        );
      },
    );
  }
}

// Navegador interno do app
class FreeBrowserPage extends StatelessWidget {
  final String url, title;
  const FreeBrowserPage({super.key, required this.url, required this.title});

  @override
  Widget build(BuildContext context) {
    return BrowserPage(
      site: SiteModel(id: 'free', name: title, baseUrl: url, allowedDomain: '', searchUrl: url, primaryColor: AppTheme.ytRed),
      freeNavigation: true,
    );
  }
}