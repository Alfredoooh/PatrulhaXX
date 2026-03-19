import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_model.dart';
import '../services/theme_service.dart';
import 'browser_page.dart';
import 'exibicao_page.dart';
import 'home_page.dart' show kPrimaryColor, FeedVideo, FeedFetcher,
    VideoSource, faviconForSource;
import '../theme/app_theme.dart';

// SVG back — padrão do app
const _iBack =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M.88,14.09,4.75,18a1,1,0,0,0,1.42,0h0a1,1,0,0,0,0-1.42L2.61,13H23'
    'a1,1,0,0,0,1-1h0a1,1,0,0,0-1-1H2.55L6.17,7.38A1,1,0,0,0,6.17,6h0A1,1,0,0,0,'
    '4.75,6L.88,9.85A3,3,0,0,0,.88,14.09Z"/></svg>';

// SVG lupa
const _iSearch =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M23.707,22.293l-5.969-5.969a10.016,10.016,0,1,0-1.414,1.414l5.969,5.969'
    'a1,1,0,0,0,1.414-1.414ZM10,18a8,8,0,1,1,8-8A8.009,8.009,0,0,1,10,18Z"/></svg>';

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

// ─── API Eporner ──────────────────────────────────────────────────────────────
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

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  late final TextEditingController _q;
  late final ScrollController _scroll;
  final _focus = FocusNode();

  List<FeedVideo> _feedVideos  = [];
  bool _loading     = false;
  bool _loadingMore = false;
  bool _searching   = false;
  String? _error;
  int _page       = 1;
  int _totalPages = 1;

  List<String> _suggestions = [];
  List<String> _history     = [];
  static const _kHistory = 'search_history_v3';

  @override
  void initState() {
    super.initState();
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
    _q.removeListener(_onTyping);
    _q.dispose(); _scroll.dispose(); _focus.dispose();
    super.dispose();
  }

  // ── Histórico ──────────────────────────────────────────────────────────────
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

  // ── Sugestões ──────────────────────────────────────────────────────────────
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

  // ── Scroll infinito ────────────────────────────────────────────────────────
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400 &&
        !_loadingMore && _page < _totalPages) {
      _fetchMore();
    }
  }

  // ── Pesquisa ───────────────────────────────────────────────────────────────
  Future<void> _doSearch(String q) async {
    q = q.trim(); if (q.isEmpty) return;
    _focus.unfocus();
    _q.text = q;
    _q.selection = TextSelection.collapsed(offset: q.length);
    await _saveHistory(q);
    setState(() {
      _searching = true; _loading = true; _error = null;
      _feedVideos = []; _suggestions = [];
      _page = 1; _totalPages = 1;
    });
    await _fetch(reset: true);
  }

  Future<void> _fetch({bool reset = false}) async {
    try {
      final results = await Future.wait([
        _EpornerApi.search(query: _q.text.trim(), page: _page, perPage: 30),
        FeedFetcher.fetchPornhub(_page),
        FeedFetcher.fetchRedtube(_page),
      ]);
      final epResult = results[0] as ({List<_EpornerVideo> videos, int totalPages});
      final phVideos = results[1] as List<FeedVideo>;
      final rtVideos = results[2] as List<FeedVideo>;

      final epFeed = epResult.videos.map((v) => FeedVideo(
        title: v.title, thumb: v.thumbUrl,
        embedUrl: 'https://www.eporner.com/embed/${v.id}/',
        duration: v.lengthMin, views: v.views,
        source: VideoSource.eporner,
      )).toList();

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
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => ExibicaoPage(
          embedUrl: v.embedUrl, currentVideo: v,
          onVideoTap: (next) => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => ExibicaoPage(
                embedUrl: next.embedUrl, currentVideo: next,
                onVideoTap: (_) {},
              ))),
        ),
      ));
    }
  }

  void _clearSearch() {
    _q.clear();
    setState(() { _searching = false; _feedVideos = []; _suggestions = []; });
    _focus.requestFocus();
  }

  // ── Popup menu três pontinhos do AppBar ────────────────────────────────────
  void _showAppBarMenu(BuildContext ctx) {
    final t = AppTheme.current;
    final RenderBox btn = ctx.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final pos = btn.localToGlobal(Offset(btn.size.width, btn.size.height), ancestor: overlay);
    showMenu<String>(
      context: ctx,
      color: t.popup,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromLTRB(
          pos.dx - 180, pos.dy + 4, pos.dx, pos.dy + 200),
      items: [
        PopupMenuItem<String>(
          value: 'options',
          height: 46,
          child: Text('Opções de pesquisa',
              style: TextStyle(color: t.text, fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'filter',
          height: 46,
          child: Text('Filtro de pesquisa',
              style: TextStyle(color: t.text, fontSize: 14)),
        ),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      final msg = val == 'options' ? 'Opções de pesquisa' : 'Filtro de pesquisa';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: TextStyle(color: t.toastText)),
        backgroundColor: t.toastBg,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        resizeToAvoidBottomInset: false,
        body: Column(children: [

          // ── AppBar ─────────────────────────────────────────────────────────
          Container(
            color: t.appBar,
            child: Column(children: [
              SizedBox(height: topPad),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
                child: Row(children: [

                  // Back
                  GestureDetector(
                    onTap: _searching ? _clearSearch : () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: SvgPicture.string(_iBack, width: 20, height: 20,
                          colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn)),
                    ),
                  ),

                  // Campo de pesquisa
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: t.inputBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: t.inputBorder),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 12),
                        SvgPicture.string(_iSearch, width: 16, height: 16,
                            colorFilter: ColorFilter.mode(t.inputHint, BlendMode.srcIn)),
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
                              hintStyle: TextStyle(color: t.inputHint, fontSize: 14.5),
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
                              child: Icon(Icons.close_rounded,
                                  color: t.iconSub, size: 17)),
                          )
                        else
                          const SizedBox(width: 12),
                      ]),
                    ),
                  ),

                  // Três pontinhos
                  Builder(builder: (btnCtx) => GestureDetector(
                    onTap: () => _showAppBarMenu(btnCtx),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      child: Icon(Icons.more_vert_rounded, color: t.icon, size: 22),
                    ),
                  )),
                ]),
              ),
              Divider(height: 1, color: t.divider),
            ]),
          ),

          // ── Corpo ──────────────────────────────────────────────────────────
          Expanded(
            child: !_searching
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
                : _loading
                    ? _SkeletonList()
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
}

// ─────────────────────────────────────────────────────────────────────────────
// _SuggestionsView
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
                Icon(
                  showSuggestions ? Icons.search_rounded : Icons.history_rounded,
                  color: subColor, size: 20),
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
// _VideosTab — lista de vídeos estilo YouTube
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

  @override
  Widget build(BuildContext context) {
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
// _VideoCard — estilo YouTube exacto
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
    }
  }

  void _showMenu(BuildContext ctx, AppTheme t) {
    final RenderBox btn = ctx.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(ctx).context.findRenderObject() as RenderBox;
    final pos = btn.localToGlobal(
        Offset(btn.size.width, btn.size.height), ancestor: overlay);
    showMenu<String>(
      context: ctx,
      color: t.popup,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromLTRB(
          pos.dx - 200, pos.dy - 30, pos.dx, pos.dy + 200),
      items: [
        PopupMenuItem<String>(
          value: 'options',
          height: 46,
          child: Text('Opções de pesquisa',
              style: TextStyle(color: t.text, fontSize: 14)),
        ),
        PopupMenuItem<String>(
          value: 'filter',
          height: 46,
          child: Text('Filtro de pesquisa',
              style: TextStyle(color: t.text, fontSize: 14)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Thumbnail 16:9 ───────────────────────────────────────────────
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

          // ── Info — idêntica ao YouTube ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 0),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Avatar circular
              _FaviconAvatar(source: video.source, size: 36),
              const SizedBox(width: 12),

              // Título + subtítulo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                          color: t.text, fontSize: 14,
                          fontWeight: FontWeight.w500, height: 1.35),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _buildSubtitle(video),
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Three-dot
              Builder(builder: (btnCtx) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showMenu(btnCtx, t),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                  child: Icon(Icons.more_vert_rounded,
                      color: t.iconTertiary, size: 20),
                ),
              )),
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

// Thumbnail com retry (igual ao feed)
class _ThumbNet extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  const _ThumbNet({required this.url, required this.headers});
  @override State<_ThumbNet> createState() => _ThumbNetState();
}
class _ThumbNetState extends State<_ThumbNet> {
  int _attempt = 0;
  bool _failed  = false;
  @override
  Widget build(BuildContext context) {
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

// Avatar favicon
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
          decoration: BoxDecoration(color: t.avatarBg, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _SkeletonList extends StatelessWidget {
  const _SkeletonList();
  @override Widget build(BuildContext context) => ListView.builder(
    padding: const EdgeInsets.only(top: 8),
    itemCount: 5,
    itemBuilder: (_, __) => const _CardSkeleton(),
  );
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
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );

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

// ─── DurationBadge ────────────────────────────────────────────────────────────
class _DurationBadge extends StatelessWidget {
  final String text;
  const _DurationBadge({required this.text});
  @override Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(4)),
    child: Text(text, style: const TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─── ErrorView ────────────────────────────────────────────────────────────────
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
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Tentar novamente',
                  style: TextStyle(color: t.text, fontSize: 13,
                      fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      ),
    );
  }
}
