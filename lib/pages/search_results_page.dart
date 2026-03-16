import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_model.dart';
import '../services/theme_service.dart';
import 'browser_page.dart';
import 'home_page.dart' show kPrimaryColor, FeedVideo, FeedFetcher,
    VideoSource, faviconForSource;

// ─── Modelo original mantido para compatibilidade ────────────────────────────
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
      // Maior resolução disponível
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

// ─── API Eporner ──────────────────────────────────────────────────────────────
class _EpornerApi {
  static const _base = 'https://www.eporner.com/api/v2/video/search/';
  static const _ua   = 'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36';

  static Future<({List<_EpornerVideo> videos, int totalCount, int totalPages})>
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
      totalCount: (data['total_count'] as int?) ?? 0,
      totalPages: (data['total_pages'] as int?) ?? 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsPage — histórico + sugestões + resultados multi-fonte
// Bottom bar SEMPRE visível (não usa Navigator.push — é integrada no IndexedStack)
// ─────────────────────────────────────────────────────────────────────────────
class SearchResultsPage extends StatefulWidget {
  final void Function(FeedVideo)? onVideoTap;
  // Compatibilidade com código antigo que passa query como parâmetro
  final String? query;
  const SearchResultsPage({super.key, this.query, this.onVideoTap});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late final TabController _tabs;
  late final TextEditingController _q;
  late final ScrollController _scroll;
  final _focus = FocusNode();

  List<_EpornerVideo> _videos = [];
  List<FeedVideo>     _feedVideos = [];
  bool _loading     = false;
  bool _loadingMore = false;
  bool _searching   = false;   // true = a mostrar resultados
  String? _error;
  int _page       = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  // Sugestões e histórico
  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  @override
  void initState() {
    super.initState();
    _tabs   = TabController(length: 2, vsync: this);
    _q      = TextEditingController(text: widget.query ?? '');
    _scroll = ScrollController()..addListener(_onScroll);
    _q.addListener(_onTyping);
    _loadHistory();
    if ((widget.query ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _doSearch(widget.query!));
    }
  }

  @override
  void dispose() {
    _tabs.dispose(); _q.removeListener(_onTyping);
    _q.dispose(); _scroll.dispose(); _focus.dispose();
    super.dispose();
  }

  // ── Histórico ─────────────────────────────────────────────────────────────
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
    _history.remove(q); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.setStringList(_kHistory, _history);
  }

  Future<void> _clearHistory() async {
    _history.clear(); setState(() {});
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHistory);
  }

  // ── Sugestões ─────────────────────────────────────────────────────────────
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

  // ── Scroll infinito ───────────────────────────────────────────────────────
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _page < _totalPages) {
      _fetchMore();
    }
  }

  // ── Pesquisa ──────────────────────────────────────────────────────────────
  Future<void> _doSearch(String q) async {
    q = q.trim();
    if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
    await _saveHistory(q);
    setState(() {
      _searching = true; _loading = true; _error = null;
      _videos = []; _feedVideos = []; _suggestions = [];
      _page = 1; _totalPages = 1; _totalCount = 0;
    });
    await _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    try {
      // Eporner em paralelo com as outras fontes
      final results = await Future.wait([
        _EpornerApi.search(query: _q.text.trim(), page: _page, perPage: 30),
        FeedFetcher.fetchPornhub(_page),
        FeedFetcher.fetchRedtube(_page),
      ]);
      final epResult = results[0] as ({List<_EpornerVideo> videos, int totalCount, int totalPages});
      final phVideos = results[1] as List<FeedVideo>;
      final rtVideos = results[2] as List<FeedVideo>;

      // Converte Eporner para FeedVideo para unificar
      final epFeed = epResult.videos.map((v) => FeedVideo(
        title:    v.title,
        thumb:    v.thumbUrl,
        embedUrl: 'https://www.eporner.com/embed/${v.id}/',
        duration: v.lengthMin,
        views:    v.views,
        source:   VideoSource.eporner,
      )).toList();

      // Mistura as fontes intercalando
      final merged = <FeedVideo>[];
      final lists  = [epFeed, phVideos, rtVideos].where((l) => l.isNotEmpty).toList();
      if (lists.isNotEmpty) {
        final maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
        for (int i = 0; i < maxLen; i++) {
          for (final list in lists) { if (i < list.length) merged.add(list[i]); }
        }
        merged.shuffle(Random(DateTime.now().millisecondsSinceEpoch));
      }

      if (mounted) setState(() {
        _videos     = reset ? epResult.videos : [..._videos, ...epResult.videos];
        _feedVideos = reset ? merged : [..._feedVideos, ...merged];
        _totalCount = epResult.totalCount;
        _totalPages = epResult.totalPages;
        _loading    = false;
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
    }
  }

  void _openEporner(_EpornerVideo v) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => BrowserPage(
        freeNavigation: true,
        site: SiteModel(
          id: 'ep', name: v.title, baseUrl: v.url,
          allowedDomain: '', searchUrl: v.url, primaryColor: kPrimaryColor),
      )));

  void _clearSearch() {
    _q.clear();
    setState(() { _searching = false; _videos = []; _feedVideos = []; _suggestions = []; });
    _focus.requestFocus();
  }

  List<_EpornerVideo> get _allWithThumb => _videos.where((v) => v.thumbUrl.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ts      = ThemeService.instance;
    final isDark  = ts.isDark;
    final topPad  = MediaQuery.of(context).padding.top;
    final bg      = isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5);
    final appBarBg= isDark ? const Color(0xFF0C0C0C) : Colors.white;
    final fieldBg = isDark ? Colors.white.withOpacity(0.09) : Colors.black.withOpacity(0.06);
    final textCol = isDark ? Colors.white : const Color(0xFF1C1C1E);
    final subCol  = isDark ? Colors.white54 : Colors.black45;
    final divCol  = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFE0E0E0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: bg,
        resizeToAvoidBottomInset: false,
        body: Column(children: [
          // ── AppBar ──────────────────────────────────────────────────────
          Container(
            color: appBarBg,
            child: Column(children: [
              SizedBox(height: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                child: Row(children: [
                  if (_searching)
                    GestureDetector(
                      onTap: _clearSearch,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Icon(Icons.arrow_back_rounded, color: textCol, size: 24),
                      ),
                    ),
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: fieldBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.10)
                                : Colors.black.withOpacity(0.08)),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 14),
                        Icon(Icons.search_rounded, color: subCol, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _q,
                            focusNode: _focus,
                            autofocus: !_searching,
                            style: TextStyle(color: textCol, fontSize: 14.5),
                            textInputAction: TextInputAction.search,
                            cursorColor: kPrimaryColor,
                            cursorWidth: 1.5,
                            onSubmitted: _doSearch,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Pesquisar vídeos...',
                              hintStyle: TextStyle(color: subCol, fontSize: 14.5),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 11),
                            ),
                          ),
                        ),
                        if (_q.text.isNotEmpty)
                          GestureDetector(
                            onTap: _clearSearch,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: Icon(Icons.close_rounded, color: subCol, size: 17),
                            ),
                          )
                        else
                          const SizedBox(width: 12),
                      ]),
                    ),
                  ),
                ]),
              ),

              // Tabs (só quando há resultados)
              if (_searching) ...[
                Divider(height: 1, color: divCol),
                TabBar(
                  controller: _tabs,
                  indicator: UnderlineTabIndicator(
                    borderSide: const BorderSide(color: kPrimaryColor, width: 2),
                    borderRadius: const BorderRadius.all(Radius.circular(1)),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: textCol,
                  unselectedLabelColor: subCol,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
                  tabs: [
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Vídeos'),
                      if (!_loading && _totalCount > 0) ...[
                        const SizedBox(width: 6),
                        _CountPill(count: _totalCount),
                      ],
                    ])),
                    Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Text('Miniaturas'),
                      if (!_loading && _allWithThumb.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        _CountPill(count: _allWithThumb.length),
                      ],
                    ])),
                  ],
                ),
              ],
            ]),
          ),

          // ── Corpo ────────────────────────────────────────────────────────
          Expanded(
            child: !_searching
                // Sugestões / histórico
                ? _SuggestionsView(
                    query: _q.text.trim(),
                    history: _history,
                    suggestions: _suggestions,
                    isDark: isDark,
                    textColor: textCol,
                    subColor: subCol,
                    divColor: divCol,
                    onSelect: _doSearch,
                    onFill: (q) {
                      _q.text = q;
                      _q.selection = TextSelection.collapsed(offset: q.length);
                    },
                    onRemoveHistory: _removeHistory,
                    onClearHistory: _clearHistory,
                  )
                : _loading
                    ? _SkeletonList(isDark: isDark)
                    : _error != null
                        ? _ErrorView(message: _error!, onRetry: () => _doSearch(_q.text))
                        : TabBarView(
                            controller: _tabs,
                            children: [
                              // Tab Vídeos — cards estilo feed YouTube
                              _VideosTab(
                                videos: _feedVideos,
                                loadingMore: _loadingMore,
                                isDark: isDark,
                                textColor: textCol,
                                subColor: subCol,
                                scroll: _scroll,
                                onTap: _openVideo,
                              ),
                              // Tab Miniaturas — grid masonry
                              _ImagesTab(
                                videos: _allWithThumb,
                                isDark: isDark,
                                onTap: _openEporner,
                              ),
                            ],
                          ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionsView — histórico + sugestões estilo YouTube
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionsView extends StatelessWidget {
  final String query;
  final List<String> history, suggestions;
  final bool isDark;
  final Color textColor, subColor, divColor;
  final void Function(String) onSelect, onFill, onRemoveHistory;
  final VoidCallback onClearHistory;

  const _SuggestionsView({
    required this.query, required this.history, required this.suggestions,
    required this.isDark, required this.textColor, required this.subColor,
    required this.divColor, required this.onSelect, required this.onFill,
    required this.onRemoveHistory, required this.onClearHistory,
  });

  @override
  Widget build(BuildContext context) {
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
                    style: TextStyle(color: kPrimaryColor,
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
                Icon(
                  showSuggestions ? Icons.search_rounded : Icons.history_rounded,
                  color: subColor, size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(item,
                    style: TextStyle(color: textColor, fontSize: 14.5))),
                // Fechar (histórico) ou seta diagonal (sugestão)
                GestureDetector(
                  onTap: () => showSuggestions ? onFill(item) : onRemoveHistory(item),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Icon(
                      showSuggestions
                          ? Icons.north_west_rounded
                          : Icons.close_rounded,
                      color: subColor, size: 18),
                  ),
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
// _VideosTab — cards estilo feed YouTube (thumbnail 16:9 full width)
// ─────────────────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<FeedVideo> videos;
  final bool loadingMore, isDark;
  final Color textColor, subColor;
  final ScrollController scroll;
  final void Function(FeedVideo) onTap;

  const _VideosTab({
    required this.videos, required this.loadingMore, required this.isDark,
    required this.textColor, required this.subColor, required this.scroll,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded, color: subColor.withOpacity(0.25), size: 48),
        const SizedBox(height: 12),
        Text('Nenhum vídeo encontrado', style: TextStyle(color: subColor, fontSize: 13)),
      ]));
    }

    return ListView.builder(
      controller: scroll,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: videos.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == videos.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: SizedBox(width: 20, height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: kPrimaryColor))),
          );
        }
        final v = videos[i];
        return _VideoCard(
          video: v, isDark: isDark,
          textColor: textColor, subColor: subColor,
          onTap: () => onTap(v),
        );
      },
    );
  }
}

// ─── Card de vídeo — thumbnail 16:9 + favicon + título + info ────────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final bool isDark;
  final Color textColor, subColor;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video, required this.isDark,
    required this.textColor, required this.subColor, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Image.network(
                video.thumb,
                fit: BoxFit.cover,
                cacheWidth: 640,
                headers: const {'User-Agent': 'Mozilla/5.0'},
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFE0E0E0),
                  child: Icon(Icons.play_circle_outline_rounded,
                      color: isDark ? Colors.white24 : Colors.black26, size: 40),
                ),
                loadingBuilder: (_, child, p) {
                  if (p == null) return child;
                  return _ThumbSkeleton(isDark: isDark);
                },
              ),
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 6, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Favicon
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  faviconForSource(video.source),
                  width: 34, height: 34,
                  errorBuilder: (_, __, ___) => Container(
                    width: 34, height: 34,
                    decoration: const BoxDecoration(
                        color: Color(0xFF222222), shape: BoxShape.circle),
                    child: Center(child: Text(video.sourceInitial,
                        style: const TextStyle(color: Colors.white54,
                            fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(video.title,
                  style: TextStyle(color: textColor, fontSize: 13.5,
                      fontWeight: FontWeight.w500, height: 1.3),
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${video.sourceLabel}'
                  '${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                  style: TextStyle(color: subColor, fontSize: 11.5),
                ),
              ])),
              Icon(Icons.more_vert_rounded, color: subColor, size: 20),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ImagesTab — grid masonry (mantido do original)
// ─────────────────────────────────────────────────────────────────────────────
class _ImagesTab extends StatelessWidget {
  final List<_EpornerVideo> videos;
  final bool isDark;
  final void Function(_EpornerVideo) onTap;
  const _ImagesTab({required this.videos, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) {
      return Center(child: Text('Nenhuma miniatura encontrada',
          style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)));
    }
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final v = videos[i];
        return GestureDetector(
          onTap: () => onTap(v),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              CachedNetworkImage(
                imageUrl: v.thumbUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(height: 110,
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFE0E0E0)),
                errorWidget: (_, __, ___) => Container(height: 90,
                    color: isDark ? const Color(0xFF141414) : const Color(0xFFE0E0E0),
                    child: Center(child: Icon(Icons.broken_image_outlined,
                        color: isDark ? Colors.white12 : Colors.black26, size: 24))),
              ),
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                    ),
                  ),
                  child: Text(v.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white,
                          fontSize: 10, fontWeight: FontWeight.w500)),
                ),
              ),
              if (v.lengthMin.isNotEmpty)
                Positioned(top: 4, right: 4,
                    child: _DurationBadge(text: v.lengthMin)),
            ]),
          ),
        );
      },
    );
  }
}

// ─── Skeleton list enquanto carrega ──────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  final bool isDark;
  const _SkeletonList({required this.isDark});

  @override
  Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(top: 4),
    itemCount: 5,
    itemBuilder: (_, __) => _CardSkeleton(isDark: isDark),
  );
}

class _CardSkeleton extends StatefulWidget {
  final bool isDark;
  const _CardSkeleton({required this.isDark});
  @override
  State<_CardSkeleton> createState() => _CardSkeletonState();
}

class _CardSkeletonState extends State<_CardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  Widget _box(double w, double h, {double r = 6}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: widget.isDark
              ? const [Color(0xFF1A1A1A), Color(0xFF262626), Color(0xFF1A1A1A)]
              : const [Color(0xFFE5E5E5), Color(0xFFEEEEEE), Color(0xFFE5E5E5)],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _box(w, w * 9 / 16, r: 0),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(34, 34, r: 17),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _box(w * 0.7, 14), const SizedBox(height: 6), _box(w * 0.45, 12),
            ])),
          ]),
        ),
      ]),
    );
  }
}

// ─── Thumbnail skeleton inline ────────────────────────────────────────────────
class _ThumbSkeleton extends StatefulWidget {
  final bool isDark;
  const _ThumbSkeleton({required this.isDark});
  @override
  State<_ThumbSkeleton> createState() => _ThumbSkeletonState();
}
class _ThumbSkeletonState extends State<_ThumbSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: widget.isDark
              ? const [Color(0xFF1A1A1A), Color(0xFF252525), Color(0xFF1A1A1A)]
              : const [Color(0xFFE5E5E5), Color(0xFFEDEDED), Color(0xFFE5E5E5)],
        ),
      ),
    ),
  );
}

// ─── CountPill ────────────────────────────────────────────────────────────────
class _CountPill extends StatelessWidget {
  final int count;
  const _CountPill({required this.count});

  String get _label {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000)    return '${(count / 1000).toStringAsFixed(0)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: kPrimaryColor.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(_label,
      style: const TextStyle(color: kPrimaryColor,
          fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

// ─── DurationBadge ────────────────────────────────────────────────────────────
class _DurationBadge extends StatelessWidget {
  final String text;
  const _DurationBadge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4)),
    child: Text(text,
        style: const TextStyle(color: Colors.white,
            fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─── ErrorView ────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: Colors.white.withOpacity(0.12), size: 44),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 12)),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Tentar novamente',
              style: TextStyle(color: Colors.white.withOpacity(0.6),
                  fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    ),
  );
}
