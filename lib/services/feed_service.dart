import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class FeedItem {
  final String id;
  final String title;
  final String thumb;
  final String url;
  final String duration;
  final String views;
  final String source;

  const FeedItem({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    this.duration = '',
    this.views = '',
    required this.source,
  });
}

class FeedService {
  static final FeedService instance = FeedService._();
  FeedService._();

  List<FeedItem> _items = [];
  bool _loaded = false;

  List<FeedItem> get items => _items;

  Future<List<FeedItem>> load({bool force = false}) async {
    if (_loaded && !force) return _items;

    final results = await Future.wait([
      _fetchEporner(),
      _fetchRedTube(),
      _fetchXvideos(),
    ]);

    _items = results.expand((e) => e).toList()..shuffle();
    _loaded = true;
    return _items;
  }

  // ── eporner XML API ───────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchEporner() async {
    try {
      final urls = [
        'https://www.eporner.com/api_xml/newest/20/',
        'https://www.eporner.com/api_xml/most-viewed/20/',
      ];
      final List<FeedItem> items = [];
      for (final url in urls) {
        final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final v in doc.findAllElements('video')) {
          final thumb = _xmlText(v, 'thumb');
          final url2 = _xmlText(v, 'url');
          final title = _xmlText(v, 'title');
          if (thumb.isEmpty || url2.isEmpty) continue;
          items.add(FeedItem(
            id: 'ep_${_xmlText(v, 'id')}',
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb.startsWith('http') ? thumb : 'https:$thumb',
            url: url2.startsWith('http') ? url2 : 'https://www.eporner.com$url2',
            duration: _xmlText(v, 'video_duration'),
            views: _xmlText(v, 'views'),
            source: 'EPorner',
          ));
        }
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  // ── RedTube JSON API ──────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchRedTube() async {
    try {
      const url =
          'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&search=&thumbsize=medium&count=20&ordering=newest';
      final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = json['videos'] as List? ?? [];
      return videos.map((v) {
        final video = (v as Map)['video'] as Map<String, dynamic>? ?? {};
        return FeedItem(
          id: 'rt_${video['video_id'] ?? ''}',
          title: video['title'] as String? ?? 'Vídeo',
          thumb: video['thumb'] as String? ?? '',
          url: video['url'] as String? ?? 'https://www.redtube.com',
          duration: video['duration'] as String? ?? '',
          views: video['views'] as String? ?? '',
          source: 'RedTube',
        );
      }).where((f) => f.thumb.isNotEmpty && f.url.isNotEmpty).toList();
    } catch (_) {
      return [];
    }
  }

  // ── xVideos RSS ───────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchXvideos() async {
    try {
      const url = 'https://www.xvideos.com/feeds/rss-new/0';
      final res = await http.get(Uri.parse(url),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36'
          }).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return [];
      final doc = XmlDocument.parse(res.body);
      final items = <FeedItem>[];
      for (final item in doc.findAllElements('item')) {
        final link = _xmlText(item, 'link');
        final title = _xmlText(item, 'title');
        final enclosure = item.findElements('enclosure').firstOrNull;
        final thumb = enclosure?.getAttribute('url') ?? '';
        if (link.isEmpty) continue;
        items.add(FeedItem(
          id: 'xv_${link.hashCode}',
          title: title.isEmpty ? 'Vídeo' : title,
          thumb: thumb,
          url: link,
          source: 'XVideos',
        ));
      }
      return items;
    } catch (_) {
      return [];
    }
  }

  String _xmlText(XmlElement el, String tag) {
    try {
      return el.findElements(tag).first.innerText.trim();
    } catch (_) {
      return '';
    }
  }
}
