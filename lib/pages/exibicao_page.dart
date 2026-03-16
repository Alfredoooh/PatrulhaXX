import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'home_page.dart' show kPrimaryColor, FeedVideo, FeedFetcher,
    VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// SVGs fornecidos pelo utilizador
const _svgDl =
    __SVG_0__;

const _svgMoreVert =
    __SVG_1__;

const _svgDlList =
    __SVG_2__;


// ─── Skeleton shimmer ─────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width, height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 6});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2).animate(
        CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(_anim.value - 1, 0),
            end: Alignment(_anim.value + 1, 0),
            colors: AppTheme.current.shimmer,
          ),
        ),
      ),
    );
  }
}

// Skeleton do player 16:9
class _PlayerSkeleton extends StatelessWidget {
  const _PlayerSkeleton();
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Player
      _Shimmer(width: w, height: w * 9 / 16, radius: 0),
      const SizedBox(height: 12),
      // Título
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Shimmer(width: w * 0.85, height: 16),
          const SizedBox(height: 6),
          _Shimmer(width: w * 0.55, height: 14),
          const SizedBox(height: 14),
          _Shimmer(width: 130, height: 34, radius: 100),
          const SizedBox(height: 20),
          Divider(color: AppTheme.current.isDark ? const Color(0xFF1C1C1C) : const Color(0xFFDDDDDD), height: 1),
          const SizedBox(height: 12),
          _Shimmer(width: 80, height: 14),
          const SizedBox(height: 12),
        ]),
      ),
      // Cards skeleton
      ..._skeletonCards(3),
    ]);
  }
}

List<Widget> _skeletonCards(int count) => List.generate(count, (_) =>
  Padding(
    padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
    child: Row(children: [
      _Shimmer(width: 160, height: 90),
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
// ExibicaoPage — player fixo no topo, conteúdo scrollável em baixo
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final FeedVideo? currentVideo;
  final void Function(FeedVideo) onVideoTap;

  const ExibicaoPage({
    super.key,
    this.embedUrl,
    this.currentVideo,
    required this.onVideoTap,
  });

  @override
  State<ExibicaoPage> createState() => _ExibicaoPageState();
}

class _ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<FeedVideo> _related = [];
  bool _loadingRelated = false;
  InAppWebViewController? _webCtrl;
  bool _titleExpanded = false;

  @override
  void initState() {
    super.initState();
    if (widget.currentVideo != null) _loadRelated();
  }

  @override
  void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo &&
        widget.currentVideo != null) {
      setState(() => _titleExpanded = false);
      _loadRelated();
    }
  }

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    final filtered =
        videos.where((v) => v.embedUrl != widget.embedUrl).take(20).toList();
    setState(() { _related
      ..clear()
      ..addAll(filtered);
      _loadingRelated = false;
    });
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = widget.currentVideo;
    if (video == null) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('A capturar link do vídeo...'),
        backgroundColor: Color(0xFF1E1E1E),
        duration: Duration(seconds: 2),
      ));
    }
    try {
      final result = await _webCtrl!.evaluateJavascript(source: r'''
        (function(){
          var v=document.querySelector('video');
          if(v&&v.src&&v.src.startsWith('http'))return v.src;
          if(v&&v.currentSrc&&v.currentSrc.startsWith('http'))return v.currentSrc;
          var s=document.querySelector('source[src]');
          if(s&&s.src&&s.src.startsWith('http'))return s.src;
          return '__none__';
        })()
      ''');
      final src = result?.toString().replaceAll('"', '').trim() ?? '__none__';
      if (!mounted) return;
      if (src == '__none__' || src.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inicia a reprodução antes de descarregar.'),
          backgroundColor: Color(0xFF1E1E1E),
        ));
        return;
      }
      // Inicia download real — aparece na lista de downloads com progresso
      DownloadService.instance.startDownload(
        url: src,
        title: video.title,
        type: 'video',
        thumbUrl: video.thumb,
        sourceUrl: video.embedUrl,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Download iniciado'),
          backgroundColor: Color(0xFF1E1E1E),
          duration: Duration(seconds: 2),
        ));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao capturar o vídeo.'),
          backgroundColor: Color(0xFF1E1E1E),
        ));
      }
    }
  }

  void _saveForLater() {
    final video = widget.currentVideo;
    if (video == null) return;
    final existing = DownloadService.instance.items
        .where((i) => i.sourceUrl == video.embedUrl)
        .toList();
    if (existing.isNotEmpty) {
      DownloadService.instance.toggleSaved(existing.first.id);
      if (mounted) {
        final saved = DownloadService.instance.isSaved(existing.first.id);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(saved ? 'Guardado para ver offline' : 'Removido dos guardados'),
          backgroundColor: const Color(0xFF1E1E1E),
        ));
      }
    } else {
      _forceDownload();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video   = widget.currentVideo;

    // Sem vídeo seleccionado
    if (widget.embedUrl == null || video == null) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: AppTheme.of(context).statusBarBrightness,
        ),
        child: Container(
          color: AppTheme.of(context).bgFeed,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.string(svgExibicaoOutline, width: 52, height: 52,
                colorFilter: const ColorFilter.mode(Colors.white24, BlendMode.srcIn)),
            const SizedBox(height: 14),
            const Text('Seleciona um vídeo no Feed',
                style: TextStyle(color: AppTheme.current.isDark ? Colors.white38 : Colors.black38, fontSize: 13.5)),
          ])),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: AppTheme.of(context).statusBarBrightness,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.of(context).bgFeed,
        body: Column(children: [

          // Status bar
          SizedBox(height: topPad),

          // ── Player FIXO — nunca sobe com o scroll ──────────────────────
          SizedBox(
            width: screenW,
            height: playerH,
            child: InAppWebView(
              key: ValueKey(widget.embedUrl),
              initialUrlRequest: URLRequest(url: WebUri(widget.embedUrl!)),
              initialSettings: InAppWebViewSettings(
                javaScriptEnabled: true,
                mediaPlaybackRequiresUserGesture: false,
                allowsInlineMediaPlayback: true,
                transparentBackground: false,
                disableDefaultErrorPage: true,
              ),
              onWebViewCreated: (ctrl) => _webCtrl = ctrl,
              shouldOverrideUrlLoading: (ctrl, action) async {
                final url = action.request.url?.toString() ?? '';
                final ok  = url.contains('/embed/') ||
                    url.contains('embed.redtube') ||
                    url.contains('youporn.com/embed') ||
                    url == widget.embedUrl ||
                    url.startsWith('about:') ||
                    url.startsWith('blob:') ||
                    url.isEmpty;
                return ok
                    ? NavigationActionPolicy.ALLOW
                    : NavigationActionPolicy.CANCEL;
              },
            ),
          ),

          // ── Scroll apenas do conteúdo abaixo ──────────────────────────
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              children: [

                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Título — 2 linhas, toca para ver tudo
                      GestureDetector(
                        onTap: () =>
                            setState(() => _titleExpanded = !_titleExpanded),
                        child: Text(
                          video.title,
                          style: TextStyle(
                            color: AppTheme.of(context).text,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: _titleExpanded ? null : 2,
                          overflow: _titleExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Favicon + fonte + views — 1 linha compacta
                      Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            faviconForSource(video.source),
                            width: 15, height: 15,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 15, height: 15),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(video.sourceLabel,
                            style: TextStyle(
                                color: AppTheme.of(context).textSub,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500)),
                        if (video.views.isNotEmpty)
                          Text('  ·  ${video.views} vis.',
                              style: TextStyle(
                                  color: AppTheme.of(context).textHint,
                                  fontSize: 11.5)),
                      ]),

                      const SizedBox(height: 12),

                      // Botão download — pill compacto com SVG
                      GestureDetector(
                        onTap: _forceDownload,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.of(context).bgCard2,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: AppTheme.of(context).bgInput),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SvgPicture.string(_svgDl,
                                width: 14, height: 14,
                                colorFilter: ColorFilter.mode(
                                    AppTheme.of(context).textSub, BlendMode.srcIn)),
                            const SizedBox(width: 7),
                            Text('Descarregar',
                                style: TextStyle(
                                    color: AppTheme.of(context).textSub,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 16),
                      Divider(
                          color: AppTheme.of(context).divider, thickness: 1, height: 1),
                      const SizedBox(height: 12),

                      Text('A seguir',
                          style: TextStyle(
                              color: AppTheme.of(context).text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Relacionados
                if (_loadingRelated)
                  Column(children: _skeletonCards(5))
                else
                  ..._related.map((v) => _RelatedCard(
                        video: v,
                        onTap: () => widget.onVideoTap(v),
                      )),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Card relacionado — horizontal, título 2 linhas max ───────────────────────
class _RelatedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _RelatedCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Thumbnail 160×90
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              SizedBox(
                width: 160, height: 90,
                child: Image.network(
                  video.thumb,
                  fit: BoxFit.cover,
                  cacheWidth: 320, // reduz memória — 2x da largura exibida
                  headers: const {'User-Agent': 'Mozilla/5.0'},
                  errorBuilder: (_, __, ___) => Container(
                    width: 160, height: 90,
                    color: AppTheme.current.card,
                    child: const Center(
                      child: Icon(Icons.play_circle_outline_rounded,
                          color: AppTheme.of(context).iconFaint, size: 28),
                    ),
                  ),
                  loadingBuilder: (_, child, p) => p == null
                      ? child
                      : _Shimmer(width: 160, height: 90),
                ),
              ),
              if (video.duration.isNotEmpty)
                Positioned(
                  bottom: 4, right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(3)),
                    child: Text(video.duration,
                        style: const TextStyle(
                            color: AppTheme.of(context).text,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),

          const SizedBox(width: 10),

          // Título + fonte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    color: AppTheme.of(context).text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Image.network(
                      faviconForSource(video.source),
                      width: 12, height: 12,
                      errorBuilder: (_, __, ___) =>
                          const SizedBox(width: 12, height: 12),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${video.sourceLabel}${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                      style: TextStyle(
                          color: AppTheme.of(context).textHint,
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ]),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(top: 1, left: 2),
            child: Icon(Icons.more_vert_rounded,
                color: AppTheme.current.isDark ? Colors.white.withOpacity(0.28) : Colors.black26, size: 18),
          ),
        ]),
      ),
    );
  }
}
