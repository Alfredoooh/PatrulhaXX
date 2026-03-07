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
  final String type; // 'video' | 'article'

  const FeedItem({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    this.duration = '',
    this.views = '',
    required this.source,
    this.type = 'video',
  });
}

class FeedService {
  static final FeedService instance = FeedService._();
  FeedService._();

  List<FeedItem> _items = [];
  bool _loaded = false;
  List<FeedItem> get items => _items;

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  Future<List<FeedItem>> load({bool force = false}) async {
    if (_loaded && !force) return _items;

    final results = await Future.wait([
      _fetchRedTube(),
      _fetchEporner(),
      _fetchPornHub(),
      _fetchXVideos(),
      _fetchPornDig(),
      _fetchBlogs(),
    ]);

    final all = results.expand((e) => e).toList()
      ..removeWhere((f) => f.url.isEmpty)
      ..shuffle();

    _items = all;
    _loaded = all.isNotEmpty;
    return _items;
  }

  /// Pesquisa local nos itens já carregados
  List<FeedItem> search(String query) {
    if (query.trim().isEmpty) return _items;
    final q = query.toLowerCase();
    return _items.where((i) =>
        i.title.toLowerCase().contains(q) ||
        i.source.toLowerCase().contains(q)).toList();
  }

  // ── RedTube JSON API (confirmado a funcionar) ─────────────────────────────
  // Documentação: https://api.redtube.com/
  Future<List<FeedItem>> _fetchRedTube() async {
    final endpoints = [
      'https://api.redtube.com/?data=redtube.Videos.searchVideos'
          '&output=json&search=&thumbsize=big&count=60&ordering=newest',
      'https://api.redtube.com/?data=redtube.Videos.searchVideos'
          '&output=json&search=&thumbsize=big&count=60&ordering=mostviewed',
      'https://api.redtube.com/?data=redtube.Videos.searchVideos'
          '&output=json&search=&thumbsize=big&count=60&ordering=hottest',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = json['videos'] as List? ?? [];
        for (final v in videos) {
          final vm = (v as Map)['video'] as Map<String, dynamic>? ?? {};
          final thumb = vm['thumb'] as String? ?? '';
          final vUrl  = vm['url']   as String? ?? '';
          if (thumb.isEmpty || vUrl.isEmpty) continue;
          items.add(FeedItem(
            id:       'rt_${vm['video_id'] ?? items.length}',
            title:    vm['title']    as String? ?? 'Vídeo',
            thumb:    thumb,
            url:      vUrl,
            duration: vm['duration'] as String? ?? '',
            views:    vm['views']    as String? ?? '',
            source:   'RedTube',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── EPorner API v2 JSON (confirmado: https://github.com/eporner/API) ──────
  // Endpoint real: https://www.eporner.com/api/v2/video/search/
  // Parâmetros: per_page, page, order, format=json, thumbsize
  // order: latest | top-weekly | top-monthly | top-alltime
  Future<List<FeedItem>> _fetchEporner() async {
    final endpoints = [
      'https://www.eporner.com/api/v2/video/search/'
          '?per_page=60&page=1&order=latest&format=json&thumbsize=big',
      'https://www.eporner.com/api/v2/video/search/'
          '?per_page=60&page=1&order=top-weekly&format=json&thumbsize=big',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = json['videos'] as List? ?? [];
        for (final v in videos) {
          final vm = v as Map<String, dynamic>;
          // thumbs é array de {src, size}
          final thumbList = vm['thumbs'] as List?;
          final thumb = thumbList != null && thumbList.isNotEmpty
              ? (thumbList.last['src'] as String? ?? '')
              : (vm['thumb'] as String? ?? '');
          final vUrl = vm['url'] as String? ?? '';
          if (thumb.isEmpty || vUrl.isEmpty) continue;
          items.add(FeedItem(
            id:       'ep_${vm['id'] ?? items.length}',
            title:    vm['title']       as String? ?? 'Vídeo',
            thumb:    thumb,
            url:      vUrl.startsWith('http') ? vUrl : 'https://www.eporner.com$vUrl',
            duration: vm['length_min']  as String? ?? '',
            views:    vm['views']       as String? ?? '',
            source:   'EPorner',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── PornHub RSS Webmasters (confirmado) ───────────────────────────────────
  // URL: https://www.pornhub.com/video/webmasterss
  Future<List<FeedItem>> _fetchPornHub() async {
    final endpoints = [
      'https://www.pornhub.com/video/webmasterss',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
          if (link.isEmpty) continue;
          items.add(FeedItem(
            id:     'ph_${link.hashCode}',
            title:  title.isEmpty ? 'Vídeo' : title,
            thumb:  thumb, url: link, source: 'PornHub',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── XVideos RSS (confirmado) ──────────────────────────────────────────────
  // URLs: https://www.xvideos.com/feeds/rss-new/0
  //       https://www.xvideos.com/feeds/rss-most-viewed-alltime/0
  Future<List<FeedItem>> _fetchXVideos() async {
    final endpoints = [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
      'https://www.xvideos.com/feeds/rss-new/gay/0',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = item.findElements('enclosure').firstOrNull?.getAttribute('url') ?? '';
          if (link.isEmpty) continue;
          items.add(FeedItem(
            id:     'xv_${link.hashCode}',
            title:  title.isEmpty ? 'Vídeo' : title,
            thumb:  thumb, url: link, source: 'XVideos',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── PornDig RSS (confirmado: https://www.porndig.com/rss) ─────────────────
  Future<List<FeedItem>> _fetchPornDig() async {
    final endpoints = [
      'https://www.porndig.com/rss',
      'https://www.porndig.com/rss?category=latest',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
          if (link.isEmpty) continue;
          items.add(FeedItem(
            id:     'pd_${link.hashCode}',
            title:  title.isEmpty ? 'Vídeo' : title,
            thumb:  thumb, url: link, source: 'PornDig',
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // ── Blogs da indústria adulta (confirmados no feedspot.com) ───────────────
  // Todos os feeds confirmados em: https://rss.feedspot.com/adult_industry_rss_feeds/
  Future<List<FeedItem>> _fetchBlogs() async {
    final sources = <String, String>{
      'https://ainews.xxx/feed/':                  'AINews.xxx',
      'https://rogreviews.com/feed':               'RogReviews',
      'https://theporndude.com/blog/feed':         'ThePornDude',
      'https://therealpornwikileaks.com/feed':     'TRPWL',
      'https://lukeisback.com/feed':               'LukeIsBack',
      'https://adultfyi.com/feed':                 'AdultFYI',
      'https://mikesouth.com/feed':                'MikeSouth',
      'https://ynot.com/feed':                     'YNotMasters',
      'https://xbiz.com/rss/all.xml':              'XBIZ',
      'https://queermenow.net/blog/feed':          'QueerMeNow',
    };
    final items = <FeedItem>[];
    for (final entry in sources.entries) {
      try {
        final res = await http.get(Uri.parse(entry.key),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
          if (link.isEmpty) continue;
          items.add(FeedItem(
            id:     '${entry.value}_${link.hashCode}',
            title:  title.isEmpty ? 'Artigo' : title,
            thumb:  thumb, url: link,
            source: entry.value, type: 'article',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _firstOf(List<String?> values) {
    for (final v in values) { if (v != null && v.isNotEmpty) return v; }
    return '';
  }

  String _xml(XmlElement el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); }
    catch (_) { return ''; }
  }
}
