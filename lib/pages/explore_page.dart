import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import 'exibicao_page.dart';

// ─── Chips ────────────────────────────────────────────────────────────────────
enum _ChipFilter {
  todos, recentes, maisVistos, maisAntigos,
  amador, milf, asiatica, latina, loira,
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

// ─── ExplorePage ──────────────────────────────────────────────────────────────
class ExplorePage extends StatefulWidget {
  final void Function(FeedVideo) onVideoTap;
  const ExplorePage({super.key, required this.onVideoTap});
  @override State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage>
    with AutomaticKeepAliveClientMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _videos = [];
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _error = false;
  bool _fetching = false;
  bool _refreshing = false;
  bool _showScrollTop = false;
  int _page = 1;
  _ChipFilter _chip = _ChipFilter.todos;

  @override void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _fetch();
  }

  @override void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final px = _scroll.position.pixels;
    final max = _scroll.position.maxScrollExtent;
    final showTop = px > 600;
    if (showTop != _showScrollTop) setState(() => _showScrollTop = showTop);
    if (px >= max - 700) _fetchMore();
  }

  List<FeedVideo> _filteredFor(_ChipFilter chip) {
    switch (chip) {
      case _ChipFilter.todos:       return _videos;
      case _ChipFilter.recentes:    return List.from(_videos);
      case _ChipFilter.maisAntigos: return _videos.reversed.toList();
      case _ChipFilter.maisVistos:
        final c = List<FeedVideo>.from(_videos);
        c.sort((a, b) => _parseViews(b.views) - _parseViews(a.views));
        return c;
      case _ChipFilter.amador:   return _byKw(['amador','amateur','caseiro','homemade']);
      case _ChipFilter.milf:     return _byKw(['milf','mature','maduro','cougar','mom','mãe']);
      case _ChipFilter.asiatica: return _byKw(['asian','asiática','japanese','korean','chinese','thai','japan']);
      case _ChipFilter.latina:   return _byKw(['latina','latin','brazilian','brasileiro','colombiana','mexico']);
      case _ChipFilter.loira:    return _byKw(['blonde','loira','blond','blondie']);
    }
  }

  List<FeedVideo> _byKw(List<String> kws) => _videos.where((v) {
    final t = v.title.toLowerCase();
    return kws.any((k) => t.contains(k));
  }).toList();

  int _parseViews(String v) {
    try {
      final clean = v.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(clean) ?? 0;
    } catch (_) { return 0; }
  }

  Future<void> _fetch() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = false; _page = 1; });
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) return;
      if (videos.isEmpty) {
        setState(() { _loading = false; _error = true; });
      } else {
        _videos..clear()..addAll(videos);
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
      final rng = Random(DateTime.now().millisecondsSinceEpoch);
      final randomPage = rng.nextInt(20) + 1;
      final videos = await FeedFetcher.fetchAll(randomPage);
      if (!mounted) return;
      if (videos.isNotEmpty) {
        _videos.insertAll(0, videos);
        _page = randomPage + 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            final colW = MediaQuery.of(context).size.width / 2;
            final itemH = colW * 9 / 16 + 80.0;
            _scroll.jumpTo(_scroll.offset + (videos.length / 2).ceil() * itemH);
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading || _refreshing) return;
    setState(() => _fetching = true);
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) { _fetching = false; return; }
      if (videos.isNotEmpty) {
        setState(() { _videos.addAll(videos); _page++; });
      }
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  void _scrollToTop() {
    _scroll.animateTo(0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic);
  }

  void _openVideo(FeedVideo video) {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 420),
      reverseTransitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => ExibicaoPage(
        embedUrl: video.embedUrl, currentVideo: video,
        onVideoTap: widget.onVideoTap, isActive: true),
      transitionsBuilder: (_, anim, secAnim, child) {
        final enter = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));
        final exit = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -0.03))
            .animate(CurvedAnimation(parent: secAnim, curve: Curves.easeOutCubic));
        return SlideTransition(position: exit,
          child: SlideTransition(position: enter,
            child: FadeTransition(opacity: anim, child: child)));
      },
    ));
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;

    // FIX: título compacto — topPad + 8 (padding top) + 22 (text) + 8 (padding bottom)
    final double titleExpandedH = topPad + 38;

    // FIX: chips altura inclui topPad para não ficar atrás da statusbar quando pinned
    final double chipsH = topPad + 37;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar),
      child: Scaffold(
        backgroundColor: t.bg,
        floatingActionButton: AnimatedScale(
          scale: _showScrollTop ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutBack,
          child: FloatingActionButton.small(
            onPressed: _scrollToTop,
            backgroundColor: t.isDark ? const Color(0xFF2A2A2A) : Colors.white,
            elevation: 3,
            child: Icon(Icons.keyboard_arrow_up_rounded,
                color: t.isDark ? Colors.white : AppTheme.ytRed, size: 24)),
        ),
        body: NestedScrollView(
          controller: _scroll,
          headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
            // ── Título "Explorar" — float+snap, desaparece ao scroll ──
            SliverAppBar(
              backgroundColor: t.bg,
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              toolbarHeight: 0,
              expandedHeight: titleExpandedH,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  color: t.bg,
                  alignment: Alignment.bottomLeft,
                  padding: EdgeInsets.only(
                    top: topPad + 8,
                    left: 16,
                    bottom: 8,
                  ),
                  child: Text('Explorar', style: TextStyle(
                      color: t.text,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
                ),
              ),
            ),

            // ── Chips — pinned: fica colado ao topo (acima da statusbar) ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _ChipHeaderDelegate(
                height: chipsH,
                topPad: topPad,
                selectedChip: _chip,
                isDark: isDark,
                onChipChanged: (c) => setState(() => _chip = c),
                bg: t.bg,
                dividerColor: t.divider,
              ),
            ),
          ],
          body: _loading
              ? _buildSkeletons()
              : _error
                  ? _buildError()
                  : _buildGrid(isDark),
        ),
      ),
    );
  }

  Widget _buildError() {
    final t = AppTheme.current;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.wifi_off_rounded, color: t.iconSub, size: 40),
      const SizedBox(height: 12),
      Text('Sem ligação à internet', style: TextStyle(color: t.textSecondary, fontSize: 13)),
      const SizedBox(height: 16),
      GestureDetector(
        onTap: _fetch,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(color: AppTheme.ytRed, borderRadius: BorderRadius.circular(100)),
          child: const Text('Tentar novamente',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)))),
    ]));
  }

  Widget _buildSkeletons() => GridView.builder(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 0.72,
    ),
    itemCount: 6,
    itemBuilder: (_, __) => const _VideoCardSkeleton());

  Widget _buildGrid(bool isDark) {
    final list = _filteredFor(_chip);
    if (list.isEmpty) {
      final t = AppTheme.current;
      return Center(child: Text('Sem resultados',
          style: TextStyle(color: t.textSecondary, fontSize: 13)));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppTheme.ytRed,
      backgroundColor: AppTheme.current.bg,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.72,
        ),
        itemCount: list.length + (_fetching ? 2 : 0),
        itemBuilder: (_, i) {
          if (i >= list.length) {
            return const _VideoCardSkeleton();
          }
          return _VideoCard(
            key: ValueKey(list[i].embedUrl),
            video: list[i],
            onTap: () => _openVideo(list[i]));
        }),
    );
  }
}

// ─── SliverPersistentHeader delegate para chips ───────────────────────────────
class _ChipHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final double topPad;
  final _ChipFilter selectedChip;
  final void Function(_ChipFilter) onChipChanged;
  final bool isDark;
  final Color bg;
  final Color dividerColor;

  const _ChipHeaderDelegate({
    required this.height,
    required this.topPad,
    required this.selectedChip,
    required this.onChipChanged,
    required this.isDark,
    required this.bg,
    required this.dividerColor,
  });

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override bool shouldRebuild(_ChipHeaderDelegate old) =>
      old.selectedChip != selectedChip ||
      old.isDark != isDark ||
      old.bg != bg;

  @override Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final indicatorColor = isDark ? Colors.white : AppTheme.ytRed;

    return Container(
      color: bg,
      // FIX: padding top = topPad para os chips não ficarem atrás da statusbar
      padding: EdgeInsets.only(top: topPad),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: _ChipFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 2),
            itemBuilder: (_, i) {
              final chip = _ChipFilter.values[i];
              final selected = selectedChip == chip;
              return GestureDetector(
                onTap: () => onChipChanged(chip),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Stack(clipBehavior: Clip.none, children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      style: TextStyle(
                        color: selected
                            ? (isDark ? Colors.white : Colors.black)
                            : (isDark ? Colors.white54 : Colors.black45),
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                      child: Text(_kChipLabels[chip]!)),
                    Positioned(
                      bottom: -5, left: 0, right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: selected ? indicatorColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(100)))),
                  ])));
            }),
        ),
        Container(height: 1, color: dividerColor),
      ]),
    );
  }
}

// ─── VideoCard ────────────────────────────────────────────────────────────────
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

  String _formatViews(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains(RegExp(r'[KkMmBb]'))) return raw;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'hoje';
    if (diff.inDays == 1) return 'ontem';
    if (diff.inDays < 7) return 'há ${diff.inDays} dias';
    if (diff.inDays < 30) return 'há ${(diff.inDays / 7).floor()} sem.';
    if (diff.inDays < 365) return 'há ${(diff.inDays / 30).floor()} meses';
    return 'há ${(diff.inDays / 365).floor()} anos';
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    final views = _formatViews(video.views);
    final date  = _formatDate(video.publishedAt);
    final meta  = [if (views.isNotEmpty) '$views vis.', if (date.isNotEmpty) date].join('  ·  ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0xFF1C1C1C) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.10),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail adaptável: usa AspectRatio 16/9 por defeito
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Positioned.fill(child: _ThumbImg(url: video.thumb, headers: _headers)),
              Positioned(right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(6))),
                  child: Text(video.duration,
                      style: const TextStyle(color: Colors.white, fontSize: 10,
                          fontWeight: FontWeight.w700, height: 1)))),
            ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(video.title,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.text, fontSize: 12,
                    fontWeight: FontWeight.w600, height: 1.3)),
              if (meta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary, fontSize: 10.5, height: 1.2)),
              ],
            ])),
        ]),
      ),
    );
  }
}

// ─── Thumbnail ────────────────────────────────────────────────────────────────
class _ThumbImg extends StatelessWidget {
  final String url;
  final Map<String, String> headers;
  final BoxFit fit;

  const _ThumbImg({required this.url, required this.headers, this.fit = BoxFit.cover});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (url.isEmpty) return _fallback(t);
    return CachedNetworkImage(
      imageUrl: url,
      httpHeaders: headers,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      imageBuilder: (_, img) => Image(image: img, fit: fit,
          filterQuality: FilterQuality.high,
          width: double.infinity, height: double.infinity),
      placeholder: (_, __) => const _Shimmer(),
      errorWidget: (_, __, ___) => _fallback(t),
      fadeInDuration: const Duration(milliseconds: 280),
      fadeOutDuration: const Duration(milliseconds: 120));
  }

  Widget _fallback(AppTheme t) => Container(
    color: t.thumbBg,
    child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 28)));
}

// ─── Dots Loader ──────────────────────────────────────────────────────────────
class _DotsLoader extends StatefulWidget {
  final bool isDark;
  const _DotsLoader({this.isDark = true});
  @override State<_DotsLoader> createState() => _DotsLoaderState();
}
class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    final dotColor = t.isDark ? Colors.white : AppTheme.ytRed;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final raw = (_ctrl.value * 3) - i;
          final phase = (raw % 3.0).clamp(0.0, 1.0);
          final bounce = phase < 0.5 ? phase * 2 : (1.0 - phase) * 2;
          return Transform.translate(
            offset: Offset(0, -7.0 * Curves.easeInOut.transform(bounce)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: dotColor.withOpacity(0.35 + 0.65 * bounce),
                borderRadius: BorderRadius.circular(100))));
        })));
  }
}

// ─── Shimmer ──────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  const _Shimmer();
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      decoration: BoxDecoration(gradient: LinearGradient(
        begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
        colors: AppTheme.current.shimmer))));
}

// ─── Skeleton ─────────────────────────────────────────────────────────────────
class _VideoCardSkeleton extends StatefulWidget {
  const _VideoCardSkeleton();
  @override State<_VideoCardSkeleton> createState() => _VideoCardSkeletonState();
}
class _VideoCardSkeletonState extends State<_VideoCardSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }

  Widget _box({double? w, double? h, double r = 0}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer))));

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Container(
      decoration: BoxDecoration(
        color: t.isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(t.isDark ? 0.35 : 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 16 / 9, child: _box()),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(w: double.infinity, h: 12, r: 4),
            const SizedBox(height: 6),
            _box(w: double.infinity, h: 12, r: 4),
            const SizedBox(height: 6),
            _box(w: 80, h: 10, r: 4),
          ])),
      ]));
  }
}