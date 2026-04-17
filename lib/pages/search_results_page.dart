import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_model.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import 'exibicao_page.dart';
import 'home_page.dart' show iosRoute;
import 'search_page.dart';

const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

const _iSearch =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M23.707,22.293l-5.969-5.969a10.016,10.016,0,1,0-1.414,1.414l5.969,5.969'
    'a1,1,0,0,0,1.414-1.414ZM10,18a8,8,0,1,1,8-8A8.009,8.009,0,0,1,10,18Z"/></svg>';

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

// CSS que oculta o header/navbar do DuckDuckGo
const _ddgHideHeaderCss = '''
(function() {
  const style = document.createElement('style');
  style.textContent = `
    #header, .header, .nav-bar, #duckbar,
    .header--aside, .js-header-wrapper,
    [class*="header"], [id*="header"],
    .site-wrapper--has-sidebar .ddgsi,
    #logo_homepage_link, .logo-wrap,
    .search-form--adv, .search-form__input-wrap,
    .js-search-form, #search_form_homepage,
    .search-wrap--home { display: none !important; }
  `;
  document.head.appendChild(style);
})();
''';

// URL DuckDuckGo com SafeSearch desativado, sem header
String _ddgUrl(String query) {
  final q = Uri.encodeComponent(query);
  // kp=-2: safesearch off | kav=1: adult content | ia=web: resultados web
  return 'https://duckduckgo.com/?q=$q&kp=-2&kav=1&ia=web&kaj=m';
}

// ─── Modelo Eporner ───────────────────────────────────────────────────────────
class _EpornerVideo {
  final String id, title, url, thumbUrl, lengthMin, views, rate, keywords;
  const _EpornerVideo({
    required this.id, required this.title, required this.url,
    required this.thumbUrl, required this.lengthMin,
    required this.views, required this.rate, required this.keywords,
  });

  factory _EpornerVideo.fromJson(Map<String, dynamic> j) {
    String thumb = '';
    final thumbs = j['thumbs'] as List<dynamic>?;
    if (thumbs != null && thumbs.isNotEmpty) {
      final sorted = thumbs.map((t) => t as Map).toList()
        ..sort((a, b) => ((b['width'] ?? 0) as int).compareTo((a['width'] ?? 0) as int));
      thumb = sorted.first['src'] as String? ?? '';
    }
    if (thumb.isEmpty) {
      final dt = j['default_thumb'] as Map<String, dynamic>?;
      thumb = (dt?['src'] as String?) ?? '';
    }
    return _EpornerVideo(
      id:        (j['id'] as String?) ?? '',
      title:     FeedVideo.cleanTitle((j['title'] as String?) ?? ''),
      url:       (j['url'] as String?) ?? '',
      thumbUrl:  thumb,
      lengthMin: (j['length_min'] as String?) ?? '',
      views:     _fmtViews(j['views']),
      rate:      _fmtRate(j['rate']),
      keywords:  (j['keywords'] as String?) ?? '',
    );
  }

  static String _fmtViews(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}k';
    return n > 0 ? '$n' : '';
  }

  static String _fmtRate(dynamic r) =>
      (double.tryParse(r?.toString() ?? '') ?? 0.0).toStringAsFixed(1);
}

class _EpornerApi {
  static const _base = 'https://www.eporner.com/api/v2/video/search/';
  static const _ua   = 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36';

  static Future<({List<_EpornerVideo> videos, int totalPages})>
      search({required String query, int page = 1, int perPage = 40}) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query':     query.isEmpty ? 'all' : query,
      'per_page':  '$perPage', 'page': '$page',
      'thumbsize': 'big', 'order': 'latest',
      'lq': '1', 'format': 'json',
    });
    final resp = await http.get(uri,
        headers: {'Accept': 'application/json', 'User-Agent': _ua})
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final rawVideos = (data['videos'] as List<dynamic>?) ?? [];
    return (
      videos:     rawVideos.map((v) => _EpornerVideo.fromJson(v as Map<String, dynamic>)).toList(),
      totalPages: (data['total_pages'] as int?) ?? 1,
    );
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
  late final ScrollController _scroll;
  final _focus = FocusNode();

  bool _searching    = false;
  bool _editingQuery = false;
  bool _webLoading   = false;

  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  InAppWebViewController? _webCtrl;

  @override void initState() {
    super.initState();
    _q      = TextEditingController(text: widget.query ?? '');
    _scroll = ScrollController();
    _q.addListener(_onTyping);
    _loadHistory();
    if ((widget.query ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(widget.query!));
    }
  }

  @override void dispose() {
    _q.removeListener(_onTyping);
    _q.dispose(); _scroll.dispose(); _focus.dispose();
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
      _webLoading   = true;
    });
    // Se o WebView já existe, carrega nova URL
    _webCtrl?.loadUrl(urlRequest: URLRequest(url: WebUri(_ddgUrl(q))));
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

  // Botão back do sistema: navega na WebView se possível
  Future<bool> _onWillPop() async {
    if (_searching && _webCtrl != null) {
      final canGoBack = await _webCtrl!.canGoBack();
      if (canGoBack) {
        await _webCtrl!.goBack();
        return false; // não fecha a página
      }
    }
    return true; // fecha normalmente
  }

  // Botão back da AppBar: volta sempre à SearchPage
  void _backToSearch() {
    Navigator.pushReplacement(context, iosRoute(const SearchPage()));
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;
    final showEditable = !_searching || _editingQuery;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: t.statusBar),
        child: Scaffold(
          backgroundColor: t.bg,
          resizeToAvoidBottomInset: false,
          body: Column(children: [

            // ── AppBar ──────────────────────────────────────────────────────
            Container(
              color: t.appBar,
              child: Column(children: [
                SizedBox(height: topPad),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                  child: Row(children: [

                    // Back → volta à SearchPage
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
                              // Display: ícone DDG + texto query
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
                Divider(height: 1, color: t.divider),
              ]),
            ),

            // ── Corpo ────────────────────────────────────────────────────────
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
                  : _buildWebView(),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return Stack(children: [
      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(_ddgUrl(_q.text.trim()))),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
          transparentBackground: true,
          supportZoom: false,
          useShouldOverrideUrlLoading: false,
        ),
        onWebViewCreated: (ctrl) => _webCtrl = ctrl,
        onLoadStart: (_, __) {
          if (mounted) setState(() => _webLoading = true);
        },
        onLoadStop: (ctrl, __) async {
          // Injeta CSS para ocultar header do DDG
          await ctrl.evaluateJavascript(source: _ddgHideHeaderCss);
          if (mounted) setState(() => _webLoading = false);
        },
        onReceivedError: (_, __, ___) {
          if (mounted) setState(() => _webLoading = false);
        },
      ),
      if (_webLoading)
        Positioned(
          top: 0, left: 0, right: 0,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            color: AppTheme.ytRed,
            minHeight: 2)),
    ]);
  }
}

// ─── Ícone DDG simples ────────────────────────────────────────────────────────
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
            fontSize: size * 0.55, fontWeight: FontWeight.w900,
            height: 1))));
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
              // mais espaço vertical entre sugestões
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