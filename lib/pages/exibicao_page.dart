import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'home_page.dart' show kPrimaryColor, FeedVideo, FeedFetcher,
    VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/theme_service.dart';
import '../services/download_service.dart';
import 'download_list_page.dart';
import '../theme/app_theme.dart';

// ─── URL do vídeo padrão (carregado quando não há seleção) ───────────────────
const _kDefaultEmbedUrl =
    'https://raw.githubusercontent.com/Alfredoooh/database/main/gallery/'
    'sente-a-batida-20260318-133645-0000_5w12cAmW.mp4';

// ─── URL da página de publicidade ────────────────────────────────────────────
const _kAdsUrl = 'https://patrulhaxx.onrender.com/ads';

// ─── SVGs ─────────────────────────────────────────────────────────────────────
const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Outline" viewBox="0 0 24 24">'
    '<path d="M9.878,18.122a3,3,0,0,0,4.244,0l3.211-3.211A1,1,0,0,0,15.919,13.5'
    'l-2.926,2.927L13,1a1,1,0,0,0-1-1h0a1,1,0,0,0-1,1l-.009,15.408L8.081,13.5'
    'a1,1,0,0,0-1.414,1.415Z"/>'
    '<path d="M23,16h0a1,1,0,0,0-1,1v4a1,1,0,0,1-1,1H3a1,1,0,0,1-1-1V17a1,1,0,0,0-1-1H1'
    'a1,1,0,0,0-1,1v4a3,3,0,0,0,3,3H21a3,3,0,0,0,3-3V17A1,1,0,0,0,23,16Z"/>'
    '</svg>';

const _svgMoreVert =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="12" cy="2.5" r="2.5"/>'
    '<circle cx="12" cy="12" r="2.5"/>'
    '<circle cx="12" cy="21.5" r="2.5"/>'
    '</svg>';

const _svgDlList =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M24,12c0,6.617-5.383,12-12,12-.815,0-1.631-.083-2.426-.246-.541-.111-.89-.64'
    '-.778-1.181,.111-.541,.638-.89,1.181-.778,.662,.136,1.343,.205,2.023,.205,5.514,0,10'
    '-4.486,10-10S17.514,2,12,2c-.643,0-1.286,.061-1.912,.182-.546,.103-1.067-.25-1.171'
    '-.792-.104-.542,.25-1.066,.792-1.171,.75-.145,1.521-.218,2.291-.218,6.617,0,12,5.383'
    ',12,12Zm-12,5.999c.569,0,1.138-.217,1.573-.65l3.136-3.142c.39-.391,.39-1.024-.002'
    '-1.415-.391-.39-1.023-.389-1.414,.001l-2.292,2.297V7c0-.552-.448-1-1-1s-1,.448-1,1V15'
    '.09l-2.292-2.297c-.39-.391-1.023-.392-1.415-.001-.391,.39-.392,1.023-.001,1.415l3.137'
    ',3.143c.433,.433,1.001,.649,1.571,.649Z"/>'
    '</svg>';

// ─── Skeleton shimmer ─────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width, height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 6});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
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
      _Shimmer(width: w, height: w * 9 / 16, radius: 0),
      const SizedBox(height: 12),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _Shimmer(width: w * 0.85, height: 16),
          const SizedBox(height: 6),
          _Shimmer(width: w * 0.55, height: 14),
          const SizedBox(height: 14),
          _Shimmer(width: 130, height: 34, radius: 100),
          const SizedBox(height: 20),
          Divider(color: AppTheme.current.divider, height: 1),
          const SizedBox(height: 12),
          _Shimmer(width: 80, height: 14),
          const SizedBox(height: 12),
        ]),
      ),
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
// ExibicaoPage
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

  // Indica se está no estado "sem vídeo seleccionado" (usa embed padrão)
  bool get _isEmpty => widget.embedUrl == null || widget.currentVideo == null;

  // URL efectivo a carregar no WebView
  String get _activeEmbedUrl => widget.embedUrl ?? _kDefaultEmbedUrl;

  @override
  void initState() {
    super.initState();
    if (!_isEmpty) _loadRelated();
  }

  @override
  void didUpdateWidget(ExibicaoPage old) {
    super.didUpdateWidget(old);
    if (widget.currentVideo != old.currentVideo && !_isEmpty) {
      setState(() => _titleExpanded = false);
      _loadRelated();
    }
  }

  Future<void> _loadRelated() async {
    if (!mounted) return;
    setState(() { _loadingRelated = true; _related.clear(); });
    final videos = await FeedFetcher.fetchAll(Random().nextInt(30) + 1);
    if (!mounted) return;
    final filtered = videos
        .where((v) => v.embedUrl != widget.embedUrl)
        .take(20)
        .toList();
    setState(() {
      _related..clear()..addAll(filtered);
      _loadingRelated = false;
    });
  }

  void _snack(String msg) {
    final t = AppTheme.current;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: t.toastText)),
      backgroundColor: t.toastBg,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = widget.currentVideo;
    if (video == null) return;
    _snack('A capturar link do vídeo...');
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
        _snack('Inicia a reprodução antes de descarregar.');
        return;
      }
      DownloadService.instance.startDownload(
        url: src,
        title: video.title,
        type: 'video',
        thumbUrl: video.thumb,
        sourceUrl: video.embedUrl,
      );
      _snack('Download iniciado');
    } catch (_) {
      if (mounted) _snack('Erro ao capturar o vídeo.');
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
        _snack(saved ? 'Guardado para ver offline' : 'Removido dos guardados');
      }
    } else {
      _forceDownload();
    }
  }

  Future<void> _openAdsUrl() async {
    final uri = Uri.parse(_kAdsUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final t       = AppTheme.current;
    final topPad  = MediaQuery.of(context).padding.top;
    final screenW = MediaQuery.of(context).size.width;
    final playerH = screenW * 9 / 16;
    final video   = widget.currentVideo;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: t.statusBar,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Column(children: [

          // Status bar padding
          SizedBox(height: topPad),

          // ── Player — sempre carregado (embed padrão ou vídeo seleccionado) ─
          SizedBox(
            width: screenW,
            height: playerH,
            child: InAppWebView(
              key: ValueKey(_activeEmbedUrl),
              initialUrlRequest: URLRequest(url: WebUri(_activeEmbedUrl)),
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
                    url == _activeEmbedUrl ||
                    url.startsWith('about:') ||
                    url.startsWith('blob:') ||
                    url.isEmpty;
                return ok
                    ? NavigationActionPolicy.ALLOW
                    : NavigationActionPolicy.CANCEL;
              },
            ),
          ),

          // ── Corpo scrollável ──────────────────────────────────────────────
          Expanded(
            child: _isEmpty
                // ── Estado vazio: Lottie + link de publicidade ─────────────
                ? _EmptyBody(onAdsLinkTap: _openAdsUrl)
                // ── Estado com vídeo ────────────────────────────────────────
                : ListView(
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    children: [

                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Título
                            GestureDetector(
                              onTap: () => setState(
                                  () => _titleExpanded = !_titleExpanded),
                              child: Text(
                                video!.title,
                                style: TextStyle(
                                  color: t.text,
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

                            // Favicon + fonte + views
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
                                      color: t.textSecondary,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500)),
                              if (video.views.isNotEmpty)
                                Text('  ·  ${video.views} vis.',
                                    style: TextStyle(
                                        color: t.textHint, fontSize: 11.5)),
                            ]),

                            const SizedBox(height: 12),

                            // Botão download
                            GestureDetector(
                              onTap: _forceDownload,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: t.cardAlt,
                                  borderRadius: BorderRadius.circular(100),
                                  border: Border.all(color: t.inputBg),
                                ),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                  SvgPicture.string(_svgDl,
                                      width: 14, height: 14,
                                      colorFilter: ColorFilter.mode(
                                          t.textSecondary, BlendMode.srcIn)),
                                  const SizedBox(width: 7),
                                  Text('Descarregar',
                                      style: TextStyle(
                                          color: t.textSecondary,
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w500)),
                                ]),
                              ),
                            ),

                            const SizedBox(height: 16),
                            Divider(color: t.divider, thickness: 1, height: 1),
                            const SizedBox(height: 12),

                            Text('A seguir',
                                style: TextStyle(
                                    color: t.text,
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

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyBody — Lottie + link para publicidade
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyBody extends StatelessWidget {
  final VoidCallback onAdsLinkTap;
  const _EmptyBody({required this.onAdsLinkTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lottie — procura qualquer ficheiro .json em assets/lottie/
          SizedBox(
            width: 200,
            height: 200,
            child: Lottie.asset(
              'assets/lottie/Cat_playing_animation.json',
              repeat: true,
              animate: true,
              // Sem colorFilter — a animação tem o seu estilo próprio
              errorBuilder: (_, __, ___) => SvgPicture.string(
                svgExibicaoOutline,
                width: 72, height: 72,
                colorFilter: ColorFilter.mode(t.emptyIcon, BlendMode.srcIn),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            'Seleciona um vídeo no Feed',
            style: TextStyle(color: t.emptyText, fontSize: 13.5),
          ),

          const SizedBox(height: 20),

          // Link sublinhado — abre no navegador do telemóvel
          GestureDetector(
            onTap: onAdsLinkTap,
            child: Text(
              'Criar publicidade agora',
              style: TextStyle(
                color: t.emptyLinkText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: t.emptyLinkText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Card relacionado ─────────────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final FeedVideo video;
  final VoidCallback onTap;
  const _RelatedCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = AppTheme.current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(children: [
              SizedBox(
                width: 160, height: 90,
                child: Image.network(
                  video.thumb,
                  fit: BoxFit.cover,
                  cacheWidth: 320,
                  headers: const {'User-Agent': 'Mozilla/5.0'},
                  errorBuilder: (_, __, ___) => Container(
                    width: 160, height: 90,
                    color: t.card,
                    child: Center(child: Icon(
                        Icons.play_circle_outline_rounded,
                        color: t.iconSub, size: 28)),
                  ),
                  loadingBuilder: (_, child, p) =>
                      p == null ? child : _Shimmer(width: 160, height: 90),
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
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
            ]),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: TextStyle(
                    color: t.text,
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
                      '${video.sourceLabel}'
                      '${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                      style: TextStyle(color: t.textHint, fontSize: 11),
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
                color: t.iconTertiary, size: 18),
          ),
        ]),
      ),
    );
  }
}
