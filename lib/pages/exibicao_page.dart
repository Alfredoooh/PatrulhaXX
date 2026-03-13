import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'home_page.dart' show kPrimaryColor, _FeedVideo, _FeedFetcher,
    _VideoSource, svgExibicaoOutline, faviconForSource;
import '../services/download_service.dart';
import 'download_list_page.dart';

// SVGs fornecidos pelo utilizador
const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">'
    '<g><path d="M210.731,386.603c24.986,25.002,65.508,25.015,90.51,0.029'
    'c0.01-0.01,0.019-0.019,0.029-0.029l68.501-68.501'
    'c7.902-8.739,7.223-22.23-1.516-30.132c-8.137-7.357-20.527-7.344-28.649,0.03'
    'l-62.421,62.443l0.149-329.109C277.333,9.551,267.782,0,256,0l0,0'
    'c-11.782,0-21.333,9.551-21.333,21.333l-0.192,328.704L172.395,288'
    'c-8.336-8.33-21.846-8.325-30.176,0.011c-8.33,8.336-8.325,21.846,0.011,30.176'
    'L210.731,386.603z"/>'
    '<path d="M490.667,341.333L490.667,341.333c-11.782,0-21.333,9.551-21.333,21.333V448'
    'c0,11.782-9.551,21.333-21.333,21.333H64c-11.782,0-21.333-9.551-21.333-21.333'
    'v-85.333c0-11.782-9.551-21.333-21.333-21.333l0,0C9.551,341.333,0,350.885,0,362.667V448'
    'c0,35.346,28.654,64,64,64h384c35.346,0,64-28.654,64-64v-85.333'
    'C512,350.885,502.449,341.333,490.667,341.333z"/></g></svg>';

const _svgMoreVert =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<circle cx="12" cy="2.5" r="2.5"/>'
    '<circle cx="12" cy="12" r="2.5"/>'
    '<circle cx="12" cy="21.5" r="2.5"/></svg>';

const _svgDlList =
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">'
    '<path d="M24,12c0,6.617-5.383,12-12,12-.815,0-1.631-.083-2.426-.246'
    '-.541-.111-.89-.64-.778-1.181,.111-.541,.638-.89,1.181-.778'
    ',.662,.136,1.343,.205,2.023,.205,5.514,0,10-4.486,10-10S17.514,2,12,2'
    'c-.643,0-1.286,.061-1.912,.182-.546,.103-1.067-.25-1.171-.792'
    '-.104-.542,.25-1.066,.792-1.171,.75-.145,1.521-.218,2.291-.218'
    ',6.617,0,12,5.383,12,12Zm-12,5.999c.569,0,1.138-.217,1.573-.65'
    'l3.136-3.142c.39-.391,.39-1.024-.002-1.415-.391-.39-1.023-.389-1.414,.001'
    'l-2.292,2.297V7c0-.552-.448-1-1-1s-1,.448-1,1V15.09l-2.292-2.297'
    'c-.39-.391-1.023-.392-1.415-.001-.391,.39-.392,1.023-.001,1.415'
    'l3.137,3.143c.433,.433,1.001,.649,1.571,.649Z'
    'm-7.301,.835c-.377-.404-1.01-.424-1.413-.046-.403,.377-.424,1.01-.046,1.413'
    ',.562,.6,1.188,1.144,1.859,1.617,.175,.123,.376,.182,.575,.182'
    ',.314,0,.624-.148,.819-.424,.318-.452,.209-1.076-.242-1.394'
    '-.56-.394-1.082-.848-1.551-1.348Z'
    'm-2.532-5.007c-.1-.543-.621-.904-1.165-.802-.543,.1-.902,.622-.802,1.165'
    ',.141,.762,.356,1.512,.641,2.229,.156,.393,.532,.632,.93,.632'
    ',.123,0,.247-.023,.368-.071,.514-.204,.765-.785,.561-1.298'
    '-.237-.597-.416-1.221-.533-1.855ZM5.099,2.182c-.671,.473-1.297,1.017-1.859,1.617'
    '-.378,.403-.357,1.036,.046,1.413,.193,.181,.438,.271,.684,.271'
    ',.267,0,.533-.106,.729-.316,.469-.5,.991-.954,1.551-1.348'
    ',.452-.318,.56-.942,.242-1.394-.317-.451-.94-.56-1.394-.242Z'
    'M2.139,7.02c-.516-.205-1.095,.047-1.298,.561-.285,.717-.5,1.467-.641,2.229'
    '-.1,.543,.259,1.065,.802,1.165,.062,.011,.123,.017,.183,.017'
    ',.473,0,.894-.337,.982-.818,.117-.634,.296-1.258,.533-1.855'
    ',.204-.513-.047-1.095-.561-1.298Z"/></svg>';

// ─────────────────────────────────────────────────────────────────────────────
// ExibicaoPage — player fixo no topo, conteúdo scrollável em baixo
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  final String? embedUrl;
  final _FeedVideo? currentVideo;
  final void Function(_FeedVideo) onVideoTap;

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

  final List<_FeedVideo> _related = [];
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
    final videos = await _FeedFetcher.fetchAll(Random().nextInt(30) + 1);
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
          statusBarIconBrightness: Brightness.light,
        ),
        child: Container(
          color: Colors.black,
          child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            SvgPicture.string(svgExibicaoOutline, width: 52, height: 52,
                colorFilter: const ColorFilter.mode(Colors.white24, BlendMode.srcIn)),
            const SizedBox(height: 14),
            const Text('Seleciona um vídeo no Feed',
                style: TextStyle(color: Colors.white38, fontSize: 13.5)),
          ])),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
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
                          style: const TextStyle(
                            color: Colors.white,
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
                                color: Colors.white.withOpacity(0.50),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500)),
                        if (video.views.isNotEmpty)
                          Text('  ·  ${video.views} views',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.40),
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
                            color: const Color(0xFF1C1C1C),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.09)),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            SvgPicture.string(_svgDl,
                                width: 14, height: 14,
                                colorFilter: const ColorFilter.mode(
                                    Colors.white60, BlendMode.srcIn)),
                            const SizedBox(width: 7),
                            const Text('Descarregar',
                                style: TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500)),
                          ]),
                        ),
                      ),

                      const SizedBox(height: 16),
                      const Divider(
                          color: Color(0xFF1C1C1C), thickness: 1, height: 1),
                      const SizedBox(height: 12),

                      const Text('A seguir',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // Relacionados
                if (_loadingRelated)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: kPrimaryColor),
                      ),
                    ),
                  )
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
  final _FeedVideo video;
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
                  errorBuilder: (_, __, ___) => Container(
                    width: 160, height: 90,
                    color: const Color(0xFF1A1A1A),
                    child: const Center(
                      child: Icon(Icons.play_circle_outline_rounded,
                          color: Colors.white24, size: 28),
                    ),
                  ),
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

          // Título + fonte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(
                    color: Colors.white,
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
                      '${video.views.isNotEmpty ? "  ·  ${video.views}" : ""}',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.40),
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
                color: Colors.white.withOpacity(0.28), size: 18),
          ),
        ]),
      ),
    );
  }
}
