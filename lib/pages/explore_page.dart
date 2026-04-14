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
  // Novos vídeos carregados em baixo, aguardando inserção
  final List<FeedVideo> _pendingBottom = [];
  final ScrollController _scroll = ScrollController();

  bool _loading = true;
  bool _error = false;
  bool _fetching = false;   // carregando mais em baixo
  bool _refreshing = false; // pull-to-refresh
  bool _showScrollTop = false;
  int _page = 1;
  _ChipFilter _chip = _ChipFilter.todos;

  // Altura estimada do AppBar (topPad + título + chips + divider)
  static const double _appBarH = 96.0;

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

    // Botão de voltar ao topo
    final showTop = px > 600;
    if (showTop != _showScrollTop) setState(() => _showScrollTop = showTop);

    // Carregar mais em baixo
    if (px >= max - 700) _fetchMore();
  }

  // ── Filtros ────────────────────────────────────────────────────────────────
  List<FeedVideo> _filteredFor(_ChipFilter chip) {
    switch (chip) {
      case _ChipFilter.todos:      return _videos;
      case _ChipFilter.recentes:   return List.from(_videos);
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

  // ── Fetch inicial ──────────────────────────────────────────────────────────
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

  // ── Pull-to-refresh: mantém posição, mostra loader no topo ────────────────
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final rng = Random(DateTime.now().millisecondsSinceEpoch);
      final randomPage = rng.nextInt(20) + 1;
      final videos = await FeedFetcher.fetchAll(randomPage);
      if (!mounted) return;
      if (videos.isNotEmpty) {
        // Insere no topo sem mexer na posição de scroll
        final oldCount = _videos.length;
        _videos.insertAll(0, videos);
        _page = randomPage + 1;
        // Corrige posição para que o utilizador não salte
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scroll.hasClients) {
            final itemH = MediaQuery.of(context).size.width * 9 / 16 + 90.0;
            _scroll.jumpTo(_scroll.offset + videos.length * itemH);
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _refreshing = false);
  }

  // ── Carregar mais em baixo: acumula em _pendingBottom ─────────────────────
  Future<void> _fetchMore() async {
    if (_fetching || _loading || _refreshing) return;
    setState(() => _fetching = true);
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
            SliverAppBar(
              backgroundColor: t.bg,
              floating: true,
              snap: true,
              pinned: false,
              elevation: 0,
              toolbarHeight: 0,
              expandedHeight: topPad + _appBarH,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: _ExploreAppBar(
                  topPad: topPad,
                  selectedChip: _chip,
                  isDark: isDark,
                  onChipChanged: (c) => setState(() => _chip = c)),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(0),
                child: Container(height: 0.5, color: t.divider)),
            ),
          ],
          body: _loading
              ? _buildSkeletons()
              : _error
                  ? _buildError()
                  : _buildList(isDark),
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

  Widget _buildSkeletons() => ListView.separated(
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(0, 6, 0, 32),
    itemCount: 6,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => const _VideoCardSkeleton());

  Widget _buildList(bool isDark) {
    final list = _filteredFor(_chip);
    if (list.isEmpty) {
      final t = AppTheme.current;
      return Center(child: Text('Sem resultados',
          style: TextStyle(color: t.textSecondary, fontSize: 13)));
    }

    return RefreshIndicator(
      // Indicador nativo do Flutter — mantém posição e mostra loader
      onRefresh: _refresh,
      color: AppTheme.ytRed,
      backgroundColor: AppTheme.current.bg,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 6, 0, 32),
        itemCount: list.length + (_fetching ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == list.length) {
            // Loader de 3 pontos no fim da lista
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(child: _DotsLoader(isDark: isDark)));
          }
          return _VideoCard(
            key: ValueKey(list[i].embedUrl),
            video: list[i],
            onTap: () => _openVideo(list[i]));
        }),
    );
  }
}

// ─── AppBar ───────────────────────────────────────────────────────────────────
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

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    final indicatorColor = isDark ? Colors.white : AppTheme.ytRed;

    return Container(
      color: t.bg,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: topPad),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
          child: Text('Explorar', style: TextStyle(
              color: t.text, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5))),
        SizedBox(height: 36,
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
                        color: selected ? t.text : t.textSecondary,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w400),
                      child: Text(_kChipLabels[chip]!)),
                    Positioned(bottom: -6, left: 0, right: 0,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: selected ? indicatorColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(100)))),
                  ])));
            })),
        const SizedBox(height: 4),
      ]));
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

  // Formata visualizações reais
  String _formatViews(String raw) {
    if (raw.isEmpty) return '';
    // Se já vem formatado (ex: "1.2M", "42K") devolve directo
    if (raw.contains(RegExp(r'[KkMmBb]'))) return raw;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n == null) return raw;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return '$n';
  }

  // Formata data real
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
    final meta  = [video.sourceLabel, if (views.isNotEmpty) '$views vis.', if (date.isNotEmpty) date]
        .join('  ·  ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: t.bg,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(fit: StackFit.expand, children: [
              Positioned.fill(child: _ThumbImg(url: video.thumb, headers: _headers)),
              Positioned(right: 0, bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: const BoxDecoration(
                    color: Color(0xCC000000),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(8))),
                  child: Text(video.duration,
                      style: const TextStyle(color: Colors.white, fontSize: 12,
                          fontWeight: FontWeight.w700, height: 1)))),
            ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(width: 0), // sem avatar
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(video.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.text, fontSize: 15,
                      fontWeight: FontWeight.w600, height: 1.3)),
                const SizedBox(height: 6),
                Text(meta, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.textSecondary, fontSize: 12.5, height: 1.2)),
              ])),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.more_vert_rounded, size: 22, color: t.iconTertiary)),
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
      // filterQuality alta para imagens mais nítidas
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
    child: Center(child: Icon(Icons.play_circle_outline_rounded, color: t.iconSub, size: 32)));
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
    return Container(color: t.bg, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AspectRatio(aspectRatio: 16 / 9, child: _box()),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _box(w: double.infinity, h: 15, r: 4),
          const SizedBox(height: 8),
          _box(w: 200, h: 15, r: 4),
          const SizedBox(height: 8),
          _box(w: 140, h: 12, r: 4),
        ])),
    ]));
  }
}