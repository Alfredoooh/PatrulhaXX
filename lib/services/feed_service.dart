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
    required this.id, required this.title, required this.thumb,
    required this.url, this.duration = '', this.views = '', required this.source,
  });
}

class FeedService {
  static final FeedService instance = FeedService._();
  FeedService._();

  List<FeedItem> _items = [];
  bool _loaded = false;
  List<FeedItem> get items => _items;

  // Mimic a desktop browser to avoid blocks
  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36';

  static Map<String, String> get _h => {
    'User-Agent': _ua,
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'pt-PT,pt;q=0.9,en-US;q=0.8',
    'Cache-Control': 'no-cache',
  };

  Future<List<FeedItem>> load({bool force = false}) async {
    if (_loaded && !force) return _items;

    // Run all fetches in parallel; failures return []
    final results = await Future.wait([
      _ep('newest', 100),
      _ep('most-viewed', 100),
      _ep('girlfriend', 100),   // the URL from the user's message
      _ep('amateur', 100),
      _ep('teen', 100),
      _rt('newest', 100),
      _rt('most_viewed', 100),
      _xv(),
    ], eagerError: false);

    _items = results.expand((e) => e).toList()..shuffle();
    _loaded = true;
    return _items;
  }

  // ── EPorner: any category slug ─────────────────────────────────────────────
  Future<List<FeedItem>> _ep(String slug, int count) async {
    return _epUrl('https://www.eporner.com/api_xml/$slug/$count/');
  }

  Future<List<FeedItem>> _epUrl(String url) async {
    try {
      final res = await http.get(Uri.parse(url), headers: _h)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];
      final body = res.body.trim();
      if (body.isEmpty || !body.startsWith('<')) return [];

      final doc = XmlDocument.parse(body);
      final items = <FeedItem>[];

      for (final v in doc.findAllElements('video')) {
        var thumb = _x(v, 'thumb');
        var link  = _x(v, 'url');
        if (thumb.isEmpty || link.isEmpty) continue;
        if (thumb.startsWith('//')) thumb = 'https:$thumb';
        if (link.startsWith('/'))   link  = 'https://www.eporner.com$link';

        items.add(FeedItem(
          id: 'ep_${_x(v, 'id')}',
          title: _x(v, 'title').isEmpty ? 'Vídeo' : _x(v, 'title'),
          thumb: thumb, url: link,
          duration: _x(v, 'video_duration'),
          views: _x(v, 'views'),
          source: 'EPorner',
        ));
      }
      return items;
    } catch (e) {
      return [];
    }
  }

  // ── RedTube JSON ───────────────────────────────────────────────────────────
  Future<List<FeedItem>> _rt(String ordering, int count) async {
    try {
      final url =
          'https://api.redtube.com/?data=redtube.Videos.searchVideos'
          '&output=json&search=&thumbsize=medium'
          '&count=$count&ordering=$ordering';
      final res = await http.get(Uri.parse(url), headers: _h)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final videos = json['videos'] as List? ?? [];
      final items = <FeedItem>[];

      for (final v in videos) {
        final vd = (v as Map)['video'] as Map<String, dynamic>? ?? {};
        final thumb = vd['thumb'] as String? ?? '';
        final link  = vd['url']   as String? ?? '';
        if (thumb.isEmpty || link.isEmpty) continue;
        items.add(FeedItem(
          id: 'rt_${vd['video_id'] ?? ''}',
          title: vd['title'] as String? ?? 'Vídeo',
          thumb: thumb, url: link,
          duration: vd['duration'] as String? ?? '',
          views: vd['views'] as String? ?? '',
          source: 'RedTube',
        ));
      }
      return items;
    } catch (_) { return []; }
  }

  // ── XVideos RSS ────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _xv() async {
    try {
      final res = await http
          .get(Uri.parse('https://www.xvideos.com/feeds/rss-new/0'), headers: _h)
          .timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return [];

      final doc = XmlDocument.parse(res.body);
      final items = <FeedItem>[];
      for (final item in doc.findAllElements('item')) {
        final link  = _x(item, 'link');
        final title = _x(item, 'title');
        final enc   = item.findElements('enclosure').firstOrNull;
        final thumb = enc?.getAttribute('url') ?? '';
        if (link.isEmpty) continue;
        items.add(FeedItem(
          id: 'xv_${link.hashCode}',
          title: title.isEmpty ? 'Vídeo' : title,
          thumb: thumb, url: link, source: 'XVideos',
        ));
      }
      return items;
    } catch (_) { return []; }
  }

  String _x(XmlElement el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); }
    catch (_) { return ''; }
  }
}
