import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import '../models/site_model.dart';
import 'browser_page.dart';

// ─── Cor primária (amarelo PornHub) ──────────────────────────────────────────
const _kPrimary = Color(0xFFFF9000);
const _kBg      = Color(0xFF0E0E0E);
const _kSurface = Color(0xFF161616);

// ─────────────────────────────────────────────────────────────────────────────
// Modelo EPorner
// ─────────────────────────────────────────────────────────────────────────────
class _EpornerVideo {
  final String id, title, url, thumbUrl, lengthMin, views, rate, keywords;
  const _EpornerVideo({
    required this.id, required this.title, required this.url,
    required this.thumbUrl, required this.lengthMin,
    required this.views, required this.rate, required this.keywords,
  });

  factory _EpornerVideo.fromJson(Map<String, dynamic> j) {
    // thumbs[] array — pega o maior disponível
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
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}k';
    return '$n';
  }

  static String _fmtRate(dynamic r) {
    final f = double.tryParse(r?.toString() ?? '') ?? 0.0;
    return f.toStringAsFixed(1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EPorner API
// ─────────────────────────────────────────────────────────────────────────────
class _EpornerApi {
  static const _base = 'https://www.eporner.com/api/v2/video/search/';

  static Future<({List<_EpornerVideo> videos, int totalCount, int totalPages})>
      search({
    required String query,
    int page = 1,
    int perPage = 40,
    String order = 'latest',
    String thumbsize = 'big',
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query':    query.isEmpty ? 'all' : query,
      'per_page': '$perPage',
      'page':     '$page',
      'thumbsize': thumbsize,
      'order':    order,
      'lq':       '1',
      'format':   'json',
    });

    final resp = await http.get(uri, headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (resp.statusCode != 200) {
      throw Exception('EPorner HTTP ${resp.statusCode}');
    }

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
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _tabs  = TabController(length: 2, vsync: this);
    _q     = TextEditingController(text: widget.query);
    _scroll = ScrollController();
    _scroll.addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ── Infinite scroll ─────────────────────────────────────────────────────────
  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300 &&
        !_loadingMore && _page < _totalPages) {
      _fetchMore();
    }
  }

  Future<void> _fetch({bool reset = false}) async {
    if (reset) {
      setState(() { _loading = true; _error = null; _videos = []; _page = 1; });
    }
    try {
      final result = await _EpornerApi.search(
        query:   _q.text.trim(),
        page:    _page,
        perPage: 40,
      );
      if (mounted) {
        setState(() {
          _videos     = reset ? result.videos : [..._videos, ...result.videos];
          _totalCount = result.totalCount;
          _totalPages = result.totalPages;
          _loading    = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _fetchMore() async {
    if (_loadingMore || _page >= _totalPages) return;
    setState(() { _loadingMore = true; _page++; });
    try {
      final result = await _EpornerApi.search(
        query:   _q.text.trim(),
        page:    _page,
        perPage: 40,
      );
      if (mounted) {
        setState(() {
          _videos.addAll(result.videos);
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loadingMore = false; _page--; });
    }
  }

  void _search() {
    FocusScope.of(context).unfocus();
    _fetch(reset: true);
  }

  void _openVideo(_EpornerVideo v) => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => BrowserPage(
                freeNavigation: true,
                site: SiteModel(
                    id: 'ep',
                    name: v.title,
                    baseUrl: v.url,
                    allowedDomain: '',
                    searchUrl: v.url,
                    primaryColor: _kPrimary),
              )));

  // ── vídeos = todos os items com thumb
  // ── imagens = thumb de TODOS os items (filtro visual puro)
  List<_EpornerVideo> get _allWithThumb =>
      _videos.where((v) => v.thumbUrl.isNotEmpty).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        controller: _scroll,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── SliverAppBar ──────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            snap: true,
            backgroundColor: _kSurface.withOpacity(0.92),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            shadowColor: Colors.transparent,
            forceElevated: innerBoxIsScrolled,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded,
                  color: Colors.white, size: 22),
              onPressed: () => Navigator.pop(context),
            ),
            title: TextField(
              controller: _q,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: 'Pesquisar...',
                hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.35), fontSize: 15),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            // Sem ícone de pesquisa nas actions
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(40),
              child: TabBar(
                controller: _tabs,
                // Indicador amarelo fino
                indicator: UnderlineTabIndicator(
                  borderSide: const BorderSide(
                    color: _kPrimary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                // Linha divisória quase invisível
                dividerColor: Colors.white.withOpacity(0.06),
                dividerHeight: 0.5,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Vídeos'),
                        if (!_loading && _videos.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(count: _totalCount),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Imagens'),
                        if (!_loading && _allWithThumb.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _CountBadge(count: _allWithThumb.length),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 1.5))
            : _error != null
                ? _ErrorState(
                    message: _error!,
                    onRetry: () => _fetch(reset: true))
                : TabBarView(
                    controller: _tabs,
                    children: [
                      // ── Tab Vídeos ───────────────────────────────────
                      _VideosTab(
                        videos: _videos,
                        loadingMore: _loadingMore,
                        onTap: _openVideo,
                      ),
                      // ── Tab Imagens ──────────────────────────────────
                      _ImagesTab(
                        videos: _allWithThumb,
                        onTap: _openVideo,
                      ),
                    ],
                  ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge contagem nos tabs
// ─────────────────────────────────────────────────────────────────────────────
class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  String _fmt() {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}k';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: _kPrimary.withOpacity(0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(_fmt(),
          style: const TextStyle(
              color: _kPrimary, fontSize: 9, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Vídeos
// ─────────────────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  final List<_EpornerVideo> videos;
  final bool loadingMore;
  final void Function(_EpornerVideo) onTap;
  const _VideosTab(
      {required this.videos, required this.loadingMore, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _emptyState('Nenhum vídeo encontrado');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: videos.length + (loadingMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == videos.length) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
                child: CircularProgressIndicator(
                    color: _kPrimary, strokeWidth: 1.5)),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VideoListCard(video: videos[i], onTap: () => onTap(videos[i])),
        );
      },
    );
  }
}

// ─── Card de vídeo na lista ───────────────────────────────────────────────────
class _VideoListCard extends StatelessWidget {
  final _EpornerVideo video;
  final VoidCallback onTap;
  const _VideoListCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(10),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              video.thumbUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: video.thumbUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          Container(color: const Color(0xFF222222)),
                      errorWidget: (_, __, ___) => _thumbError(),
                    )
                  : _thumbError(),

              // Gradiente bottom
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.5, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.6)
                      ],
                    ),
                  ),
                ),
              ),

              // Badge duração
              if (video.lengthMin.isNotEmpty)
                Positioned(
                  bottom: 8, right: 8,
                  child: _Badge(text: video.lengthMin),
                ),

              // Badge rating
              if (video.rate != '0.0')
                Positioned(
                  top: 8, left: 8,
                  child: _Badge(
                    text: '★ ${video.rate}',
                    color: _kPrimary.withOpacity(0.88),
                    textColor: Colors.black,
                  ),
                ),

              // Badge views
              if (video.views.isNotEmpty)
                Positioned(
                  top: 8, right: 8,
                  child: _Badge(text: video.views),
                ),
            ]),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.4)),
              if (video.keywords.isNotEmpty) ...[
                const SizedBox(height: 5),
                Text(
                  video.keywords.split(',').take(5).join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.32),
                      fontSize: 11),
                ),
              ],
              const SizedBox(height: 8),
              Row(children: [
                _MetaChip(label: video.lengthMin, icon: Icons.schedule_rounded),
                const SizedBox(width: 8),
                _MetaChip(label: video.views, icon: Icons.visibility_outlined),
                const SizedBox(width: 8),
                _MetaChip(label: '★ ${video.rate}', icon: null),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _thumbError() => Container(
      color: const Color(0xFF1E1E1E),
      child: const Center(
          child: Icon(Icons.play_circle_outline,
              color: Colors.white12, size: 42)));
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab Imagens — StaggeredGridView com TODAS as thumbnails
// ─────────────────────────────────────────────────────────────────────────────
class _ImagesTab extends StatelessWidget {
  final List<_EpornerVideo> videos;
  final void Function(_EpornerVideo) onTap;
  const _ImagesTab({required this.videos, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (videos.isEmpty) return _emptyState('Nenhuma imagem encontrada');

    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 24),
      crossAxisCount: 2,
      mainAxisSpacing: 6,
      crossAxisSpacing: 6,
      itemCount: videos.length,
      itemBuilder: (_, i) {
        final v = videos[i];
        return GestureDetector(
          onTap: () => onTap(v),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(children: [
              CachedNetworkImage(
                imageUrl: v.thumbUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                placeholder: (_, __) => Container(
                  height: 120,
                  color: const Color(0xFF1E1E1E),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 100,
                  color: const Color(0xFF1E1E1E),
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.white12, size: 28)),
                ),
              ),
              // Overlay leve no hover / tap com título
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(6, 14, 6, 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.75),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    v.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              // Badge duração
              if (v.lengthMin.isNotEmpty)
                Positioned(
                  top: 5, right: 5,
                  child: _Badge(text: v.lengthMin),
                ),
            ]),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets auxiliares
// ─────────────────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  const _Badge({
    required this.text,
    this.color = const Color(0xCC000000),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(text,
          style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  const _MetaChip({required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, color: Colors.white24, size: 12),
        const SizedBox(width: 3),
      ],
      Text(label,
          style: TextStyle(
              color: Colors.white.withOpacity(0.35),
              fontSize: 11)),
    ]);
  }
}

Widget _emptyState(String msg) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.search_off_rounded,
            color: Colors.white.withOpacity(0.1), size: 52),
        const SizedBox(height: 12),
        Text(msg,
            style: TextStyle(
                color: Colors.white.withOpacity(0.28), fontSize: 14)),
      ]),
    );

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              color: Colors.white.withOpacity(0.15), size: 48),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3), fontSize: 12)),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kPrimary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _kPrimary.withOpacity(0.35)),
              ),
              child: const Text('Tentar novamente',
                  style: TextStyle(
                      color: _kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}
