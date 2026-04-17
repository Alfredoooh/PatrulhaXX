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

// ─── SVG inline ───────────────────────────────────────────────────────────────
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

const _googleSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
  <path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
  <path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
  <path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.18 1.48-4.97 2.31-8.16 2.31-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
  <path fill="none" d="M0 0h48v48H0z"/>
</svg>''';

// ─── Motores de pesquisa ───────────────────────────────────────────────────────
enum SearchEngine { google, bing, duckduckgo, yahoo }

extension SearchEngineX on SearchEngine {
  String get label {
    switch (this) {
      case SearchEngine.google:     return 'Google';
      case SearchEngine.bing:       return 'Bing';
      case SearchEngine.duckduckgo: return 'DuckDuckGo';
      case SearchEngine.yahoo:      return 'Yahoo';
    }
  }

  // URLs já com parâmetros de SafeSearch desativado
  String buildUrl(String query) {
    final q = Uri.encodeComponent(query);
    switch (this) {
      case SearchEngine.google:
        // &safe=off — ignorado frequentemente pelo Google, mas enviamos na mesma
        return 'https://www.google.com/search?q=$q&safe=off';
      case SearchEngine.bing:
        // &adlt=off desativa SafeSearch no Bing
        return 'https://www.bing.com/search?q=$q&adlt=off';
      case SearchEngine.duckduckgo:
        // &kp=-2 é o mais fiável para desativar SafeSearch
        return 'https://duckduckgo.com/?q=$q&kp=-2';
      case SearchEngine.yahoo:
        return 'https://search.yahoo.com/search?p=$q&vm=r';
    }
  }

  String get svgIcon {
    switch (this) {
      case SearchEngine.google:
        return _googleSvg;
      case SearchEngine.bing:
        return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><path fill="#008373" d="M8 3l6 2v18l-4-2-2 3 10 6 8-5V14l-14-5z"/></svg>';
      case SearchEngine.duckduckgo:
        return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><circle cx="16" cy="16" r="16" fill="#DE5833"/><text x="16" y="21" text-anchor="middle" fill="white" font-size="14" font-weight="bold">D</text></svg>';
      case SearchEngine.yahoo:
        return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32"><rect width="32" height="32" rx="6" fill="#6001D2"/><text x="16" y="22" text-anchor="middle" fill="white" font-size="13" font-weight="bold">Y!</text></svg>';
    }
  }
}

// ─── Preferência do motor guardada ────────────────────────────────────────────
class _EnginePrefs {
  static const _key = 'search_engine_v1';
  static Future<SearchEngine> load() async {
    final p = await SharedPreferences.getInstance();
    final v = p.getInt(_key) ?? 0;
    return SearchEngine.values[v.clamp(0, SearchEngine.values.length - 1)];
  }
  static Future<void> save(SearchEngine e) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_key, e.index);
  }
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

  static String _fmtRate(dynamic r) {
    final f = double.tryParse(r?.toString() ?? '') ?? 0.0;
    return f.toStringAsFixed(1);
  }
}

class _EpornerApi {
  static const _base = 'https://www.eporner.com/api/v2/video/search/';
  static const _ua   = 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36';

  static Future<({List<_EpornerVideo> videos, int totalPages})>
      search({required String query, int page = 1, int perPage = 40}) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query':     query.isEmpty ? 'all' : query,
      'per_page':  '$perPage',
      'page':      '$page',
      'thumbsize': 'big',
      'order':     'latest',
      'lq':        '1',
      'format':    'json',
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
// SearchResultsPage
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

  // Modo: 'videos' mostra resultados da API, 'web' mostra InAppWebView
  _ResultMode _mode = _ResultMode.videos;

  List<FeedVideo> _feedVideos  = [];
  bool _loading     = false;
  bool _loadingMore = false;
  bool _searching   = false;
  bool _editingQuery = false;
  bool _webLoading  = false;
  String? _error;
  int _page       = 1;
  int _totalPages = 1;

  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  SearchEngine _engine = SearchEngine.duckduckgo;
  InAppWebViewController? _webCtrl;

  @override void initState() {
    super.initState();
    _q      = TextEditingController(text: widget.query ?? '');
    _scroll = ScrollController()..addListener(_onScroll);
    _q.addListener(_onTyping);
    _loadPrefs();
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

  Future<void> _loadPrefs() async {
    final e = await _EnginePrefs.load();
    if (mounted) setState(() => _engine = e);
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

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _page < _totalPages) {
      _fetchMore();
    }
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
      _loading      = true;
      _error        = null;
      _feedVideos   = [];
      _suggestions  = [];
      _page         = 1;
      _totalPages   = 1;
      _mode         = _ResultMode.videos;
    });
    await _fetch(reset: true);
  }

  // Pesquisa no motor web configurado
  void _doWebSearch(String q) {
    q = q.trim(); if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    setState(() {
      _searching    = true;
      _editingQuery = false;
      _mode         = _ResultMode.web;
      _webLoading   = true;
    });
    final url = _engine.buildUrl(q);
    _webCtrl?.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
  }

  Future<void> _fetch({bool reset = false}) async {
    try {
      final results = await Future.wait([
        _EpornerApi.search(query: _q.text.trim(), page: _page, perPage: 20),
        FeedFetcher.fetchPornhub(_page),
        FeedFetcher.fetchRedtube(_page),
        FeedFetcher.fetchYouporn(_page),
        FeedFetcher.fetchXhamster(_page),
        FeedFetcher.fetchBravotube(_page),
        FeedFetcher.fetchDrtuber(_page),
        FeedFetcher.fetchTxxx(_page),
        FeedFetcher.fetchGotporn(_page),
        FeedFetcher.fetchPorndig(_page),
      ]);

      final epResult  = results[0] as ({List<_EpornerVideo> videos, int totalPages});
      final phVideos  = results[1] as List<FeedVideo>;
      final rtVideos  = results[2] as List<FeedVideo>;
      final ypVideos  = results[3] as List<FeedVideo>;
      final xhVideos  = results[4] as List<FeedVideo>;
      final btVideos  = results[5] as List<FeedVideo>;
      final dtVideos  = results[6] as List<FeedVideo>;
      final txVideos  = results[7] as List<FeedVideo>;
      final gpVideos  = results[8] as List<FeedVideo>;
      final pdVideos  = results[9] as List<FeedVideo>;

      final epFeed = epResult.videos.map((v) => FeedVideo(
        title: v.title, thumb: v.thumbUrl,
        embedUrl: 'https://www.eporner.com/embed/${v.id}/',
        duration: v.lengthMin, views: v.views,
        source: VideoSource.eporner,
      )).toList();

      final merged = <FeedVideo>[];
      final lists = [
        epFeed, phVideos, rtVideos, ypVideos, xhVideos,
        btVideos, dtVideos, txVideos, gpVideos, pdVideos,
      ].where((l) => l.isNotEmpty).toList();

      if (lists.isNotEmpty) {
        final maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
        for (int i = 0; i < maxLen; i++) {
          for (final list in lists) { if (i < list.length) merged.add(list[i]); }
        }
        merged.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
      }

      if (mounted) setState(() {
        _feedVideos  = reset ? merged : [..._feedVideos, ...merged];
        _totalPages  = epResult.totalPages;
        _loading     = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; _loadingMore = false; });
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() { _loadingMore = true; _page++; });
    await _fetch();
  }

  void _openVideo(FeedVideo v) {
    if (widget.onVideoTap != null) {
      widget.onVideoTap!(v);
    } else {
      Navigator.push(context, iosRoute(ExibicaoPage(
        embedUrl: v.embedUrl, currentVideo: v,
        onVideoTap: (next) => Navigator.pushReplacement(context,
            iosRoute(ExibicaoPage(
              embedUrl: next.embedUrl, currentVideo: next,
              onVideoTap: (_) {},
            ))),
      )));
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
      _feedVideos   = [];
      _suggestions  = [];
      _mode         = _ResultMode.videos;
    });
    _focus.requestFocus();
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
          Text('Motor de pesquisa',
            style: TextStyle(color: t.text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...SearchEngine.values.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: SvgPicture.string(e.svgIcon, width: 26, height: 26),
            title: Text(e.label,
              style: TextStyle(color: t.text, fontSize: 14, fontWeight: FontWeight.w500)),
            trailing: _engine == e
                ? Icon(Icons.check_rounded, color: AppTheme.ytRed, size: 20)
                : null,
            onTap: () async {
              await _EnginePrefs.save(e);
              if (mounted) setState(() => _engine = e);
              if (mounted) Navigator.pop(context);
              // re-pesquisa no novo motor se já há query
              if (_q.text.trim().isNotEmpty) _doWebSearch(_q.text.trim());
            },
          )),
        ]),
      ),
    );
  }

  // Volta à SearchPage
  void _goToSearchPage() {
    Navigator.pushReplacement(context, iosRoute(const SearchPage()));
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;

    final showEditableField = !_searching || _editingQuery;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar),
      child: Scaffold(
        backgroundColor: t.bg,
        resizeToAvoidBottomInset: false,
        body: Column(children: [

          // ── AppBar ──────────────────────────────────────────────────────────
          Container(
            color: t.appBar,
            child: Column(children: [
              SizedBox(height: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Row(children: [

                  // Back
                  GestureDetector(
                    onTap: () {
                      if (_editingQuery) {
                        setState(() { _editingQuery = false; });
                        _focus.unfocus();
                      } else if (_searching) {
                        _clearSearch();
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: SvgPicture.string(_iBack, width: 20, height: 20,
                          colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
                    ),
                  ),

                  // Campo de pesquisa
                  Expanded(
                    child: GestureDetector(
                      onTap: !showEditableField ? _activateEditing : null,
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF2F2F2),
                          borderRadius: BorderRadius.circular(10)),
                        child: Row(children: [
                          const SizedBox(width: 10),

                          // Quando há pesquisa activa e não está a editar:
                          // mostra logo do motor + texto da query
                          if (!showEditableField) ...[
                            SvgPicture.string(_engine.svgIcon, width: 18, height: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_q.text,
                                style: TextStyle(
                                  color: t.inputText, fontSize: 14.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 10),
                          ] else ...[
                            // Campo editável
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
                                  hintText: 'Pesquisar vídeos...',
                                  hintStyle: TextStyle(
                                      color: isDark ? Colors.white30 : Colors.black38,
                                      fontSize: 14.5),
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 11),
                                ),
                              ),
                            ),
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

                  // Botão motor de pesquisa (ícone do motor activo)
                  GestureDetector(
                    onTap: _showEngineSheet,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: SvgPicture.string(_engine.svgIcon, width: 22, height: 22)),
                  ),
                ]),
              ),

              // Tabs: Vídeos | Web
              if (_searching && !_editingQuery)
                Row(children: [
                  _Tab(
                    label: 'Vídeos',
                    active: _mode == _ResultMode.videos,
                    onTap: () => setState(() => _mode = _ResultMode.videos)),
                  _Tab(
                    label: 'Web',
                    active: _mode == _ResultMode.web,
                    onTap: () {
                      setState(() => _mode = _ResultMode.web);
                      if (_webCtrl == null) {
                        // WebView ainda não criado, será criado no build
                      } else {
                        _webCtrl!.loadUrl(
                          urlRequest: URLRequest(
                            url: WebUri(_engine.buildUrl(_q.text.trim()))));
                      }
                    }),
                ]),

              Divider(height: 1, color: t.divider),
            ]),
          ),

          // ── Corpo ────────────────────────────────────────────────────────
          Expanded(
            child: !_searching || _editingQuery
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
                : _mode == _ResultMode.web
                    ? _buildWebView()
                    : _loading
                        ? const _SkeletonList()
                        : _error != null
                            ? _ErrorView(message: _error!, onRetry: () => _doSearch(_q.text))
                            : _VideosTab(
                                videos: _feedVideos,
                                loadingMore: _loadingMore,
                                scroll: _scroll,
                                onTap: _openVideo,
                              ),
          ),
        ]),
      ),
    );
  }

  Widget _buildWebView() {
    final t = AppTheme.current;
    final url = _engine.buildUrl(_q.text.trim());
    return Stack(children: [
      InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(url)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          userAgent: 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/124.0.0.0 Mobile Safari/537.36',
          transparentBackground: true,
          supportZoom: true,
          useShouldOverrideUrlLoading: false,
        ),
        onWebViewCreated: (ctrl) => _webCtrl = ctrl,
        onLoadStart: (_, __) => setState(() => _webLoading = true),
        onLoadStop: (_, __) => setState(() => _webLoading = false),
        onReceivedError: (_, __, ___) => setState(() => _webLoading = false),
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

// ─── Tab selector ─────────────────────────────────────────────────────────────
class _Tab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.active, required this.onTap});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: active ? AppTheme.ytRed : Colors.transparent,
            width: 2))),
        child: Text(label,
          style: TextStyle(
            color: active ? t.text : t.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
      ),
    );
  }
}

// ─── Modo resultado ───────────────────────────────────────────────────────────
enum _ResultMode { videos, web }

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionsView (sem alterações)
// ─────────────────────────────────────────────────────────────────────────────
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
        Text('Pesquisa vídeos', style: TextStyle(color: subColor, fontSize: 14)),
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                showSuggestions
                    ? Icon(Icons.search_rounded, color: subColor, size: 20)
                    : SvgPicture.string(_iHistory, width: 20, height: 20,
                        colorFilter: ColorFilter.mode(subColor, BlendMode.srcIn)),
                const SizedBox(width: 14),
                Expanded(child: Text(item,
                    style: TextStyle(color: textColor, fontSize: 14.5))),
                GestureDetector(
                  onTap: () => showSuggestions ? onFill(item) : onRemoveHistory(item),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      showSuggestions ? Icons.north_west_rounded : Icons.close_rounded,
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

// ─────────────────────────────────────────────────────────────────────────────
// _VideosTab (sem alterações)
// ─────────────────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<FeedVideo> videos;
  final bool loadingMore;
  final ScrollController scroll;
  final void Function(FeedVideo) onTap;

  const _VideosTab({
    required this.videos, required this.loadingMore,
    required this.scroll, required this.onTap,
  });

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (videos.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, color: t.iconTertiary, size: 48),
        const SizedBox(height: 12),
        Text('Nenhum vídeo encontrado',
            style: TextStyle(color: t.textSecondary, fontSize: 13)),
      ]));
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: videos.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == videos.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: AppTheme.ytRed))),
          );
        }
        return _VideoCard(video: videos[i], onTap: () => onTap(videos[i]));
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _VideoCard (sem alterações)
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _VideoCard({required this.video, required this.onTap});

  static Map<String, String> _headers(VideoSource src) {
    final origin = _origin(src);
    return {
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
          '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36',
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'pt-PT,pt;q=0.9',
      if (origin.isNotEmpty) 'Referer': origin,
    };
  }

  static String _origin(VideoSource src) {
    switch (src) {
      case VideoSource.eporner:   return 'https://www.eporner.com/';
      case VideoSource.pornhub:   return 'https://www.pornhub.com/';
      case VideoSource.redtube:   return 'https://www.redtube.com/';
      case VideoSource.youporn:   return 'https://www.youporn.com/';
      case VideoSource.xvideos:   return 'https://www.xvideos.com/';
      case VideoSource.xhamster:  return 'https://xhamster.com/';
      case VideoSource.spankbang: return 'https://spankbang.com/';
      case VideoSource.bravotube: return 'https://www.bravotube.net/';
      case VideoSource.drtuber:   return 'https://www.drtuber.com/';
      case VideoSource.txxx:      return 'https://www.txxx.com/';
      case VideoSource.gotporn:   return 'https://www.gotporn.com/';
      case VideoSource.porndig:   return 'https://www.porndig.com/';
    }
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              _ThumbNet(url: video.thumb, headers: _headers(video.source)),
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 6, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _FaviconAvatar(source: video.source, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(video.title,
                    style: TextStyle(color: t.text, fontSize: 14,
                        fontWeight: FontWeight.w500, height: 1.35),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(_buildSubtitle(video),
                    style: TextStyle(color: t.textSecondary, fontSize: 12),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                ]),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  String _buildSubtitle(FeedVideo v) {
    final parts = <String>[v.sourceLabel];
    if (v.views.isNotEmpty) parts.add('${v.views} vis.');
    return parts.join(' · ');
  }
}

// ─── ThumbNet, ThumbShimmer, FaviconAvatar, Skeleton, Error ─────────────────
class _ThumbNet extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  const _ThumbNet({required this.url, required this.headers});
  @override State<_ThumbNet> createState() => _ThumbNetState();
}
class _ThumbNetState extends State<_ThumbNet> {
  int _attempt = 0;
  bool _failed  = false;
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (widget.url.isEmpty || _failed) {
      return Container(color: t.thumbBg,
          child: Center(child: Icon(Icons.play_circle_outline_rounded,
              color: t.iconSub, size: 40)));
    }
    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover,
      headers: widget.headers,
      errorBuilder: (_, __, ___) {
        if (_attempt < 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _attempt++);
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _failed = true);
          });
        }
        return Container(color: t.thumbBg,
            child: Center(child: Icon(Icons.play_circle_outline_rounded,
                color: t.iconSub, size: 40)));
      },
      loadingBuilder: (_, child, p) {
        if (p == null) return child;
        return _ThumbShimmer();
      },
    );
  }
}

class _ThumbShimmer extends StatefulWidget {
  @override State<_ThumbShimmer> createState() => _ThumbShimmerState();
}
class _ThumbShimmerState extends State<_ThumbShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
      colors: AppTheme.current.shimmer))));
}

class _FaviconAvatar extends StatelessWidget {
  final VideoSource source;
  final double size;
  const _FaviconAvatar({required this.source, this.size = 36});
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        faviconForSource(source),
        width: size, height: size,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => Container(
          width: size, height: size,
          decoration: BoxDecoration(color: t.avatarBg, shape: BoxShape.circle),
          child: Center(child: Text(
            source.name[0].toUpperCase(),
            style: TextStyle(color: t.textSecondary,
                fontSize: size * 0.36, fontWeight: FontWeight.w700))),
        ),
        loadingBuilder: (_, child, p) => p == null ? child : Container(
          width: size, height: size,
          decoration: BoxDecoration(color: t.avatarBg, shape: BoxShape.circle)),
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(top: 8),
    itemCount: 5,
    itemBuilder: (_, __) => const _CardSkeleton());
}

class _CardSkeleton extends StatefulWidget {
  const _CardSkeleton();
  @override State<_CardSkeleton> createState() => _CardSkeletonState();
}
class _CardSkeletonState extends State<_CardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  Widget _box(double w, double h, {double r = 6}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer))));

  @override Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _box(w, w * 9 / 16, r: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(36, 36, r: 18),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w * 0.75, 14),
              const SizedBox(height: 6),
              _box(w * 0.45, 12),
            ])),
          ]),
        ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, color: t.iconTertiary, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center,
              style: TextStyle(color: t.textTertiary, fontSize: 12)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: t.border),
                borderRadius: BorderRadius.circular(8)),
              child: Text('Tentar novamente',
                  style: TextStyle(color: t.text, fontSize: 13,
                      fontWeight: FontWeight.w500)))),
        ]),
      ),
    );
  }
}