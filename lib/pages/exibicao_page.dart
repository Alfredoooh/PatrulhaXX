import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/feed_video_model.dart';
import 'home_page.dart' show iosRoute;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// ─── SVGs ─────────────────────────────────────────────────────────────────────
const _svgSaveLater =
    '<svg id="Layer_1" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">'
    '<path d="m14.181.207a1 1 0 0 0 -1.181.983v2.879a8.053 8.053 0 1 0 6.931 6.931h2.886'
    'a1 1 0 0 0 .983-1.181 12.047 12.047 0 0 0 -9.619-9.612zm1.819 12.793h-2.277'
    'a1.994 1.994 0 1 1 -2.723-2.723v-3.277a1 1 0 0 1 2 0v3.277a2 2 0 0 1 .723.723h2.277'
    'a1 1 0 0 1 0 2zm-13.014-8.032a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm-1.6 3.987a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.167-.8z'
    'm8.742 12.868a1 1 0 1 1 -1.17.794 1 1 0 0 1 1.167-.794z'
    'm-4.12-19.923a1 1 0 1 1 -1.17.8 1 1 0 0 1 1.17-.8z'
    'm4.174-1.691a1 1 0 1 1 -1.182.771 1 1 0 0 1 1.182-.771z'
    'm-9.948 13.837a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm1.681 3.963a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm3.052 2.991a1 1 0 1 1 .8 1.17 1 1 0 0 1 -.8-1.17z'
    'm16.047-1.967a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.799z'
    'm-3.022 3.067a1 1 0 1 1 1.17-.8 1 1 0 0 1 -1.17.8z'
    'm-3.939 1.656a1 1 0 1 1 1.17-.795 1 1 0 0 1 -1.17.791z'
    'm9.659-9.756a1 1 0 1 1 -1-1 1 1 0 0 1 1 1z"/></svg>';
const _svgPlaylist =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M1,6H23a1,1,0,0,0,0-2H1A1,1,0,0,0,1,6Z"/>'
    '<path d="M23,9H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,19H1a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M23,14H9a1,1,0,0,0,0,2H23a1,1,0,0,0,0-2Z"/>'
    '<path d="M1.707,16.245l2.974-2.974a1.092,1.092,0,0,0,0-1.542L1.707,8.755'
    'A1,1,0,0,0,0,9.463v6.074A1,1,0,0,0,1.707,16.245Z"/></svg>';
const _svgPlayNext =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M5,20c0,1.381-1.119,2.5-2.5,2.5S0,21.381,0,20s1.119-2.5,2.5-2.5S5,18.619,5,20Z"/>'
    '<path d="M20.5,14H7a2.5,2.5,0,0,1,0-5H16.728l-1.293,1.293a1,1,0,0,0,1.414,1.414'
    'l1.972-1.972a2.5,2.5,0,0,0,0-3.535L16.849.793A1,1,0,0,0,15.435,2.207L16.728,3.5H7'
    'a4.5,4.5,0,0,0,0,9H20.5a2.5,2.5,0,0,1,0,5H18a1,1,0,0,0,0,2h2.5a4.5,4.5,0,0,0,0-9Z"/></svg>';

// ─────────────────────────────────────────────────────────────────────────────
// Lista de imagens de assets/images/ do app
// Adiciona ou remove conforme os ficheiros reais do teu projeto
// ─────────────────────────────────────────────────────────────────────────────
const List<String> _appStoryImages = [
  'assets/images/story_1.jpg',
  'assets/images/story_2.jpg',
  'assets/images/story_3.jpg',
  'assets/images/story_4.jpg',
  'assets/images/story_5.jpg',
  'assets/images/story_6.jpg',
  'assets/images/story_7.jpg',
  'assets/images/story_8.jpg',
];

// URL do site a publicitar
const String _brandSiteUrl = 'https://www.teusite.pt'; // ← substitui pelo teu URL

// ─────────────────────────────────────────────────────────────────────────────
// Shimmer unificado
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final double radius;
  const _Shimmer({this.width, this.height, this.radius = 6});
  @override State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _a;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();
    _a = Tween<double>(begin: -2, end: 2).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      width: widget.width, height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0), end: Alignment(_a.value + 1, 0),
          colors: AppTheme.current.shimmer,
        ),
      ),
    ),
  );
}

List<Widget> _skeletonCards(int n) => List.generate(n, (_) =>
  Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
    child: Row(children: [
      _Shimmer(width: 160, height: 90, radius: 6),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _Shimmer(width: double.infinity, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 120, height: 13),
        const SizedBox(height: 5),
        _Shimmer(width: 80, height: 11),
      ])),
    ]),
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Story Viewer — slideshow de imagens estilo Pinterest
// ─────────────────────────────────────────────────────────────────────────────
class _StoryViewer extends StatefulWidget {
  final List<String> images;
  const _StoryViewer({required this.images});
  @override State<_StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<_StoryViewer>
    with SingleTickerProviderStateMixin {
  int _current = 0;
  late final PageController _pageCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;

  @override void initState() {
    super.initState();
    _pageCtrl = PageController();
    _fadeCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 350));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override void dispose() {
    _pageCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.images.length) return;
    _fadeCtrl.forward(from: 0);
    setState(() => _current = index);
    _pageCtrl.animateToPage(index,
        duration: const Duration(milliseconds: 320), curve: Curves.easeInOut);
  }

  @override Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return const ColoredBox(
        color: Colors.black12,
        child: Center(child: Icon(Icons.image_not_supported_outlined,
            color: Colors.white38, size: 48)),
      );
    }

    return GestureDetector(
      onTapUp: (d) {
        final half = context.size!.width / 2;
        if (d.localPosition.dx < half) {
          _goTo(_current - 1);
        } else {
          _goTo(_current + 1);
        }
      },
      child: Stack(children: [
        // ── Imagens em PageView ──────────────────────────────────────────────
        PageView.builder(
          controller: _pageCtrl,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.images.length,
          onPageChanged: (i) => setState(() => _current = i),
          itemBuilder: (_, i) => FadeTransition(
            opacity: i == _current ? _fadeAnim : const AlwaysStoppedAnimation(1),
            child: Image.asset(
              widget.images[i],
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black,
                child: const Center(child: Icon(Icons.broken_image_outlined,
                    color: Colors.white24, size: 48)),
              ),
            ),
          ),
        ),

        // ── Gradiente superior (para o back button) ──────────────────────────
        Positioned(top: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xCC000000), Colors.transparent]),
            ),
          ),
        ),

        // ── Gradiente inferior ───────────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
          child: Container(
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter, end: Alignment.topCenter,
                colors: [Color(0x99000000), Colors.transparent]),
            ),
          ),
        ),

        // ── Indicadores de página (estilo Pinterest) ─────────────────────────
        Positioned(bottom: 14, left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final isActive = i == _current;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white
                      : Colors.white.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ),

        // ── Contador texto (ex: 2 / 8) ───────────────────────────────────────
        Positioned(top: 14, right: 14,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.52),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_current + 1} / ${widget.images.length}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 11.5,
                  fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão "Visitar Site" estilo Pinterest — publicita a marca
// ─────────────────────────────────────────────────────────────────────────────
class _VisitSiteButton extends StatelessWidget {
  const _VisitSiteButton();

  Future<void> _launch() async {
    final uri = Uri.parse(_brandSiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: _launch,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(14, 10, 14, 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: t.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: t.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFDDDDDD),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.language_rounded,
                size: 17, color: t.isDark ? Colors.white70 : Colors.black87),
            const SizedBox(width: 8),
            Text(
              'Visitar o site',
              style: TextStyle(
                color: t.isDark ? Colors.white : Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabeçalho da descrição (autor + título) com badge da marca
// ─────────────────────────────────────────────────────────────────────────────
class _PostHeader extends StatelessWidget {
  final FeedVideo? video;
  const _PostHeader({required this.video});

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (video == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Badge da marca / fonte
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: t.isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE5E5E5)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.storefront_rounded,
                  size: 13, color: t.textSecondary),
              const SizedBox(width: 5),
              Text(video!.sourceLabel,
                  style: TextStyle(
                      color: t.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        const SizedBox(height: 10),
        // Título
        Text(
          video!.title,
          style: TextStyle(
              color: t.text,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.3),
        ),
        if (video!.views.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(video!.views,
              style: TextStyle(
                  color: t.textHint,
                  fontSize: 12,
                  fontWeight: FontWeight.w400)),
        ],
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _RelatedCard (preservado do original)
// ─────────────────────────────────────────────────────────────────────────────
class _RelatedCard extends StatefulWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  final void Function(Offset) onMenuTap;
  final int index;

  const _RelatedCard({
    super.key,
    required this.video,
    required this.onTap,
    required this.onMenuTap,
    this.index = 0,
  });

  static Map<String, String> _headers(VideoSource src) {
    const ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
    final origins = {
      VideoSource.eporner: 'https://www.eporner.com/',
      VideoSource.pornhub: 'https://www.pornhub.com/',
      VideoSource.redtube: 'https://www.redtube.com/',
      VideoSource.youporn: 'https://www.youporn.com/',
      VideoSource.xvideos: 'https://www.xvideos.com/',
      VideoSource.xhamster: 'https://xhamster.com/',
      VideoSource.spankbang: 'https://spankbang.com/',
      VideoSource.bravotube: 'https://www.bravotube.net/',
      VideoSource.drtuber: 'https://www.drtuber.com/',
      VideoSource.txxx: 'https://www.txxx.com/',
      VideoSource.gotporn: 'https://www.gotporn.com/',
      VideoSource.porndig: 'https://www.porndig.com/',
    };
    return {
      'User-Agent': ua,
      'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
      'Accept-Language': 'pt-PT,pt;q=0.9,en;q=0.8',
      if (origins[src] != null) 'Referer': origins[src]!,
    };
  }

  @override State<_RelatedCard> createState() => _RelatedCardState();
}

class _RelatedCardState extends State<_RelatedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final Animation<double> _slide;
  late final Animation<double> _fade;

  @override void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _slide = Tween<double>(begin: 40, end: 0)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade = CurvedAnimation(parent: _ac, curve: Curves.easeOut);
    Future.delayed(Duration(milliseconds: 40 * widget.index.clamp(0, 15)), () {
      if (mounted) _ac.forward();
    });
  }

  @override void dispose() { _ac.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return AnimatedBuilder(
      animation: _ac,
      builder: (_, child) => FadeTransition(
        opacity: _fade,
        child: Transform.translate(offset: Offset(0, _slide.value), child: child),
      ),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 160, height: 90,
              child: Stack(fit: StackFit.expand, children: [
                ClipRRect(borderRadius: BorderRadius.circular(6),
                  child: _ThumbCompact(
                    url: widget.video.thumb,
                    headers: _RelatedCard._headers(widget.video.source),
                    bg: t.thumbBg)),
                if (widget.video.duration.isNotEmpty)
                  Positioned(bottom: 4, right: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(3)),
                      child: Text(widget.video.duration,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)))),
              ])),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.video.title,
                  style: TextStyle(
                      color: t.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(
                '${widget.video.sourceLabel}'
                '${widget.video.views.isNotEmpty ? "  ·  ${widget.video.views} vis." : ""}',
                style: TextStyle(color: t.textSecondary, fontSize: 11.5)),
            ])),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => widget.onMenuTap(d.globalPosition),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Icon(Icons.more_vert_rounded, color: t.iconTertiary, size: 20))),
          ]),
        ),
      ),
    );
  }
}

class _ThumbCompact extends StatefulWidget {
  final String url;
  final Map<String, String> headers;
  final Color bg;
  const _ThumbCompact({required this.url, required this.headers, required this.bg});
  @override State<_ThumbCompact> createState() => _ThumbCompactState();
}
class _ThumbCompactState extends State<_ThumbCompact> {
  int _attempt = 0; bool _failed = false;
  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    if (widget.url.isEmpty || _failed)
      return Container(color: widget.bg,
          child: Center(child: Icon(Icons.play_circle_outline_rounded,
              color: t.iconSub, size: 32)));
    return Image.network(
      _attempt == 0 ? widget.url : '${widget.url}?_r=$_attempt',
      key: ValueKey('${widget.url}_$_attempt'),
      fit: BoxFit.cover, headers: widget.headers,
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
        return Container(color: widget.bg,
            child: Center(child: Icon(Icons.play_circle_outline_rounded,
                color: t.iconSub, size: 32)));
      },
      loadingBuilder: (_, child, p) => p == null ? child : _Shimmer(radius: 0),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Secção de sugestões — rola de forma independente
// ─────────────────────────────────────────────────────────────────────────────
class _SuggestionsSection extends StatefulWidget {
  final bool loading;
  final List<FeedVideo> related;
  final void Function(FeedVideo) onVideoTap;
  final void Function(FeedVideo, Offset) onMenuTap;

  const _SuggestionsSection({
    required this.loading,
    required this.related,
    required this.onVideoTap,
    required this.onMenuTap,
  });

  @override State<_SuggestionsSection> createState() => _SuggestionsSectionState();
}

class _SuggestionsSectionState extends State<_SuggestionsSection> {
  final ScrollController _scroll = ScrollController();

  @override void dispose() { _scroll.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final t = AppTheme.current;
    return CustomScrollView(
      controller: _scroll,
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: Text('Relacionados', style: TextStyle(
                color: t.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ),
        if (widget.loading)
          SliverList(delegate: SliverChildListDelegate(_skeletonCards(5)))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) {
                if (i >= widget.related.length) return const SizedBox(height: 32);
                final v = widget.related[i];
                return _RelatedCard(
                  key: ValueKey(v.embedUrl),
                  video: v,
                  index: i,
                  onTap: () => widget.onVideoTap(v),
                  onMenuTap: (pos) => widget.onMenuTap(v, pos),
                );
              },
              childCount: widget.related.length + 1,
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ExibicaoPage — reformulada estilo Pinterest com Stories de imagens
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;
  final bool isActive;
  const ExibicaoPage({
    super.key,
    this.embedUrl,
    this.currentVideo,
    required this.onVideoTap,
    this.isActive = true,
  });
  @override State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  @override bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool _loadingRelated = false;
  FeedVideo? _nextVideo;

  late final AnimationController _enterAnim;

  bool get _isEmpty =>
      widget.embedUrl == null || widget.currentVideo == null;

  @override void initState() {
    super.initState();
    _enterAnim = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420))
      ..forward();
    if (!_isEmpty) _loadRelated();
  }

  @override void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      _enterAnim.forward(from: 0.0);
      if (!_isEmpty) _loadRelated();
    }
  }

  @override void dispose() {
    _enterAnim.dispose();
    super.dispose();
  }

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    setState(() {
      _related
        ..clear()
        ..addAll(videos
            .where((v) => v.embedUrl != widget.embedUrl)
            .take(20));
      _loadingRelated = false;
    });
  }

  void _snack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: t.toastText)),
      backgroundColor: t.toastBg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2)));
  }

  void _showVideoMenu(BuildContext ctx, FeedVideo v, Offset pos) {
    final t = AppTheme.current;
    final RenderBox overlay =
        Overlay.of(ctx).context.findRenderObject() as RenderBox;
    showMenu<String>(
      context: ctx,
      color: t.popup,
      elevation: 6,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: t.borderSoft)),
      position: RelativeRect.fromRect(
          pos & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        _popItem('save',     _svgSaveLater, 'Guardar para assistir mais tarde', t),
        _popItem('playlist', _svgPlaylist,  'Adicionar na minha playlist',      t),
        _popItem('next',     _svgPlayNext,  'Exibir como próximo vídeo',        t),
      ],
    ).then((val) {
      if (val == null || !mounted) return;
      switch (val) {
        case 'save':     _snack('Guardado para assistir mais tarde'); break;
        case 'playlist': _snack('Adicionado à playlist'); break;
        case 'next':
          setState(() => _nextVideo = v);
          _snack('Será exibido a seguir');
          break;
      }
    });
  }

  PopupMenuItem<String> _popItem(
      String val, String svg, String label, AppTheme t) =>
    PopupMenuItem<String>(
      value: val, height: 46,
      child: Row(children: [
        SvgPicture.string(svg, width: 18, height: 18,
            colorFilter: ColorFilter.mode(t.iconSub, BlendMode.srcIn)),
        const SizedBox(width: 12),
        Expanded(child: Text(label,
            style: TextStyle(color: t.text, fontSize: 13.5))),
      ]));

  @override Widget build(BuildContext context) {
    super.build(context);
    final t = AppTheme.current;
    final screenW = MediaQuery.of(context).size.width;
    // Proporção 4:3 para o story (mais visual, tipo Pinterest)
    final storyH = screenW * 3 / 4;
    final video = widget.currentVideo;

    final overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: t.isDark ? Brightness.light : Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: t.bg,
        body: SafeArea(
          bottom: false,
          child: Column(children: [

            // ── Área de imagem (Story) ────────────────────────────────────────
            AnimatedBuilder(
              animation: _enterAnim,
              builder: (_, child) => FadeTransition(
                opacity: _enterAnim,
                child: Transform.translate(
                  offset: Offset(0, (1 - _enterAnim.value) * -16),
                  child: child,
                ),
              ),
              child: ClipRRect(
                // Bordas arredondadas na imagem como no Pinterest
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: SizedBox(
                  width: screenW,
                  height: storyH,
                  child: Stack(children: [

                    // ── Story viewer com imagens do app ───────────────────
                    _StoryViewer(images: _appStoryImages),

                    // ── Botão voltar (top-left) ───────────────────────────
                    Positioned(top: 12, left: 12,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).maybePop(),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.chevron_left_rounded,
                              color: Colors.black, size: 26),
                        ),
                      ),
                    ),

                  ]),
                ),
              ),
            ),

            // ── Corpo inferior (scrollável) ──────────────────────────────────
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [

                  // Cabeçalho: autor + título
                  SliverToBoxAdapter(
                    child: _PostHeader(video: video),
                  ),

                  // Botão "Visitar o site"
                  const SliverToBoxAdapter(
                    child: _VisitSiteButton(),
                  ),

                  // Divider
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
                      child: Divider(color: t.divider, thickness: 1, height: 1),
                    ),
                  ),

                  // Banner "próximo vídeo"
                  if (_nextVideo != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
                        child: GestureDetector(
                          onTap: () {
                            if (_nextVideo != null) {
                              widget.onVideoTap(_nextVideo!);
                              setState(() => _nextVideo = null);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: t.isDark
                                  ? const Color(0xFF2A1A1A)
                                  : const Color(0xFFFFF0F0),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: t.isDark
                                      ? const Color(0xFF5A2020)
                                      : const Color(0xFFFFCCCC))),
                            child: Row(children: [
                              SvgPicture.string(_svgPlaylist,
                                  width: 15, height: 15,
                                  colorFilter: ColorFilter.mode(
                                      AppTheme.ytRed, BlendMode.srcIn)),
                              const SizedBox(width: 10),
                              Expanded(child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Seguinte:',
                                        style: TextStyle(
                                            color: AppTheme.ytRed,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 2),
                                    Text(_nextVideo!.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color: t.text,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600)),
                                    Text(_nextVideo!.sourceLabel,
                                        style: TextStyle(
                                            color: t.textSecondary,
                                            fontSize: 11)),
                                  ])),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _nextVideo = null),
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Icon(Icons.close_rounded,
                                      color: t.iconTertiary, size: 18))),
                            ]),
                          ),
                        ),
                      ),
                    ),

                  // Label "Relacionados"
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                      child: Text('Relacionados',
                          style: TextStyle(
                              color: t.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),

                  // Sugestões
                  if (_loadingRelated)
                    SliverList(
                        delegate: SliverChildListDelegate(_skeletonCards(5)))
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) {
                          if (i >= _related.length) {
                            return const SizedBox(height: 32);
                          }
                          final v = _related[i];
                          return _RelatedCard(
                            key: ValueKey(v.embedUrl),
                            video: v,
                            index: i,
                            onTap: () {
                              if (_nextVideo?.embedUrl == v.embedUrl) {
                                setState(() => _nextVideo = null);
                              }
                              Navigator.of(context).push(
                                CupertinoPageRoute(
                                  builder: (_) => ExibicaoPage(
                                    embedUrl: v.embedUrl,
                                    currentVideo: v,
                                    onVideoTap: widget.onVideoTap,
                                    isActive: true,
                                  ),
                                ),
                              );
                            },
                            onMenuTap: (pos) =>
                                _showVideoMenu(context, v, pos),
                          );
                        },
                        childCount: _related.length + 1,
                      ),
                    ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
