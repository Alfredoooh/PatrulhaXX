import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/app_theme.dart';
import 'home_page.dart' show FeedVideo, VideoSource, FeedFetcher, faviconForSource, iosRoute, SearchPage;

// ─────────────────────────────────────────────────────────────────────────────
// Chips de filtro
// ─────────────────────────────────────────────────────────────────────────────
enum _ChipFilter {
  todos, recentes, maisVistos, maisAntigos,
  amador, milf, asiatica, latina, loira,
}

const _kChipLabels = <_ChipFilter, String>{
  _ChipFilter.todos:       'Todos',
  _ChipFilter.recentes:    'Recentes',
  _ChipFilter.maisVistos:  'Mais vistos',
  _ChipFilter.maisAntigos: 'Mais antigos',
  _ChipFilter.amador:      'Amador',
  _ChipFilter.milf:        'MILF',
  _ChipFilter.asiatica:    'Asiática',
  _ChipFilter.latina:      'Latina',
  _ChipFilter.loira:       'Loira',
};

// ─────────────────────────────────────────────────────────────────────────────
// ExplorePage
// ─────────────────────────────────────────────────────────────────────────────
class ExplorePage extends StatefulWidget {
  final void Function(FeedVideo) onVideoTap;
  const ExplorePage({super.key, required this.onVideoTap});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedVideo> _videos = [];
  bool _loading = true;
  bool _error = false;
  bool _fetching = false;
  bool _refreshing = false;
  int _page = 1;
  _ChipFilter _chip = _ChipFilter.todos;
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
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 700) {
      _fetchMore();
    }
  }

  // ── Filtro dinâmico por chip ──────────────────────────────────────────────
  List<FeedVideo> get _filtered {
    switch (_chip) {
      case _ChipFilter.todos:
        return _videos;

      case _ChipFilter.recentes:
        // Mantém ordem original — os primeiros do feed são os mais recentes
        return List<FeedVideo>.from(_videos);

      case _ChipFilter.maisAntigos:
        // Inverte a lista — os mais antigos vêm primeiro
        return _videos.reversed.toList();

      case _ChipFilter.maisVistos:
        // Ordena por duração como proxy de popularidade
        final copy = List<FeedVideo>.from(_videos);
        copy.sort((a, b) => _parseDuration(b.duration) - _parseDuration(a.duration));
        return copy;

      case _ChipFilter.amador:
        return _byKeywords(['amador', 'amateur', 'caseiro', 'homemade']);
      case _ChipFilter.milf:
        return _byKeywords(['milf', 'mature', 'maduro', 'cougar', 'mom', 'mãe']);
      case _ChipFilter.asiatica:
        return _byKeywords(['asian', 'asiática', 'japanese', 'korean', 'chinese', 'thai', 'japan']);
      case _ChipFilter.latina:
        return _byKeywords(['latina', 'latin', 'brazilian', 'brasileiro', 'colombiana', 'mexico']);
      case _ChipFilter.loira:
        return _byKeywords(['blonde', 'loira', 'blond', 'blondie']);
    }
  }

  List<FeedVideo> _byKeywords(List<String> kws) {
    return _videos.where((v) {
      final title = v.title.toLowerCase();
      return kws.any((k) => title.contains(k));
    }).toList();
  }

  int _parseDuration(String d) {
    try {
      final parts = d.split(':').map(int.parse).toList();
      if (parts.length == 2) return parts[0] * 60 + parts[1];
      if (parts.length == 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
    } catch (_) {}
    return 0;
  }

  // ── Fetch ─────────────────────────────────────────────────────────────────
  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = false; _page = 1; });
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

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      _page = 1;
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) return;
      if (videos.isNotEmpty) {
        _videos
          ..clear()
          ..addAll(videos);
        _page++;
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading || _refreshing) return;
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Container(
        color: t.bg,
        child: Stack(children: [
          // ── Conteúdo scrollável ────────────────────────────────────────
          Column(children: [
            SizedBox(height: topPad + 96),
            Expanded(
              child: _DotsRefreshWrapper(
                isDark: isDark,
                refreshing: _refreshing,
                onRefresh: _refresh,
                child: _loading
                    ? _buildSkeletons()
                    : _error
                        ? _buildError()
                        : _buildGrid(),
              ),
            ),
          ]),

          // ── AppBar sobreposto ──────────────────────────────────────────
          Positioned(
            top: 0, left: 0, right: 0,
            child: _ExploreAppBar(
              topPad: topPad,
              selectedChip: _chip,
              isDark: isDark,
              onChipChanged: (c) => setState(() => _chip = c),
              onSearchTap: () => Navigator.push(
                  context, iosRoute(const SearchPage())),
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
      // Efeito elástico nativo iOS
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      crossAxisCount: 2,
      mainAxisSpacing: 3,
      crossAxisSpacing: 3,
      padding: const EdgeInsets.fromLTRB(3, 6, 3, 32),
      itemCount: list.length + 1,
      itemBuilder: (_, i) {
        if (i == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: _DotsLoader()),
          );
        }
        // Key por embedUrl para evitar reconstruções erradas
        return _VideoCard(
          key: ValueKey(list[i].embedUrl),
          video: list[i],
          onTap: () => widget.onVideoTap(list[i]),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Wrapper pull-to-refresh com três pontos
// ─────────────────────────────────────────────────────────────────────────────
class _DotsRefreshWrapper extends StatefulWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final bool isDark;
  final bool refreshing;

  const _DotsRefreshWrapper({
    required this.child,
    required this.onRefresh,
    required this.isDark,
    required this.refreshing,
  });

  @override
  State<_DotsRefreshWrapper> createState() => _DotsRefreshWrapperState();
}

class _DotsRefreshWrapperState extends State<_DotsRefreshWrapper> {
  static const double _trigger = 72.0;
  double _pull = 0;
  bool _triggered = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (widget.refreshing) return false;

        if (n is OverscrollNotification && n.overscroll < 0) {
          setState(() {
            _pull = (_pull + (-n.overscroll) * 0.5).clamp(0, _trigger * 1.4);
          });
        }
        if (n is ScrollEndNotification || n is ScrollUpdateNotification) {
          if (_pull >= _trigger && !_triggered && !widget.refreshing) {
            _triggered = true;
            widget.onRefresh().then((_) {
              if (mounted) setState(() { _pull = 0; _triggered = false; });
            });
          } else if (!_triggered) {
            if (n is ScrollEndNotification) {
              setState(() => _pull = 0);
            }
          }
        }
        return false;
      },
      child: Stack(
        children: [
          // Indicador de três pontos
          Positioned(
            top: 0, left: 0, right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: widget.refreshing
                  ? 44
                  : (_pull > 8 ? (_pull * 0.55).clamp(0, 44) : 0),
              child: Center(
                child: (widget.refreshing || _pull > _trigger * 0.4)
                    ? _DotsLoader(isDark: widget.isDark)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          // Conteúdo com padding animado
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              top: widget.refreshing
                  ? 44
                  : (_pull * 0.4).clamp(0, 36),
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Loader três pontos com bounce sequencial
// ─────────────────────────────────────────────────────────────────────────────
class _DotsLoader extends StatefulWidget {
  final bool isDark;
  const _DotsLoader({this.isDark = true});

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final isDark = t.statusBar == Brightness.light;
    final dotColor = isDark ? Colors.white : AppTheme.ytRed;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Fase desfasada por dot
            final raw = (_ctrl.value * 3) - i;
            final phase = (raw % 3.0).clamp(0.0, 1.0);
            final bounce = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
            final yOffset = -7.0 * Curves.easeInOut.transform(bounce);

            return Transform.translate(
              offset: Offset(0, yOffset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor.withOpacity(0.35 + 0.65 * bounce),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// AppBar do Explorar
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreAppBar extends StatelessWidget {
  final double topPad;
  final _ChipFilter selectedChip;
  final void Function(_ChipFilter) onChipChanged;
  final VoidCallback onSearchTap;
  final bool isDark;

  const _ExploreAppBar({
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.onSearchTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    // Indicator branco no escuro, primary color no claro
    final indicatorColor = isDark ? Colors.white : AppTheme.ytRed;

    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          bottom: BorderSide(color: t.divider, width: 0.5),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad),

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
                child: Icon(Icons.search_rounded, color: t.icon, size: 22),
              ),
            ),
          ]),
        ),

        // Chips com indicador rounded e animação suave
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _ChipFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (ctx, i) {
              final chip = _ChipFilter.values[i];
              final selected = selectedChip == chip;
              final label = _kChipLabels[chip]!;

              return GestureDetector(
                onTap: () => onChipChanged(chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? indicatorColor : Colors.transparent,
                        // Rounded caps via StrokeAlign — visualmente arredondado
                        width: 2.5,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                  ),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      color: selected ? t.text : t.textSecondary,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    ),
                    child: Text(label),
                  ),
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


// ─────────────────────────────────────────────────────────────────────────────
// Card de vídeo
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;

  const _VideoCard({super.key, required this.video, required this.onTap});

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
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(children: [
          _ThumbImg(url: video.thumb, headers: _headers),

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


// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail — shimmer base + fade-in da imagem quando carrega
// Evita thumbnails a aparecerem em cima umas das outras
// ─────────────────────────────────────────────────────────────────────────────
class _ThumbImg extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  const _ThumbImg({required this.url, required this.headers});

  @override
  State<_ThumbImg> createState() => _ThumbImgState();
}

class _ThumbImgState extends State<_ThumbImg> {
  bool _failed = false;
  bool _loaded = false;

  @override
  void didUpdateWidget(_ThumbImg old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) {
      _failed = false;
      _loaded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (widget.url.isEmpty || _failed) {
      return _fallback(t);
    }

    return Stack(
      children: [
        // Shimmer sempre presente por baixo
        const _Shimmer(),

        // Imagem faz fade-in quando carregada
        AnimatedOpacity(
          duration: const Duration(milliseconds: 280),
          opacity: _loaded ? 1.0 : 0.0,
          child: Image.network(
            widget.url,
            fit: BoxFit.cover,
            width: double.infinity,
            headers: widget.headers,
            frameBuilder: (_, child, frame, __) {
              if (frame != null && !_loaded) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _loaded = true);
                });
              }
              return child;
            },
            errorBuilder: (_, __, ___) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() { _failed = true; });
              });
              return _fallback(t);
            },
          ),
        ),
      ],
    );
  }

  Widget _fallback(AppTheme t) => Container(
    height: 120,
    color: t.thumbBg,
    child: Center(child: Icon(
        Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)),
  );
}


// ─────────────────────────────────────────────────────────────────────────────
// Shimmer animado
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  const _Shimmer();

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


// ─────────────────────────────────────────────────────────────────────────────
// Skeleton de carregamento
// ─────────────────────────────────────────────────────────────────────────────
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
