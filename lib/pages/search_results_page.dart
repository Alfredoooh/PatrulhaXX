import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'home_page.dart' show iosRoute;

const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

// CSS injected — oculta header DDG e scrollbar nativo
const _ddgCss = '''
(function() {
  if (window.__ddgCssInjected) return;
  window.__ddgCssInjected = true;
  const s = document.createElement('style');
  s.textContent = `
    #header_wrapper, #header, .header--aside,
    .js-header-wrapper, .nav-menu, #duckbar,
    [class*="Header"], [id*="header"] { display: none !important; }
    ::-webkit-scrollbar { display: none !important; width: 0 !important; }
  `;
  document.head.appendChild(s);
})();
''';

// Apenas 3 tabs — sem notícias nem mapas
enum _WebTab { tudo, imagens, videos }

extension _WebTabX on _WebTab {
  String get label {
    switch (this) {
      case _WebTab.tudo:    return 'Tudo';
      case _WebTab.imagens: return 'Imagens';
      case _WebTab.videos:  return 'Vídeos';
    }
  }

  // kp=-2 = safe search off, &t=h_ = sem tracking
  // Para vídeos: força pesquisa em sites adultos conhecidos
  String url(String q) {
    final enc = Uri.encodeComponent(q);
    switch (this) {
      case _WebTab.tudo:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&ia=web&kaj=m';
      case _WebTab.imagens:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&iax=images&ia=images&kaj=m';
      case _WebTab.videos:
        // Pesquisa no xvideos directamente para resultados garantidamente adultos
        return 'https://www.xvideos.com/?k=${Uri.encodeComponent(q)}';
    }
  }
}

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

  bool _searching    = false;
  bool _editingQuery = false;

  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  _WebTab _activeTab = _WebTab.tudo;

  final Map<_WebTab, InAppWebViewController?> _webCtrls = {
    for (final t in _WebTab.values) t: null,
  };
  final Map<_WebTab, bool> _webLoading = {
    for (final t in _WebTab.values) t: false,
  };

  @override void initState() {
    super.initState();
    _q = TextEditingController(text: widget.query ?? '');
    _q.addListener(_onTyping);
    _loadHistory();
    if ((widget.query ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(widget.query!));
    }
  }

  @override void dispose() {
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
    _history.remove(q); _history.insert(0, q);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
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

  void _onTyping() {
    setState(() {});
    final q = _q.text.trim();
    if (q.length >= 2) _fetchSuggestions(q);
    else setState(() => _suggestions = []);
  }

  Future<void> _fetchSuggestions(String q) async {
    try {
      final uri = Uri.parse(
          'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeComponent(q)}');
      final r = await http.get(uri).timeout(const Duration(seconds: 4));
      if (!mounted) return;
      final data = jsonDecode(r.body);
      setState(() => _suggestions =
          (data[1] as List).map((e) => e.toString()).take(7).toList());
    } catch (_) {}
  }

  Future<void> _doSearch(String q) async {
    q = q.trim(); if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
    await _saveHistory(q);

    setState(() {
      _searching    = true;
      _editingQuery = false;
      _suggestions  = [];
      _activeTab    = _WebTab.tudo;
    });

    // Carrega TODOS os tabs de uma vez — sem lazy loading
    for (final tab in _WebTab.values) {
      final ctrl = _webCtrls[tab];
      if (ctrl != null) {
        ctrl.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url(q))));
      }
    }
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
      _searching    = false;
      _editingQuery = false;
      _suggestions  = [];
    });
    _focus.requestFocus();
  }

  Future<bool> _onWillPop() async {
    if (_searching) {
      final ctrl = _webCtrls[_activeTab];
      if (ctrl != null && await ctrl.canGoBack()) {
        await ctrl.goBack();
        return false;
      }
    }
    return true;
  }

  // Volta à tela anterior — não ao SearchPage
  void _goBack() => Navigator.pop(context);

  void _switchTab(_WebTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.of(context).padding.top;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (_, __) {
          final t      = AppTheme.current;
          final isDark = t.statusBar == Brightness.light;
          final showEditable = !_searching || _editingQuery;

          return AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: t.statusBar),
            child: Scaffold(
              backgroundColor: t.bg,
              resizeToAvoidBottomInset: false,
              body: Column(children: [

                // ── AppBar ────────────────────────────────────────────────────
                Container(
                  color: t.appBar,
                  child: Column(children: [
                    SizedBox(height: topPad),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                      child: Row(children: [
                        // Back — vai à tela anterior
                        GestureDetector(
                          onTap: _goBack,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            child: SvgPicture.string(_iBack,
                                width: 20, height: 20,
                                colorFilter: ColorFilter.mode(
                                    t.icon, BlendMode.srcIn)),
                          ),
                        ),

                        // Input
                        Expanded(
                          child: GestureDetector(
                            onTap: !showEditable ? _activateEditing : null,
                            child: Container(
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFEFEFEF),
                                borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const SizedBox(width: 10),
                                Icon(LucideIcons.search, size: 16,
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38),
                                const SizedBox(width: 7),
                                if (!showEditable)
                                  Expanded(
                                    child: Text(_q.text,
                                      style: TextStyle(
                                          color: t.inputText,
                                          fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis))
                                else
                                  Expanded(
                                    child: TextField(
                                      controller: _q,
                                      focusNode: _focus,
                                      autofocus: !_searching,
                                      style: TextStyle(
                                          color: t.inputText, fontSize: 14),
                                      textInputAction: TextInputAction.search,
                                      cursorColor: AppTheme.ytRed,
                                      cursorWidth: 1.5,
                                      onSubmitted: _doSearch,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Pesquisar...',
                                        hintStyle: TextStyle(
                                            color: isDark
                                                ? Colors.white30
                                                : Colors.black38,
                                            fontSize: 14),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 10)),
                                    )),
                                if (_q.text.isNotEmpty && showEditable)
                                  GestureDetector(
                                    onTap: _clearSearch,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Icon(LucideIcons.x,
                                          size: 15,
                                          color: isDark
                                              ? Colors.white54
                                              : Colors.black38)))
                                else
                                  const SizedBox(width: 8),
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    // ── Tabs ─────────────────────────────────────────────────
                    if (_searching && !_editingQuery)
                      SizedBox(
                        height: 34,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                          children: _WebTab.values.map((tab) {
                            final active = _activeTab == tab;
                            return GestureDetector(
                              onTap: () => _switchTab(tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12),
                                decoration: BoxDecoration(
                                  color: active
                                      ? (isDark
                                          ? Colors.white
                                          : Colors.black)
                                      : (isDark
                                          ? const Color(0xFF2A2A2A)
                                          : const Color(0xFFEEEEEE)),
                                  borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    color: active
                                        ? (isDark
                                            ? Colors.black
                                            : Colors.white)
                                        : (isDark
                                            ? Colors.white70
                                            : Colors.black54),
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500),
                                  child: Text(tab.label))));
                          }).toList(),
                        ),
                      ),

                    Divider(height: 1, color: t.divider),
                  ]),
                ),

                // ── Corpo ─────────────────────────────────────────────────────
                Expanded(
                  child: showEditable
                      ? _SuggestionsView(
                          query: _q.text.trim(),
                          history: _history,
                          suggestions: _suggestions,
                          textColor: t.text,
                          subColor: t.textSecondary,
                          divColor: t.divider,
                          onSelect: _doSearch,
                          onFill: (q) {
                            _q.text = q;
                            _q.selection = TextSelection.collapsed(
                                offset: q.length);
                          },
                          onRemoveHistory: _removeHistory,
                          onClearHistory: _clearHistory,
                        )
                      : _buildWebViews(isDark, t.bg),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWebViews(bool isDark, Color bg) {
    return Stack(
      children: _WebTab.values.map((tab) => Offstage(
        offstage: tab != _activeTab,
        child: _WebPane(
          key: ValueKey(tab),
          tab: tab,
          query: _q.text.trim(),
          isDark: isDark,
          bg: bg,
          loading: _webLoading[tab] ?? false,
          onCreated: (ctrl) => _webCtrls[tab] = ctrl,
          onLoadStart: () {
            if (mounted) setState(() => _webLoading[tab] = true);
          },
          onLoadStop: (ctrl) async {
            await ctrl.evaluateJavascript(source: _ddgCss);
            if (mounted) setState(() => _webLoading[tab] = false);
          },
        ),
      )).toList(),
    );
  }
}

// ─── WebPane ──────────────────────────────────────────────────────────────────

class _WebPane extends StatelessWidget {
  final _WebTab tab;
  final String query;
  final bool isDark, loading;
  final Color bg;
  final void Function(InAppWebViewController) onCreated;
  final VoidCallback onLoadStart;
  final void Function(InAppWebViewController) onLoadStop;

  const _WebPane({
    super.key,
    required this.tab,
    required this.query,
    required this.isDark,
    required this.loading,
    required this.bg,
    required this.onCreated,
    required this.onLoadStart,
    required this.onLoadStop,
  });

  @override Widget build(BuildContext context) {
    return Stack(children: [
      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(tab.url(query))),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
          // Fundo explícito — elimina linha branca lateral e inferior
          transparentBackground: false,
          supportZoom: false,
          verticalScrollBarEnabled: false,
          horizontalScrollBarEnabled: false,
        ),
        // Cor de fundo do WebView igual ao tema — sem bordas brancas
        backgroundColor: bg,
        onWebViewCreated: onCreated,
        onLoadStart: (_, __) => onLoadStart(),
        onLoadStop: (ctrl, __) => onLoadStop(ctrl),
        onReceivedError: (_, __, ___) {
          if (loading) onLoadStart();
        },
      ),

      if (loading)
        Positioned(
          top: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            color: AppTheme.ytRed,
            minHeight: 2)),
    ]);
  }
}

// ─── SuggestionsView ──────────────────────────────────────────────────────────

class _SuggestionsView extends StatelessWidget {
  final String query;
  final List<String> history, suggestions;
  final Color textColor, subColor, divColor;
  final void Function(String) onSelect, onFill, onRemoveHistory;
  final VoidCallback onClearHistory;

  const _SuggestionsView({
    required this.query, required this.history, required this.suggestions,
    required this.textColor, required this.subColor, required this.divColor,
    required this.onSelect, required this.onFill,
    required this.onRemoveHistory, required this.onClearHistory,
  });

  @override Widget build(BuildContext context) {
    final showSuggestions = query.length >= 2 && suggestions.isNotEmpty;
    final items = showSuggestions ? suggestions : history;

    if (items.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(LucideIcons.search,
            color: subColor.withOpacity(0.25), size: 48),
        const SizedBox(height: 14),
        Text('Pesquisa algo',
            style: TextStyle(color: subColor, fontSize: 14)),
      ]));
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (!showSuggestions && history.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
            child: Row(children: [
              Text('Pesquisas recentes',
                  style: TextStyle(color: subColor,
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton(
                onPressed: onClearHistory,
                child: Text('Limpar tudo',
                    style: TextStyle(color: AppTheme.ytRed,
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ...items.map((item) => Column(children: [
          InkWell(
            onTap: () => onSelect(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(children: [
                Icon(
                  showSuggestions ? LucideIcons.search : LucideIcons.clock3,
                  color: subColor, size: 17),
                const SizedBox(width: 14),
                Expanded(child: Text(item,
                    style: TextStyle(color: textColor, fontSize: 14.5))),
                GestureDetector(
                  onTap: () => showSuggestions
                      ? onFill(item) : onRemoveHistory(item),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      showSuggestions
                          ? LucideIcons.arrowUpLeft
                          : LucideIcons.x,
                      color: subColor, size: 16)),
                ),
              ]),
            ),
          ),
          Divider(height: 1, color: divColor, indent: 47),
        ])),
      ],
    );
  }
}