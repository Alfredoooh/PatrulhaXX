import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../models/feed_video_model.dart';
import '../theme/app_theme.dart';
import 'exibicao_page.dart';

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

const List<double> _kRatios = [
  16/9, 4/3, 16/9, 16/9, 4/3,
  16/9, 16/9, 4/3, 16/9, 16/9,
];

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
    final px  = _scroll.position.pixels;
    final max = _scroll.position.maxScrollExtent;
    if (px > 600 != _showScrollTop) setState(() => _showScrollTop = px > 600);
    if (px >= max - 700) _fetchMore();
  }

  List<FeedVideo> _filteredFor(_ChipFilter chip) {
    switch (chip) {
      case _ChipFilter.todos:       return _videos;
      case _ChipFilter.recentes:    return List.from(_videos);
      case _ChipFilter.maisAntigos: return _videos.reversed.toList();
      case _ChipFilter.maisVistos:
        final c = List<FeedVideo>.from(_videos);
        c.sort((a, b) => _pv(b.views) - _pv(a.views));
        return c;
      case _ChipFilter.amador:   return _kw(['amador','amateur','caseiro','homemade']);
      case _ChipFilter.milf:     return _kw(['milf','mature','maduro','cougar','mom','mãe']);
      case _ChipFilter.asiatica: return _kw(['asian','asiática','japanese','korean','chinese','thai','japan']);
      case _ChipFilter.latina:   return _kw(['latina','latin','brazilian','brasileiro','colombiana','mexico']);
      case _ChipFilter.loira:    return _kw(['blonde','loira','blond','blondie']);
    }
  }

  List<FeedVideo> _kw(List<String> kws) => _videos.where((v) {
    final t = v.title.toLowerCase();
    return kws.any((k) => t.contains(k));
  }).toList();

  int _pv(String v) {
    try { return int.tryParse(v.replaceAll(RegExp(r'[^\d]'), '')) ?? 0; }
    catch (_) { return 0; }
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
      final videos = await FeedFetcher.fetchAll(rng.nextInt(20) + 1);
      if (!mounted) return;
      if (videos.isNotEmpty) { _videos.insertAll(0, videos); _page++; }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _fetchMore() async {
    if (_fetching || _loading || _refreshing) return;
    setState(() => _fetching = true);
    try {
      final videos = await FeedFetcher.fetchAll(_page);
      if (!mounted) { _fetching = false; return; }
      if (videos.isNotEmpty) setState(() { _videos.addAll(videos); _page++; });
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  void _scrollToTop() => _scroll.animateTo(0,
      duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);

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

  void _showPopup(BuildContext btnCtx) async {
    final t      = AppTheme.current;
    final isDark = t.statusBar == Brightness.light;
    final popupBg = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFFFFFFF);
    final textCol = isDark ? Colors.white            : Colors.black87;

    final RenderBox box     = btnCtx.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(btnCtx).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect pos  = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    await showMenu<String>(
      context: btnCtx,
      position: pos,
      color: popupBg,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      items: [
        PopupMenuItem(value: 'filmes',      height: 46, child: Text('Filmes',      style: TextStyle(color: textCol, fontSize: 14))),
        PopupMenuItem(value: 'meus_videos', height: 46, child: Text('Meus vídeos', style: TextStyle(color: textCol, fontSize: 14))),
        PopupMenuItem(value: 'shows',       height: 46, child: Text('Shows',       style: TextStyle(color: textCol, fontSize: 14))),
      ],
    );
  }

  @override Widget build(BuildContext context) {
    super.build(context);
    final t      = AppTheme.current;
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = t.statusBar == Brightness.light;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: t.bg,
        statusBarIconBrightness: t.statusBar,
      ),
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

            // ── Título sobe e some atrás do status bar sólido ──
            SliverAppBar(
              backgroundColor: t.bg,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              floating: false,
              expandedHeight: topPad + 44,
              // quando colapsado ocupa zero — chips ficam no limite do status bar
              toolbarHeight: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: 16, bottom: 10),
                centerTitle: false,
                expandedTitleScale: 1.0,
                title: Text('Explorar',
                  style: TextStyle(
                    color: t.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  )),
              ),
              actions: [
                Builder(builder: (btnCtx) => GestureDetector(
                  onTap: () => _showPopup(btnCtx),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 14, bottom: 10),
                    child: Icon(Icons.more_vert, color: t.text, size: 22),
                  ),
                )),
              ],
            ),

            // ── Chips pregados exactamente no limite do status bar ──
            SliverPersistentHeader(
              pinned: true,
              delegate: _ChipDelegate(
                height: 28 + 12,
                topPad: 0,
                selected: _chip,
                isDark: isDark,
                onChanged: (c) => setState(() => _chip = c),
                bg: t.bg,
              ),
            ),
          ],
          body: _loading
              ? _buildSkeletons()
              : _error ? _buildError() : _buildGrid(),
        ),
      ),
    );
  }

  Widget _buildError() {
    final t = AppTheme.current;
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
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
              color: AppTheme.ytRed, borderRadius: BorderRadius.circular(100)),
          child: const Text('Tentar novamente',
              style: TextStyle(color: Colors.white, fontSize: 13,
                  fontWeight: FontWeight.w600)))),
    ]));
  }

  Widget _buildSkeletons() {
    final colW = (MediaQuery.of(context).size.width - 30) / 2;
    return MasonryGridView.count(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 8,
      itemCount: 8,
      itemBuilder: (_, i) =>
          _SkeletonTile(height: colW / _kRatios[i % _kRatios.length]));
  }

  Widget _buildGrid() {
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
      child: MasonryGridView.count(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 32),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        itemCount: list.length + (_fetching ? 2 : 0),
        itemBuilder: (_, i) {
          if (i >= list.length) {
            final colW = (MediaQuery.of(context).size.width - 30) / 2;
            return _SkeletonTile(height: colW / _kRatios[i % _kRatios.length]);
          }
          return _VideoTile(
            key: ValueKey(list[i].embedUrl),
            video: list[i],
            ratio: _kRatios[i % _kRatios.length],
            onTap: () => _openVideo(list[i]));
        }),
    );
  }
}

// ─── Chip delegate ────────────────────────────────────────────────────────────

class _ChipDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final double topPad;
  final _ChipFilter selected;
  final void Function(_ChipFilter) onChanged;
  final bool isDark;
  final Color bg;

  const _ChipDelegate({
    required this.height,
    required this.topPad,
    required this.selected,
    required this.onChanged,
    required this.isDark,
    required this.bg,
  });

  @override double get minExtent => height;
  @override double get maxExtent => height;

  @override bool shouldRebuild(_ChipDelegate old) =>
      old.selected != selected || old.isDark != isDark ||
      old.bg != bg || old.topPad != topPad;

  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final selBg   = isDark ? Colors.white            : Colors.black;
    final selText = isDark ? Colors.black            : Colors.white;
    final unBg    = isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);
    final unText  = isDark ? Colors.white70          : Colors.black54;

    return Container(
      color: bg,
      padding: const EdgeInsets.only(top: 6, bottom: 6),
      child: SizedBox(
        height: 28,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: _ChipFilter.values.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (_, i) {
            final chip = _ChipFilter.values[i];
            final sel  = selected == chip;
            return GestureDetector(
              onTap: () => onChanged(chip),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 11),
                decoration: BoxDecoration(
                  color: sel ? selBg : unBg,
                  borderRadius: BorderRadius.circular(6)),
                alignment: Alignment.center,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: TextStyle(
                    color: sel ? selText : unText,
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500),
                  child: Text(_kChipLabels[chip]!))));
          }),
      ),
    );
  }
}

// ─── Video tile ───────────────────────────────────────────────────────────────

class _VideoTile extends StatelessWidget {
  final FeedVideo video;
  final double ratio;
  final VoidCallback onTap;

  const _VideoTile({super.key, required this.video,
      required this.ratio, required this.onTap});

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

  String _fv(String raw) {
    if (raw.isEmpty) return '';
    if (raw.contains(RegExp(r'[KkMmBb]'))) return raw;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  @override Widget build(BuildContext context) {
    final t     = AppTheme.current;
    final views = _fv(video.views);

    return GestureDetector(
      onTap: onTap,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: AspectRatio(
            aspectRatio: ratio,
            child: CachedNetworkImage(
              imageUrl: video.thumb,
              httpHeaders: _headers,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              memCacheWidth: 480,
              width: double.infinity,
              height: double.infinity,
              placeholder: (_, __) => const _Shimmer(),
              errorWidget: (_, __, ___) => Container(
                color: t.thumbBg,
                child: Center(child: Icon(Icons.play_circle_outline_rounded,
                    color: t.iconSub, size: 28))),
              fadeInDuration: const Duration(milliseconds: 200),
            )),
        ),
        const SizedBox(height: 5),
        Text(video.title,
          maxLines: 2, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: t.text, fontSize: 12,
              fontWeight: FontWeight.w600, height: 1.3)),
        const SizedBox(height: 2),
        Text(
          [video.sourceLabel, if (views.isNotEmpty) '$views vis.'].join('  ·  '),
          maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(color: t.textSecondary, fontSize: 10.5)),
        const SizedBox(height: 4),
      ]),
    );
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
    _a = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
      colors: AppTheme.current.shimmer))));
}

// ─── Skeleton tile ────────────────────────────────────────────────────────────

class _SkeletonTile extends StatefulWidget {
  final double height;
  const _SkeletonTile({required this.height});
  @override State<_SkeletonTile> createState() => _SkeletonTileState();
}
class _SkeletonTileState extends State<_SkeletonTile>
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

  Widget _box({double? w, double? h, double r = 0}) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer))));

  @override Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: _box(w: double.infinity, h: widget.height)),
      const SizedBox(height: 6),
      _box(w: double.infinity, h: 11, r: 4),
      const SizedBox(height: 4),
      _box(w: 100, h: 10, r: 4),
      const SizedBox(height: 4),
    ]);
}