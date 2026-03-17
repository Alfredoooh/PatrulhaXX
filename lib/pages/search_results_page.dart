import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';

// ─── Modelo de vídeo simples ──────────────────────────────────────────────────
class VideoInfo {
  final String id, title, thumb, url, views, duration, channel;
  VideoInfo({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    required this.views,
    required this.duration,
    required this.channel,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> j) {
    String thumb = '';
    final thumbs = j['thumbs'] as List<dynamic>?;
    if (thumbs != null && thumbs.isNotEmpty) {
      final sorted = thumbs.map((t) => t as Map).toList()
        ..sort((a, b) => ((b['width'] ?? 0) as int).compareTo((a['width'] ?? 0) as int));
      thumb = sorted.first['src'] as String? ?? '';
    }
    if (thumb.isEmpty) {
      final dt = j['default_thumb'] as Map<String, dynamic>?;
      thumb = (dt?['src'] as String?) ?? '';
    }

    return VideoInfo(
      id: j['id']?.toString() ?? '',
      title: j['title'] ?? 'Sem título',
      thumb: thumb,
      url: j['url'] ?? '',
      views: _fmtViews(j['views']),
      duration: j['length_min'] ?? '',
      channel: 'Eporner',
    );
  }

  static String _fmtViews(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(0)} mil';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)} mil';
    return n > 0 ? '$n' : '';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SearchResultsPage — Estilo YouTube
// ─────────────────────────────────────────────────────────────────────────────
class SearchResultsPage extends StatefulWidget {
  final String query;
  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<VideoInfo> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.query;
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    setState(() => _loading = true);
    try {
      final res = await http.get(Uri.parse(
          'https://www.eporner.com/api/v2/video/search/?query=${Uri.encodeComponent(widget.query)}&per_page=20&page=1'));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final List items = json['videos'] ?? [];
        setState(() {
          _videos = items.map((v) => VideoInfo.fromJson(v)).toList();
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Scaffold(
        backgroundColor: theme.bg,
        body: Column(
          children: [
            // AppBar com search
            Container(
              color: theme.appBar,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 8,
                right: 8,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: theme.icon),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.searchBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.searchBorder),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: theme.inputText),
                              decoration: InputDecoration(
                                hintText: 'Pesquisar',
                                hintStyle: TextStyle(color: theme.inputHint),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onSubmitted: (q) {
                                if (q.trim().isNotEmpty) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SearchResultsPage(query: q.trim()),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () => _searchController.clear(),
                              child: Icon(Icons.close, color: theme.iconSub, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: theme.icon),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.cast, color: theme.icon),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.icon),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Filtro "Inclui promoção paga"
            Container(
              color: theme.bg,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.chipBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 16, color: theme.iconSub),
                        const SizedBox(width: 6),
                        Text(
                          'Inclui promoção paga',
                          style: TextStyle(
                            color: theme.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.chevron_right, size: 16, color: theme.iconSub),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.volume_off, color: theme.iconSub, size: 20),
                  const SizedBox(width: 16),
                  Icon(Icons.closed_caption, color: theme.iconSub, size: 20),
                  const SizedBox(width: 16),
                  Icon(Icons.fast_forward, color: theme.iconSub, size: 20),
                ],
              ),
            ),

            Divider(color: theme.divider, height: 1),

            // Lista de vídeos
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accent),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(top: 8),
                      itemCount: _videos.length,
                      itemBuilder: (context, i) => _VideoCard(video: _videos[i], isFirst: i == 0),
                    ),
            ),
          ],
        ),
      );
    });
  }
}

// ─── Card de vídeo estilo YouTube ─────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final VideoInfo video;
  final bool isFirst;
  const _VideoCard({required this.video, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return AppThemeBuilder(builder: (context, theme) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail 16:9
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
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
                // Duração
                if (video.duration.isNotEmpty)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.durationBg,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        video.duration,
                        style: TextStyle(
                          color: theme.durationText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Info do vídeo
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar do canal
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.chipBg,
                  ),
                  child: Center(
                    child: Text(
                      'E',
                      style: TextStyle(
                        color: theme.textSub,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                // Título e metadados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${video.channel} · ${video.views} visualizações · há 18 horas',
                        style: TextStyle(
                          color: theme.textSub,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Menu
                Icon(Icons.more_vert, color: theme.iconSub, size: 20),
              ],
            ),
          ),

          // "As pessoas também viram este vídeo"
          if (isFirst)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                'As pessoas também viram este vídeo',
                style: TextStyle(
                  color: theme.textSub,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    });
  }
}
