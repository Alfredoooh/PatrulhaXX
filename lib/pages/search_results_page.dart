import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import '../models/site_model.dart';
import 'browser_page.dart';

const _kPrimary  = Color(0xFFFF9000);
const _kBg       = Color(0xFF0C0C0C);
const _kCard     = Color(0xFF141414);
const _kDivider  = Color(0xFF1E1E1E);

// ─────────────────────────────────────────────────────────────────────────────
// Modelo
// ─────────────────────────────────────────────────────────────────────────────
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
      final last = thumbs.last as Map<String, dynamic>?;
      thumb = (last?['src'] as String?) ?? '';
    }
    if (thumb.isEmpty) {
      final dt = j['default_thumb'] as Map<String, dynamic>?;
      thumb = (dt?['src'] as String?) ?? '';
    }
    return _EpornerVideo(
      id:        (j['id'] as String?) ?? '',
      title:     (j['title'] as String?) ?? '',
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
    return '$n';
  }

  static String _fmtRate(dynamic r) {
    final f = double.tryParse(r?.toString() ?? '') ?? 0.0;
    return f.toStringAsFixed(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// API
// ─────────────────────────────────────────────────────────────────────────────
class _EpornerApi {
  static const _base = 'https://www.eporner.com/api/v2/video/search/';

  static Future<({List<_EpornerVideo> videos, int totalCount, int totalPages})>
      search({required String query, int page = 1, int perPage = 40}) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query':    query.isEmpty ? 'all' : query,
      'per_page': '$perPage',
      'page':     '$page',
      'thumbsize': 'big',
      'order':    'latest',
      'lq':       '1',
      'format':   'json',
    });
    final resp = await http.get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));
    if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}');
    final data = json.decode(resp.body) as Map<String, dynamic>;
    final rawVideos = (data['videos'] as List<dynamic>?) ?? [];
    final videos = rawVideos
        .map((v) => _EpornerVideo.fromJson(v as Map<String, dynamic>))
        .toList();
    return (
      videos:     videos,
      totalCount: (data['total_count'] as int?) ?? 0,
      totalPages: (data['total_pages'] as int?) ?? 1,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsPage
// ─────────────────────────────────────────────────────────────────────────────
class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  late final TextEditingController _q;
  late final ScrollController _scroll;

  List<_EpornerVideo> _videos = [];
  bool _loading     = true;
  bool _loadingMore = false;
  String? _error;
  int _page       = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs  = TabController(length: 2, vsync: this);
    _q     = TextEditingController(text: widget.query);
    _scroll = ScrollController()..addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _tabs.dispose(); _q.dispose(); _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _page < _totalPages) {
      _fetchMore();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) setState(() { _loading = true; _error = null; _videos = []; _page = 1; });
    try {
      final r = await _EpornerApi.search(query: _q.text.trim(), page: _page, perPage: 40);
      if (mounted) setState(() {
        _videos     = reset ? r.videos : [..._videos, ...r.videos];
        _totalCount = r.totalCount;
        _totalPages = r.totalPages;
        _loading    = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() { _loadingMore = true; _page++; });
    try {
      final r = await _EpornerApi.search(query: _q.text.trim(), page: _page, perPage: 40);
      if (mounted) setState(() { _videos.addAll(r.videos); _loadingMore = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingMore = false; _page--; });
    }
  }

  void _search() { FocusScope.of(context).unfocus(); _fetch(reset: true); }

  void _openVideo(_EpornerVideo v) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => BrowserPage(
        freeNavigation: true,
        site: SiteModel(
          id: 'ep', name: v.title, baseUrl: v.url,
          allowedDomain: '', searchUrl: v.url, primaryColor: _kPrimary),
      )));

  List<_EpornerVideo> get _allWithThumb =>
      _videos.where((v) => v.thumbUrl.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: NestedScrollView(
          controller: _scroll,
          headerSliverBuilder: (_, innerBoxIsScrolled) => [
            SliverAppBar(
              pinned: true,
              floating: true,
              snap: true,
              expandedHeight: 0,
              backgroundColor: _kBg,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.light,
              ),
              leading: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
              title: _SearchField(
                controller: _q,
                onSubmit: _search,
              ),
              titleSpacing: 0,
              actions: [
                GestureDetector(
                  onTap: _search,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(Icons.search_rounded,
                        color: Color(0xFFFF9000), size: 22),
                  ),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(44),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Divider(height: 1, color: _kDivider),
                    TabBar(
                      controller: _tabs,
                      indicator: const UnderlineTabIndicator(
                        borderSide: BorderSide(color: _kPrimary, width: 2),
                        borderRadius: BorderRadius.all(Radius.circular(1)),
                      ),
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white38,
                      labelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w400),
                      tabs: [
                        Tab(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Vídeos'),
                            if (!_loading && _totalCount > 0) ...[
                              const SizedBox(width: 6),
                              _CountPill(count: _totalCount),
                            ],
                          ]),
                        ),
                        Tab(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            const Text('Imagens'),
                            if (!_loading && _allWithThumb.isNotEmpty) ...[
                              const SizedBox(width: 6),
                              _CountPill(count: _allWithThumb.length),
                            ],
                          ]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: _loading
              ? const Center(child: CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 1.5))
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: () => _fetch(reset: true))
                  : TabBarView(
                      controller: _tabs,
                      children: [
                        _VideosTab(videos: _videos, loadingMore: _loadingMore, onTap: _openVideo),
                        _ImagesTab(videos: _allWithThumb, onTap: _openVideo),
                      ],
                    ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SearchField — barra de pesquisa minimalista no AppBar
// ─────────────────────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;
  const _SearchField({required this.controller, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSubmit(),
      cursorColor: _kPrimary,
      cursorWidth: 1.5,
      decoration: InputDecoration(
        hintText: 'Pesquisar...',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CountPill
// ─────────────────────────────────────────────────────────────────────────────
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
      color: _kPrimary.withOpacity(0.15),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(_label,
      style: const TextStyle(
        color: _kPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Vídeos
// ─────────────────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<_EpornerVideo> videos;
  final bool loadingMore;
  final void Function(_EpornerVideo) onTap;
  const _VideosTab({required this.videos, required this.loadingMore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _emptyState('Nenhum vídeo encontrado');
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: videos.length + (loadingMore ? 1 : 0),
      separatorBuilder: (_, __) => Divider(height: 1, color: _kDivider),
      itemBuilder: (_, i) {
        if (i == videos.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator(
                color: _kPrimary, strokeWidth: 1.5)),
          );
        }
        return _VideoRow(video: videos[i], onTap: () => onTap(videos[i]));
      },
    );
  }
}

// ─── Row de vídeo — thumbnail à esquerda + info à direita ────────────────────
class _VideoRow extends StatelessWidget {
  final _EpornerVideo video;
  final VoidCallback onTap;
  const _VideoRow({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 130, height: 76,
              child: Stack(fit: StackFit.expand, children: [
                video.thumbUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: video.thumbUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(color: _kCard),
                        errorWidget: (_, __, ___) => _thumbPlaceholder(),
                      )
                    : _thumbPlaceholder(),
                // Badge duração
                if (video.lengthMin.isNotEmpty)
                  Positioned(
                    bottom: 4, right: 4,
                    child: _DurationBadge(text: video.lengthMin),
                  ),
              ]),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 8),
                Row(children: [
                  if (video.views.isNotEmpty) ...[
                    Icon(Icons.visibility_outlined,
                        size: 11, color: Colors.white.withOpacity(0.3)),
                    const SizedBox(width: 3),
                    Text(video.views,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11)),
                    const SizedBox(width: 10),
                  ],
                  if (video.rate != '0.0') ...[
                    const Text('★',
                        style: TextStyle(color: _kPrimary, fontSize: 10)),
                    const SizedBox(width: 2),
                    Text(video.rate,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 11)),
                  ],
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _thumbPlaceholder() => Container(
    color: _kCard,
    child: const Center(
      child: Icon(Icons.play_circle_outline,
          color: Colors.white12, size: 28)),
  );
}

// ─── Badge duração simples ────────────────────────────────────────────────────
class _DurationBadge extends StatelessWidget {
  final String text;
  const _DurationBadge({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.75),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text,
      style: const TextStyle(
        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Imagens — grid masonry limpa
// ─────────────────────────────────────────────────────────────────────────────
class _ImagesTab extends StatelessWidget {
  final List<_EpornerVideo> videos;
  final void Function(_EpornerVideo) onTap;
  const _ImagesTab({required this.videos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _emptyState('Nenhuma imagem encontrada');
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
                placeholder: (_, __) => Container(height: 110, color: _kCard),
                errorWidget: (_, __, ___) => Container(
                  height: 90, color: _kCard,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: Colors.white12, size: 24))),
              ),
              // Gradient título
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 20, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(v.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    )),
                ),
              ),
              if (v.lengthMin.isNotEmpty)
                Positioned(
                  top: 4, right: 4,
                  child: _DurationBadge(text: v.lengthMin),
                ),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Estados vazios / erro
// ─────────────────────────────────────────────────────────────────────────────
Widget _emptyState(String msg) => Center(
  child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(Icons.search_off_rounded,
        color: Colors.white.withOpacity(0.08), size: 48),
    const SizedBox(height: 12),
    Text(msg,
      style: TextStyle(
        color: Colors.white.withOpacity(0.25), fontSize: 13)),
  ]),
);

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded,
            color: Colors.white.withOpacity(0.12), size: 44),
        const SizedBox(height: 12),
        Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.25), fontSize: 12)),
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
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ),
      ]),
    ),
  );
}
