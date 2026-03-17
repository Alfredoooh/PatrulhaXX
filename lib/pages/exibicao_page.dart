import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../services/download_service.dart';
import '../theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// SVGs
const _svgDl =
    '<svg xmlns="http://www.w3.org/2000/svg" id="Outline" viewBox="0 0 24 24"><path d="M9.878,18.122a3,3,0,0,0,4.244,0l3.211-3.211A1,1,0,0,0,15.919,13.5l-2.926,2.927L13,1a1,1,0,0,0-1-1h0a1,1,0,0,0-1,1l-.009,15.408L8.081,13.5a1,1,0,0,0-1.414,1.415Z"/><path d="M23,16h0a1,1,0,0,0-1,1v4a1,1,0,0,1-1,1H3a1,1,0,0,1-1-1V17a1,1,0,0,0-1-1H1a1,1,0,0,0-1,1v4a3,3,0,0,0,3,3H21a3,3,0,0,0,3-3V17A1,1,0,0,0,23,16Z"/></svg>';

// ─── Modelo de vídeo simples ──────────────────────────────────────────────────
class VideoInfo {
  final String id, title, thumb, url, views;
  VideoInfo({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    required this.views,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> j) => VideoInfo(
        id: j['id']?.toString() ?? '',
        title: j['title'] ?? 'Sem título',
        thumb: j['default_thumb']?['src'] ?? '',
        url: j['url'] ?? '',
        views: j['views']?.toString() ?? '',
      );
}

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
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
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
          Divider(color: AppTheme.current.divider, height: 1),
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

List<Widget> _skeletonCards(int count) => List.generate(
      count,
      (_) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
        child: Row(children: [
          _Shimmer(width: 160, height: 90, radius: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Shimmer(width: double.infinity, height: 13),
                const SizedBox(height: 5),
                _Shimmer(width: 120, height: 13),
                const SizedBox(height: 5),
                _Shimmer(width: 80, height: 11),
              ],
            ),
          ),
        ]),
      ),
    );

// ─────────────────────────────────────────────────────────────────────────────
// ExibicaoPage — player fixo no topo, conteúdo scrollável em baixo
// ─────────────────────────────────────────────────────────────────────────────
class ExibicaoPage extends StatefulWidget {
  const ExibicaoPage({super.key});

  @override
  State<ExibicaoPage> createState() => ExibicaoPageState();
}

class ExibicaoPageState extends State<ExibicaoPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  VideoInfo? _currentVideo;
  final List<VideoInfo> _videos = [];
  bool _loading = true;
  bool _loadingRelated = false;
  InAppWebViewController? _webCtrl;
  bool _titleExpanded = false;
  bool _isPlayerPaused = false;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://www.eporner.com/api/v2/video/search/?query=&per_page=20&page=1'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List items = json['videos'] ?? [];
        final videos = items.map((v) => VideoInfo.fromJson(v)).toList();
        if (mounted) {
          setState(() {
            _videos.clear();
            _videos.addAll(videos);
            if (videos.isNotEmpty && _currentVideo == null) {
              _currentVideo = videos.first;
            }
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onVideoTap(VideoInfo video) {
    setState(() {
      _currentVideo = video;
      _titleExpanded = false;
      _isPlayerPaused = false;
    });
  }

  // Função para pausar player quando sai do tab
  void pausePlayer() {
    if (_webCtrl != null && !_isPlayerPaused) {
      _webCtrl!.evaluateJavascript(source: '''
        var v = document.querySelector('video');
        if (v) v.pause();
      ''');
      setState(() => _isPlayerPaused = true);
    }
  }

  // Função pública para manter o vídeo ao voltar ao tab
  void resumeIfNeeded() {
    // Não resume automaticamente, usuário decide
    setState(() {});
  }

  Future<void> _forceDownload() async {
    if (_webCtrl == null) return;
    final video = _currentVideo;
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
      await DownloadService.instance.startDownload(
        url: src,
        filename: '${video.title}.mp4',
        headers: {'User-Agent': 'Mozilla/5.0'},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Download iniciado!'),
        backgroundColor: Color(0xFF1E1E1E),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erro: $e'),
        backgroundColor: Color(0xFF1E1E1E),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return AppThemeBuilder(builder: (context, theme) {
      if (_loading) {
        return const Center(child: _PlayerSkeleton());
      }

      if (_currentVideo == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.video_library_outlined,
                  size: 64, color: theme.iconSub),
              const SizedBox(height: 16),
              Text(
                'Nenhum vídeo disponível',
                style: TextStyle(color: theme.textSub, fontSize: 16),
              ),
            ],
          ),
        );
      }

      final video = _currentVideo!;

      return Scaffold(
        backgroundColor: theme.bg,
        body: RefreshIndicator(
          onRefresh: _loadVideos,
          color: AppTheme.accent,
          child: CustomScrollView(slivers: [
            SliverAppBar(
              backgroundColor: theme.appBar,
              elevation: 0,
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text(
                'Exibição',
                style: TextStyle(
                  color: theme.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: theme.divider),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Player WebView
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      color: Colors.black,
                      child: InAppWebView(
                        initialUrlRequest: URLRequest(url: WebUri(video.url)),
                        initialSettings: InAppWebViewSettings(
                          javaScriptEnabled: true,
                          mediaPlaybackRequiresUserGesture: false,
                          allowsInlineMediaPlayback: true,
                          userAgent:
                              'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
                        ),
                        onWebViewCreated: (c) => _webCtrl = c,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info do vídeo
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Título expansível
                        GestureDetector(
                          onTap: () =>
                              setState(() => _titleExpanded = !_titleExpanded),
                          child: Text(
                            video.title,
                            style: TextStyle(
                              color: theme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                            ),
                            maxLines: _titleExpanded ? null : 2,
                            overflow: _titleExpanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // Views
                        Row(children: [
                          Text(
                            'Eporner',
                            style: TextStyle(
                              color: theme.textSub,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (video.views.isNotEmpty)
                            Text(
                              '  ·  ${video.views} vis.',
                              style: TextStyle(
                                color: theme.textHint,
                                fontSize: 11.5,
                              ),
                            ),
                        ]),

                        const SizedBox(height: 12),

                        // Botão download
                        GestureDetector(
                          onTap: _forceDownload,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: theme.cardAlt,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: theme.inputBg),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SvgPicture.string(
                                  _svgDl,
                                  width: 14,
                                  height: 14,
                                  colorFilter: ColorFilter.mode(
                                      theme.textSub, BlendMode.srcIn),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Descarregar',
                                  style: TextStyle(
                                    color: theme.textSub,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(color: theme.divider, thickness: 1, height: 1),
                        const SizedBox(height: 12),

                        Text(
                          'A seguir',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),

                  // Lista de vídeos relacionados
                  ..._videos
                      .where((v) => v.id != video.id)
                      .take(20)
                      .map((v) => _RelatedCard(
                            video: v,
                            onTap: () => _onVideoTap(v),
                          )),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ]),
        ),
      );
    });
  }
}

// ─── Card relacionado ─────────────────────────────────────────────────────────
class _RelatedCard extends StatelessWidget {
  final VideoInfo video;
  final VoidCallback onTap;
  const _RelatedCard({required this.video, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 8, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 160,
                  height: 90,
                  color: theme.thumbBg,
                  child: video.thumb.isNotEmpty
                      ? Image.network(
                          video.thumb,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.play_circle_outline,
                            color: theme.thumbIcon,
                            size: 48,
                          ),
                        )
                      : Icon(
                          Icons.play_circle_outline,
                          color: theme.thumbIcon,
                          size: 48,
                        ),
                ),
              ),

              const SizedBox(width: 10),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: TextStyle(
                        color: theme.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Eporner${video.views.isNotEmpty ? "  ·  ${video.views} vis." : ""}',
                      style: TextStyle(
                        color: theme.textHint,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              Icon(Icons.more_vert, color: theme.iconSub, size: 18),
            ],
          ),
        ),
      );
    });
  }
}
