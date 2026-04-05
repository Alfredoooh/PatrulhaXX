import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import 'exibicao_page.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Chips de filtro
// ─────────────────────────────────────────────────────────────────────────────
enum _ChipFilter {
  todos,
  recentes,
  maisVistos,
  maisAntigos,
  amador,
  milf,
  asiatica,
  latina,
  loira,
}

const _kChipLabels = <_ChipFilter, String>{
  _ChipFilter.todos: 'Todos',
  _ChipFilter.recentes: 'Recentes',
  _ChipFilter.maisVistos: 'Mais vistos',
  _ChipFilter.maisAntigos: 'Mais antigos',
  _ChipFilter.amador: 'Amador',
  _ChipFilter.milf: 'MILF',
  _ChipFilter.asiatica: 'Asiática',
  _ChipFilter.latina: 'Latina',
  _ChipFilter.loira: 'Loira',
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
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _error = false;
  bool _fetching = false;
  bool _refreshing = false;
  int _page = 1;
  _ChipFilter _chip = _ChipFilter.todos;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetch();
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 700) {
      _fetchMore();
    }
  }

  List<FeedVideo> _filteredFor(_ChipFilter chip) {
    switch (chip) {
      case _ChipFilter.todos:
        return _videos;
      case _ChipFilter.recentes:
        return List<FeedVideo>.from(_videos);
      case _ChipFilter.maisAntigos:
        return _videos.reversed.toList();
      case _ChipFilter.maisVistos:
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

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
      _page = 1;
    });

    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) return;

      if (videos.isEmpty) {
        setState(() {
          _loading = false;
          _error = true;
        });
      } else {
        _videos
          ..clear()
          ..addAll(videos);
        _page++;
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = true;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);

    try {
      final rng = Random(DateTime.now().millisecondsSinceEpoch);
      final randomPage = rng.nextInt(20) + 1;
      final videos = await FeedFetcher.fetchAll(randomPage);

      if (!mounted) return;

      if (videos.isNotEmpty) {
        _videos
          ..clear()
          ..addAll(videos);
        _page = randomPage + 1;
      }
    } catch (_) {}

    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading || _refreshing) return;

    setState(() => _fetching = true);
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) {
        _fetching = false;
        return;
      }

      if (videos.isNotEmpty) {
        setState(() {
          _videos.addAll(videos);
          _page++;
        });
      }
    } catch (_) {}

    if (mounted) setState(() => _fetching = false);
  }

  void _openVideo(FeedVideo video) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 420),
        reverseTransitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (_, __, ___) {
          return ExibicaoPage(
            embedUrl: video.embedUrl,
            currentVideo: video,
            onVideoTap: widget.onVideoTap,
            isActive: true,
          );
        },
        transitionsBuilder: (_, animation, secondaryAnimation, child) {
          final enter = Tween<Offset>(
            begin: const Offset(0, 1.0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );

          final exit = Tween<Offset>(
            begin: Offset.zero,
            end: const Offset(0, -0.03),
          ).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
            ),
          );

          return SlideTransition(
            position: exit,
            child: SlideTransition(
              position: enter,
              child: FadeTransition(
                opacity: animation,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

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
        child: Stack(
          children: [
            Column(
              children: [
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
                            : _buildList(),
                  ),
                ),
              ],
            ),
            if (_fetching && !_loading && !_refreshing)
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(child: _DotsLoader(isDark: isDark)),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _ExploreAppBar(
                topPad: topPad,
                selectedChip: _chip,
                isDark: isDark,
                onChipChanged: (c) {
                  setState(() => _chip = c);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    final t = AppTheme.current;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, color: t.iconSub, size: 40),
          const SizedBox(height: 12),
          Text(
            'Sem ligação à internet',
            style: TextStyle(color: t.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _fetch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.ytRed,
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Text(
                'Tentar novamente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletons() {
    return ListView.separated(
      controller: _scroll,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 32),
      itemCount: 8,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => const _VideoCardSkeleton(),
    );
  }

  Widget _buildList() {
    final list = _filteredFor(_chip);

    if (list.isEmpty) {
      final t = AppTheme.current;
      return Center(
        child: Text(
          'Sem resultados',
          style: TextStyle(color: t.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      controller: _scroll,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 32),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        return _VideoCard(
          key: ValueKey(list[i].embedUrl),
          video: list[i],
          onTap: () => _openVideo(list[i]),
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
              if (mounted) {
                setState(() {
                  _pull = 0;
                  _triggered = false;
                });
              }
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              height: widget.refreshing
                  ? 44
                  : (_pull > 8 ? (_pull * 0.55).clamp(0.0, 44.0) : 0),
              child: Center(
                child: (widget.refreshing || _pull > _trigger * 0.4)
                    ? _DotsLoader(isDark: widget.isDark)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          AnimatedPadding(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              top: widget.refreshing ? 44 : (_pull * 0.4).clamp(0.0, 36.0),
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
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

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
  final bool isDark;

  const _ExploreAppBar({
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    final indicatorColor = isDark ? Colors.white : AppTheme.ytRed;

    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(
          bottom: BorderSide(color: t.divider, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
            child: Row(
              children: [
                Text(
                  'Explorar',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
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
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          style: TextStyle(
                            color: selected ? t.text : t.textSecondary,
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          ),
                          child: Text(label),
                        ),
                        Positioned(
                          bottom: -6,
                          left: 0,
                          right: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOutCubic,
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: selected ? indicatorColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(100),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de vídeo — um por linha, estilo YouTube
// ─────────────────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;

  const _VideoCard({
    super.key,
    required this.video,
    required this.onTap,
  });

  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  Map<String, String> get _headers => {
        'User-Agent': _ua,
        'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Referer': _referer,
      };

  String get _referer {
    switch (video.source) {
      case VideoSource.eporner:
        return 'https://www.eporner.com/';
      case VideoSource.pornhub:
        return 'https://www.pornhub.com/';
      case VideoSource.redtube:
        return 'https://www.redtube.com/';
      case VideoSource.youporn:
        return 'https://www.youporn.com/';
      case VideoSource.xvideos:
        return 'https://www.xvideos.com/';
      case VideoSource.xhamster:
        return 'https://xhamster.com/';
      case VideoSource.spankbang:
        return 'https://spankbang.com/';
      case VideoSource.bravotube:
        return 'https://www.bravotube.net/';
      case VideoSource.drtuber:
        return 'https://www.drtuber.com/';
      case VideoSource.txxx:
        return 'https://www.txxx.com/';
      case VideoSource.gotporn:
        return 'https://www.gotporn.com/';
      case VideoSource.porndig:
        return 'https://www.porndig.com/';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: t.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: _ThumbImg(url: video.thumb, headers: _headers),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: const BoxDecoration(
                        color: Color(0xCC000000),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                        ),
                      ),
                      child: Text(
                        video.duration,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ChannelAvatar(video: video),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title.toUpperCase(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.text,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '${video.sourceLabel} · 42 mil visualizações · há 4 dias',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: t.textSecondary,
                            fontSize: 13,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.more_vert, size: 24, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChannelAvatar extends StatelessWidget {
  final FeedVideo video;
  const _ChannelAvatar({required this.video});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: t.thumbBg,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: _ThumbImg(
        url: video.thumb,
        headers: const {},
        fit: BoxFit.cover,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Thumbnail com cached_network_image
// ─────────────────────────────────────────────────────────────────────────────
class _ThumbImg extends StatelessWidget {
  final String url;
  final Map<String, String> headers;
  final BoxFit fit;

  const _ThumbImg({
    required this.url,
    required this.headers,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    if (url.isEmpty) return _fallback(t);

    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      placeholder: (_, __) => const _Shimmer(),
      errorWidget: (_, __, ___) => _fallback(t),
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 120),
    );
  }

  Widget _fallback(AppTheme t) => Container(
        color: t.thumbBg,
        child: Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            color: t.iconSub,
            size: 32,
          ),
        ),
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
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _a,
        builder: (_, __) => Container(
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
class _VideoCardSkeleton extends StatefulWidget {
  const _VideoCardSkeleton();

  @override
  State<_VideoCardSkeleton> createState() => _VideoCardSkeletonState();
}

class _VideoCardSkeletonState extends State<_VideoCardSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;

    return AnimatedBuilder(
      animation: _a,
      builder: (_, __) => Container(
        color: t.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(_a.value - 1, 0),
                    end: Alignment(_a.value + 1, 0),
                    colors: AppTheme.current.shimmer,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment(_a.value - 1, 0),
                        end: Alignment(_a.value + 1, 0),
                        colors: AppTheme.current.shimmer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 16,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_a.value - 1, 0),
                              end: Alignment(_a.value + 1, 0),
                              colors: AppTheme.current.shimmer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 16,
                          width: 180,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_a.value - 1, 0),
                              end: Alignment(_a.value + 1, 0),
                              colors: AppTheme.current.shimmer,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment(_a.value - 1, 0),
                              end: Alignment(_a.value + 1, 0),
                              colors: AppTheme.current.shimmer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(_a.value - 1, 0),
                        end: Alignment(_a.value + 1, 0),
                        colors: AppTheme.current.shimmer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}