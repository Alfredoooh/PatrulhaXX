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

  static const _ua =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

  Future<List<FeedItem>> load({bool force = false}) async {
    if (_loaded && !force) return _items;

    final results = await Future.wait([
      _fetchRedTube(),
      _fetchEporner(),
      _fetchPornHub(),
      _fetchXvideos(),
    ]);

    final all = results.expand((e) => e).toList()
      ..removeWhere((f) => f.thumb.isEmpty || f.url.isEmpty)
      ..shuffle();

    _items = all;
    _loaded = all.isNotEmpty;
    return _items;
  }

  // ── RedTube JSON ──────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchRedTube() async {
    try {
      final endpoints = [
        'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&search=&thumbsize=medium&count=40&ordering=newest',
        'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&search=&thumbsize=medium&count=40&ordering=mostviewed',
      ];
      final items = <FeedItem>[];
      for (final url in endpoints) {
        try {
          final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua},
          ).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) continue;
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          final videos = json['videos'] as List? ?? [];
          for (final v in videos) {
            final video = (v as Map)['video'] as Map<String, dynamic>? ?? {};
            final thumb = video['thumb'] as String? ?? '';
            final vUrl  = video['url']   as String? ?? '';
            if (thumb.isEmpty || vUrl.isEmpty) continue;
            items.add(FeedItem(
              id:       'rt_${video['video_id'] ?? items.length}',
              title:    video['title']    as String? ?? 'Vídeo',
              thumb:    thumb,
              url:      vUrl,
              duration: video['duration'] as String? ?? '',
              views:    video['views']    as String? ?? '',
              source:   'RedTube',
            ));
          }
        } catch (_) {}
      }
      return items;
    } catch (_) { return []; }
  }

  // ── EPorner XML ───────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchEporner() async {
    try {
      final endpoints = [
        'https://www.eporner.com/api/v2/video/search/?per_page=40&page=1&order=latest&format=xml&thumbsize=medium',
        'https://www.eporner.com/api/v2/video/search/?per_page=40&page=1&order=top-rated&format=xml&thumbsize=medium',
      ];
      final items = <FeedItem>[];
      for (final url in endpoints) {
        try {
          final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua},
          ).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) continue;

          // Tenta parse JSON (API v2 pode retornar JSON)
          try {
            final json = jsonDecode(res.body) as Map<String, dynamic>;
            final videos = json['videos'] as List? ?? [];
            for (final v in videos) {
              final vm = v as Map<String, dynamic>;
              final thumb = _firstNonEmpty([
                vm['thumbs']?[0]?['src'] as String?,
                vm['thumb']  as String?,
              ]);
              final vUrl = vm['url'] as String? ?? '';
              if (thumb.isEmpty || vUrl.isEmpty) continue;
              items.add(FeedItem(
                id:       'ep_${vm['id'] ?? items.length}',
                title:    vm['title']    as String? ?? 'Vídeo',
                thumb:    thumb,
                url:      vUrl.startsWith('http') ? vUrl : 'https://www.eporner.com$vUrl',
                duration: vm['length_min'] as String? ?? '',
                views:    vm['views']      as String? ?? '',
                source:   'EPorner',
              ));
            }
            continue;
          } catch (_) {}

          // Fallback: XML antigo
          try {
            final doc = XmlDocument.parse(res.body);
            for (final v in doc.findAllElements('video')) {
              final thumb = _xmlText(v, 'thumb');
              final vUrl  = _xmlText(v, 'url');
              if (thumb.isEmpty || vUrl.isEmpty) continue;
              items.add(FeedItem(
                id:       'ep_${_xmlText(v, 'id')}',
                title:    _xmlText(v, 'title').isEmpty ? 'Vídeo' : _xmlText(v, 'title'),
                thumb:    thumb.startsWith('http') ? thumb : 'https:$thumb',
                url:      vUrl.startsWith('http')  ? vUrl  : 'https://www.eporner.com$vUrl',
                duration: _xmlText(v, 'video_duration'),
                views:    _xmlText(v, 'views'),
                source:   'EPorner',
              ));
            }
          } catch (_) {}
        } catch (_) {}
      }
      return items;
    } catch (_) { return []; }
  }

  // ── PornHub RSS ───────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchPornHub() async {
    try {
      const url = 'https://www.pornhub.com/video/webmasterss';
      final res = await http.get(Uri.parse(url),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return [];
      final doc = XmlDocument.parse(res.body);
      final items = <FeedItem>[];
      for (final item in doc.findAllElements('item')) {
        final link  = _xmlText(item, 'link');
        final title = _xmlText(item, 'title');
        // thumbnail vem em media:thumbnail ou enclosure
        final mediaThumb = item
            .findElements('media:thumbnail')
            .firstOrNull
            ?.getAttribute('url') ?? '';
        final encThumb = item
            .findElements('enclosure')
            .firstOrNull
            ?.getAttribute('url') ?? '';
        final thumb = mediaThumb.isNotEmpty ? mediaThumb : encThumb;
        if (link.isEmpty) continue;
        items.add(FeedItem(
          id:     'ph_${link.hashCode}',
          title:  title.isEmpty ? 'Vídeo' : title,
          thumb:  thumb,
          url:    link,
          source: 'PornHub',
        ));
      }
      return items;
    } catch (_) { return []; }
  }

  // ── xVideos RSS ───────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchXvideos() async {
    try {
      final endpoints = [
        'https://www.xvideos.com/feeds/rss-new/0',
        'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
      ];
      final items = <FeedItem>[];
      for (final url in endpoints) {
        try {
          final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua},
          ).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) continue;
          final doc = XmlDocument.parse(res.body);
          for (final item in doc.findAllElements('item')) {
            final link  = _xmlText(item, 'link');
            final title = _xmlText(item, 'title');
            final enc   = item.findElements('enclosure').firstOrNull;
            final thumb = enc?.getAttribute('url') ?? '';
            if (link.isEmpty) continue;
            items.add(FeedItem(
              id:     'xv_${link.hashCode}',
              title:  title.isEmpty ? 'Vídeo' : title,
              thumb:  thumb,
              url:    link,
              source: 'XVideos',
            ));
          }
        } catch (_) {}
      }
      return items;
    } catch (_) { return []; }
  }

  // ── helpers ───────────────────────────────────────────────────────────────
  String _firstNonEmpty(List<String?> values) {
    for (final v in values) { if (v != null && v.isNotEmpty) return v; }
    return '';
  }

  String _xmlText(XmlElement el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); }
    catch (_) { return ''; }
  }
}
