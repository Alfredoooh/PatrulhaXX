import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import '../services/theme_service.dart';
import 'home_page.dart' show iosRoute;
import 'search_page.dart';

const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

const _iHistory =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">'
    '<path d="M256,80C159.9,80,80,159.9,80,256s79.9,176,176,176s176-79.9,176-176'
    'C432,159.9,352.1,80,256,80z M256,400c-79.4,0-144-64.6-144-144s64.6-144,144-144'
    's144,64.6,144,144S335.4,400,256,400z"/>'
    '<path d="M272,176h-32v96l64,64l22.6-22.6l-54.6-54.6V176z"/>'
    '<path d="M256,0C114.6,0,0,114.6,0,256s114.6,256,256,256s256-114.6,256-256'
    'S397.4,0,256,0z M256,480C132.3,480,32,379.7,32,256S132.3,32,256,32'
    's224,100.3,224,224S379.7,480,256,480z"/>'
    '</svg>';

// ─── DDG URLs por tab ─────────────────────────────────────────────────────────
const _ddgHideCss = '''
(function() {
  const s = document.createElement('style');
  s.textContent = `
    #header, .header, .nav-bar, #duckbar,
    .header--aside, .js-header-wrapper,
    [class*="header"], [id*="header"],
    #logo_homepage_link, .logo-wrap,
    .search-form--adv, .search-form__input-wrap,
    .js-search-form, #search_form_homepage,
    .search-wrap--home { display: none !important; }
    ::-webkit-scrollbar { width: 0px !important; }
  `;
  document.head.appendChild(s);
})();
''';

enum _WebTab { tudo, imagens, videos, noticias }

extension _WebTabX on _WebTab {
  String get label {
    switch (this) {
      case _WebTab.tudo:     return 'Tudo';
      case _WebTab.imagens:  return 'Imagens';
      case _WebTab.videos:   return 'Vídeos';
      case _WebTab.noticias: return 'Notícias';
    }
  }

  String url(String q) {
    final enc = Uri.encodeComponent(q);
    switch (this) {
      case _WebTab.tudo:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&ia=web&kaj=m';
      case _WebTab.imagens:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&iax=images&ia=images&kaj=m';
      case _WebTab.videos:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&ia=videos&iax=videos&kaj=m';
      case _WebTab.noticias:
        return 'https://duckduckgo.com/?q=$enc&kp=-2&kav=1&ia=news&iax=news&kaj=m';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
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

  // Um controller por tab para não perder posição
  final Map<_WebTab, InAppWebViewController> _webCtrls = {};
  final Map<_WebTab, bool> _webLoading = {
    _WebTab.tudo:     false,
    _WebTab.imagens:  false,
    _WebTab.videos:   false,
    _WebTab.noticias: false,
  };
  // Guarda se cada tab já foi inicializada (evita reload ao mudar tab)
  final Map<_WebTab, bool> _tabReady = {
    _WebTab.tudo:     false,
    _WebTab.imagens:  false,
    _WebTab.videos:   false,
    _WebTab.noticias: false,
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
    // Reset: todas as tabs vão recarregar com nova query
    _tabReady.updateAll((_, __) => false);
    setState(() {
      _searching    = true;
      _editingQuery = false;
      _suggestions  = [];
      _activeTab    = _WebTab.tudo;
      _webLoading.updateAll((_, __) => false);
    });
    // Carrega a tab activa
    final ctrl = _webCtrls[_activeTab];
    if (ctrl != null) {
      await ctrl.loadUrl(
          urlRequest: URLRequest(url: WebUri(_activeTab.url(q))));
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

  void _backToSearch() {
    Navigator.pushReplacement(context, iosRoute(SearchPage()));
  }

  void _switchTab(_WebTab tab) {
    if (_activeTab == tab) return;
    setState(() => _activeTab = tab);
    // Se a tab ainda não foi carregada, carrega agora
    if (!(_tabReady[tab] ?? false) && _searching) {
      final ctrl = _webCtrls[tab];
      if (ctrl != null) {
        ctrl.loadUrl(urlRequest: URLRequest(url: WebUri(tab.url(_q.text.trim()))));
      }
    }
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final topPad = MediaQuery.of(context).padding.top;
    final showEditable = !_searching || _editingQuery;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: ListenableBuilder(
        listenable: ThemeService.instance,
        builder: (_, __) {
          final t      = AppTheme.current;
          final isDark = t.statusBar == Brightness.light;

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
                        // Back
                        GestureDetector(
                          onTap: _backToSearch,
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            child: SvgPicture.string(_iBack, width: 20, height: 20,
                                colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
                          ),
                        ),

                        // Input
                        Expanded(
                          child: GestureDetector(
                            onTap: !showEditable ? _activateEditing : null,
                            child: Container(
                              height: 42,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF2A2A2A)
                                    : const Color(0xFFF2F2F2),
                                borderRadius: BorderRadius.circular(10)),
                              child: Row(children: [
                                const SizedBox(width: 10),
                                if (!showEditable) ...[
                                  _DdgIcon(size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(_q.text,
                                      style: TextStyle(color: t.inputText, fontSize: 14.5),
                                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                                  const SizedBox(width: 10),
                                ] else ...[
                                  Icon(Icons.search_rounded, size: 18,
                                      color: isDark ? Colors.white38 : Colors.black38),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _q,
                                      focusNode: _focus,
                                      autofocus: !_searching,
                                      style: TextStyle(color: t.inputText, fontSize: 14.5),
                                      textInputAction: TextInputAction.search,
                                      cursorColor: AppTheme.ytRed,
                                      cursorWidth: 1.5,
                                      onSubmitted: _doSearch,
                                      decoration: InputDecoration(
                                        border: InputBorder.none,
                                        hintText: 'Pesquisar...',
                                        hintStyle: TextStyle(
                                            color: isDark ? Colors.white30 : Colors.black38,
                                            fontSize: 14.5),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(vertical: 11)),
                                    )),
                                  if (_q.text.isNotEmpty)
                                    GestureDetector(
                                      onTap: _clearSearch,
                                      child: Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Icon(Icons.close_rounded,
                                            color: isDark ? Colors.white54 : Colors.black38,
                                            size: 17))),
                                ],
                              ]),
                            ),
                          ),
                        ),
                      ]),
                    ),

                    // ── Tabs (só visíveis quando há pesquisa activa) ──
                    if (_searching && !_editingQuery)
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: _WebTab.values.map((tab) {
                            final active = _activeTab == tab;
                            return GestureDetector(
                              onTap: () => _switchTab(tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.only(right: 6, bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: active
                                      ? (isDark ? Colors.white : Colors.black)
                                      : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE)),
                                  borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 180),
                                  style: TextStyle(
                                    color: active
                                        ? (isDark ? Colors.black : Colors.white)
                                        : (isDark ? Colors.white70 : Colors.black54),
                                    fontSize: 12,
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500),
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
                            _q.selection = TextSelection.collapsed(offset: q.length);
                          },
                          onRemoveHistory: _removeHistory,
                          onClearHistory: _clearHistory,
                        )
                      : _buildWebViews(isDark),
                ),
              ]),
            ),
          );
        },
      ),
    );
  }

  // Constrói todos os WebViews em stack (Offstage) para não perder posição
  Widget _buildWebViews(bool isDark) {
    return Stack(
      children: _WebTab.values.map((tab) {
        final isActive = tab == _activeTab;
        return Offstage(
          offstage: !isActive,
          child: _WebPane(
            key: ValueKey(tab),
            tab: tab,
            query: _q.text.trim(),
            isDark: isDark,
            isActive: isActive,
            loading: _webLoading[tab] ?? false,
            onCreated: (ctrl) {
              _webCtrls[tab] = ctrl;
              // Se é a tab activa e ainda não foi carregada, carrega agora
              if (isActive && !(_tabReady[tab] ?? false)) {
                _tabReady[tab] = true;
              }
            },
            onLoadStart: () {
              if (mounted) setState(() => _webLoading[tab] = true);
            },
            onLoadStop: (ctrl) async {
              await ctrl.evaluateJavascript(source: _ddgHideCss);
              _tabReady[tab] = true;
              if (mounted) setState(() => _webLoading[tab] = false);
            },
          ),
        );
      }).toList(),
    );
  }
}

// ─── WebPane individual por tab ───────────────────────────────────────────────
class _WebPane extends StatelessWidget {
  final _WebTab tab;
  final String query;
  final bool isDark, isActive, loading;
  final void Function(InAppWebViewController) onCreated;
  final VoidCallback onLoadStart;
  final void Function(InAppWebViewController) onLoadStop;

  const _WebPane({
    super.key,
    required this.tab,
    required this.query,
    required this.isDark,
    required this.isActive,
    required this.loading,
    required this.onCreated,
    required this.onLoadStart,
    required this.onLoadStop,
  });

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Stack(children: [
      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(tab.url(query))),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
          transparentBackground: true,
          supportZoom: false,
          useShouldOverrideUrlLoading: false,
          // scrollbar nativo desativado — usamos RawScrollbar Flutter
          disableVerticalScroll: false,
        ),
        onWebViewCreated: onCreated,
        onLoadStart: (_, __) => onLoadStart(),
        onLoadStop: (ctrl, __) => onLoadStop(ctrl),
        onReceivedError: (_, __, ___) => onLoadStart(), // reset loading
      ),

      // ── Scrollbar fino moderno (lado direito) ──
      Positioned(
        right: 2, top: 0, bottom: 0,
        child: _ThinScrollIndicator(loading: loading, isDark: isDark),
      ),

      // ── Progress bar no topo ──
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

// ─── Scrollbar fino animado ───────────────────────────────────────────────────
class _ThinScrollIndicator extends StatefulWidget {
  final bool loading, isDark;
  const _ThinScrollIndicator({required this.loading, required this.isDark});
  @override State<_ThinScrollIndicator> createState() => _ThinScrollIndicatorState();
}

class _ThinScrollIndicatorState extends State<_ThinScrollIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    if (!widget.loading) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final pos = _anim.value;
        return CustomPaint(
          size: const Size(3, double.infinity),
          painter: _ScrollbarPainter(
            position: pos,
            color: widget.isDark
                ? Colors.white.withOpacity(0.35)
                : Colors.black.withOpacity(0.25)),
        );
      },
    );
  }
}

class _ScrollbarPainter extends CustomPainter {
  final double position;
  final Color color;
  const _ScrollbarPainter({required this.position, required this.color});

  @override void paint(Canvas canvas, Size size) {
    final h = size.height * 0.15;
    final top = (size.height - h) * position;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, top, 3, h),
      const Radius.circular(2));
    canvas.drawRRect(rr, Paint()..color = color);
  }

  @override bool shouldRepaint(_ScrollbarPainter old) =>
      old.position != position || old.color != color;
}

// ─── Ícone DDG ────────────────────────────────────────────────────────────────
class _DdgIcon extends StatelessWidget {
  final double size;
  const _DdgIcon({this.size = 20});
  @override Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(
      color: Color(0xFFDE5833), shape: BoxShape.circle),
    child: Center(
      child: Text('D',
        style: TextStyle(color: Colors.white,
            fontSize: size * 0.55, fontWeight: FontWeight.w900, height: 1))));
}

// ─── _SuggestionsView ─────────────────────────────────────────────────────────
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
        Icon(Icons.search_rounded, color: subColor.withOpacity(0.25), size: 52),
        const SizedBox(height: 14),
        Text('Pesquisa algo', style: TextStyle(color: subColor, fontSize: 14)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(children: [
                showSuggestions
                    ? Icon(Icons.search_rounded, color: subColor, size: 20)
                    : SvgPicture.string(_iHistory, width: 20, height: 20,
                        colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
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
                          ? Icons.north_west_rounded : Icons.close_rounded,
                      color: subColor, size: 18)),
                ),
              ]),
            ),
          ),
          Divider(height: 1, color: divColor, indent: 52),
        ])),
      ],
    );
  }
}