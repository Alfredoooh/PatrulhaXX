import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../theme/app_theme.dart';
import 'home_page.dart' show FeedVideo, VideoSource, FeedFetcher, faviconForSource, _iosRoute, _SearchPage;

// ─────────────────────────────────────────────────────────────────────────────
// ExplorePage — tela de explorar separada
// ─────────────────────────────────────────────────────────────────────────────
class ExplorePage extends StatefulWidget {
  final void Function(FeedVideo) onVideoTap;

  const ExplorePage({super.key, required this.onVideoTap});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

const _kExploreChips = [
  'Todos', 'Recentes', 'Mais vistos',
  'Amador', 'MILF', 'Asiática', 'Latina', 'Loira',
];

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedVideo> _videos = [];
  bool _loading = true;
  bool _error = false;
  bool _fetching = false;
  int _page = 1;
  int _selectedChip = 0;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetch();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600) {
      _fetchMore();
    }
  }

  List<FeedVideo> get _filtered {
    if (_selectedChip == 0) return _videos;
    final chip = _kExploreChips[_selectedChip].toLowerCase();
    // Chips especiais: Recentes e Mais vistos não filtram por título
    if (chip == 'recentes' || chip == 'mais vistos') return _videos;
    return _videos
        .where((v) => v.title.toLowerCase().contains(chip) ||
            v.sourceLabel.toLowerCase().contains(chip))
        .toList();
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = false; });
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) return;
      if (videos.isEmpty) {
        setState(() { _loading = false; _error = true; });
      } else {
        _videos
          ..clear()
          ..addAll(videos);
        _page++;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = true; });
    }
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading) return;
    _fetching = true;
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) { _fetching = false; return; }
      if (videos.isNotEmpty) {
        setState(() {
          _videos.addAll(videos);
          _page++;
        });
      }
    } catch (_) {}
    _fetching = false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Container(
        color: t.bg,
        child: Stack(children: [
          // ── Conteúdo scrollável ──────────────────────────────────────────
          Column(children: [
            SizedBox(height: topPad + 96), // espaço para o AppBar sobreposto
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.ytRed,
                backgroundColor: t.surface,
                onRefresh: _fetch,
                child: _loading
                    ? _buildSkeletons()
                    : _error
                        ? _buildError()
                        : _buildGrid(),
              ),
            ),
          ]),

          // ── AppBar sobreposto ────────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _ExploreAppBar(
              topPad: topPad,
              selectedChip: _selectedChip,
              onChipChanged: (i) => setState(() => _selectedChip = i),
              onSearchTap: () => Navigator.push(
                  context, _iosRoute(const _SearchPage())),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildError() {
    final t = AppTheme.current;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_off_rounded, color: t.iconSub, size: 40),
        const SizedBox(height: 12),
        Text('Sem ligação à internet',
            style: TextStyle(color: t.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _fetch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.ytRed,
              borderRadius: BorderRadius.circular(100),
            ),
            child: const Text('Tentar novamente',
                style: TextStyle(
                    color: Colors.white, fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildSkeletons() {
    return MasonryGridView.count(
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
      itemCount: 12,
      itemBuilder: (_, i) => _GridSkeleton(tall: i % 3 == 0),
    );
  }

  Widget _buildGrid() {
    final list = _filtered;
    if (list.isEmpty) {
      final t = AppTheme.current;
      return Center(
        child: Text('Sem resultados',
            style: TextStyle(color: t.textSecondary, fontSize: 13)),
      );
    }
    return MasonryGridView.count(
      controller: _scroll,
      physics: const AlwaysScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 32),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == list.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: AppTheme.ytRed),
              ),
            ),
          );
        }
        return _VideoCard(
          video: list[i],
          onTap: () => widget.onVideoTap(list[i]),
        );
      },
    );
  }
}


// ─── AppBar do Explorar ────────────────────────────────────────────────────────
class _ExploreAppBar extends StatelessWidget {
  final double topPad;
  final int selectedChip;
  final void Function(int) onChipChanged;
  final VoidCallback onSearchTap;

  const _ExploreAppBar({
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return Container(
      // Usa exatamente a mesma cor de fundo do body — sem gradiente fake
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          bottom: BorderSide(color: t.divider, width: 0.5),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad),

        // Título + botão pesquisa
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Row(children: [
            Text('Explorar',
              style: TextStyle(
                color: t.text, fontSize: 22,
                fontWeight: FontWeight.w800, letterSpacing: -0.5,
              )),
            const Spacer(),
            GestureDetector(
              onTap: onSearchTap,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: SvgPicture.asset(
                  'assets/icons/svg/search.svg', width: 20, height: 20,
                  colorFilter: ColorFilter.mode(t.icon, BlendMode.srcIn),
                ),
              ),
            ),
          ]),
        ),

        // Chips — linha indicadora em baixo
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _kExploreChips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (_, i) {
              final selected = selectedChip == i;
              return GestureDetector(
                onTap: () => onChipChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        // Usa a cor primária do AppTheme se existir, senão laranja
                        color: selected ? const Color(0xFFFF9000) : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Text(_kExploreChips[i],
                    style: TextStyle(
                      color: selected ? t.text : t.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    )),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),
      ]),
    );
  }
}


// ─── Card de vídeo minimalista (só thumbnail + duração no canto) ──────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;

  const _VideoCard({required this.video, required this.onTap});

  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  Map<String, String> get _headers => {
    'User-Agent': _ua,
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    'Referer': _referer,
  };

  String get _referer {
    switch (video.source) {
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

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(children: [
          // Thumbnail — sem AspectRatio fixo para staggered natural
          _ThumbImg(url: video.thumb, headers: _headers),

          // Overlay inferior: apenas duração (sem título — menos texto)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Color(0xBB000000), Colors.transparent],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(5, 14, 5, 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Fonte — pequena, discreta
                  Expanded(
                    child: Text(
                      video.sourceLabel,
                      style: const TextStyle(
                        color: Color(0xAAFFFFFF), fontSize: 9,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Duração
                  if (video.duration.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(video.duration,
                        style: const TextStyle(
                          color: Colors.white, fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        )),
                    ),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}


// ─── Thumbnail com loading shimmer e fallback ─────────────────────────────────
class _ThumbImg extends StatefulWidget {
  final String url;
  final Map<String, String> headers;

  const _ThumbImg({required this.url, required this.headers});

  @override
  State<_ThumbImg> createState() => _ThumbImgState();
}

class _ThumbImgState extends State<_ThumbImg> {
  bool _failed = false;

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (widget.url.isEmpty || _failed) {
      return _fallback(t);
    }

    return Image.network(
      widget.url,
      fit: BoxFit.cover,
      width: double.infinity,
      headers: widget.headers,
      errorBuilder: (_, __, ___) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _failed = true);
        });
        return _fallback(t);
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return _Shimmer();
      },
    );
  }

  Widget _fallback(AppTheme t) => Container(
    height: 120,
    color: t.thumbBg,
    child: Center(child: Icon(
        Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)),
  );
}


// ─── Shimmer animado ──────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0),
          end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );
}


// ─── Skeleton de carregamento ─────────────────────────────────────────────────
class _GridSkeleton extends StatefulWidget {
  final bool tall;
  const _GridSkeleton({this.tall = false});

  @override
  State<_GridSkeleton> createState() => _GridSkeletonState();
}

class _GridSkeletonState extends State<_GridSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: widget.tall ? 200.0 : 140.0,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(_a.value - 1, 0),
              end: Alignment(_a.value + 1, 0),
              colors: AppTheme.current.shimmer,
            ),
          ),
        ),
      ),
    );
  }
}
