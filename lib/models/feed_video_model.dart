import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VideoSource
// ─────────────────────────────────────────────────────────────────────────────
enum VideoSource {
  eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang,
  bravotube, drtuber, txxx, gotporn, porndig,
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedVideo
// ─────────────────────────────────────────────────────────────────────────────
class FeedVideo {
  final String title;
  final String thumb;
  final String embedUrl;
  final String duration;
  final String views;
  final VideoSource source;

  const FeedVideo({
    required this.title, required this.thumb, required this.embedUrl,
    required this.duration, required this.views, required this.source,
  });

  String get sourceLabel {
    switch (source) {
      case VideoSource.eporner:   return 'Eporner';
      case VideoSource.pornhub:   return 'Pornhub';
      case VideoSource.redtube:   return 'RedTube';
      case VideoSource.youporn:   return 'YouPorn';
      case VideoSource.xvideos:   return 'XVideos';
      case VideoSource.xhamster:  return 'xHamster';
      case VideoSource.spankbang: return 'SpankBang';
      case VideoSource.bravotube: return 'BravoTube';
      case VideoSource.drtuber:   return 'DrTuber';
      case VideoSource.txxx:      return 'TXXX';
      case VideoSource.gotporn:   return 'GotPorn';
      case VideoSource.porndig:   return 'PornDig';
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:   return 'E';
      case VideoSource.pornhub:   return 'P';
      case VideoSource.redtube:   return 'R';
      case VideoSource.youporn:   return 'Y';
      case VideoSource.xvideos:   return 'XV';
      case VideoSource.xhamster:  return 'XH';
      case VideoSource.spankbang: return 'SB';
      case VideoSource.bravotube: return 'BT';
      case VideoSource.drtuber:   return 'DT';
      case VideoSource.txxx:      return 'TX';
      case VideoSource.gotporn:   return 'GP';
      case VideoSource.porndig:   return 'PD';
    }
  }

  Color get sourceColor => const Color(0xFF222222);

  static FeedVideo? fromEporner(Map<String, dynamic> j) {
    final id = j['id'] as String? ?? '';
    if (id.isEmpty) return null;
    String thumb = '';
    final thumbs = j['thumbs'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      final sorted = thumbs.map((t) => t as Map).toList()
        ..sort((a, b) => ((b['width'] ?? 0) as int).compareTo((a['width'] ?? 0) as int));
      thumb = sorted.first['src'] as String? ?? '';
    }
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.eporner.com/embed/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.eporner,
    );
  }

  static FeedVideo? fromPornhub(Map<String, dynamic> j) {
    final viewkey = j['video_id'] as String? ?? j['viewkey'] as String? ?? '';
    if (viewkey.isEmpty) return null;
    String thumb = '';
    final thumbs = j['thumbs'] as List?;
    if (thumbs != null && thumbs.isNotEmpty) {
      thumb = (thumbs.first['src'] ?? thumbs.first['url'] ?? '') as String;
    }
    if (thumb.isEmpty) thumb = j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.pornhub.com/embed/$viewkey',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.pornhub,
    );
  }

  static FeedVideo? fromRedtube(Map<String, dynamic> j) {
    final vid = j['video_id'] as String? ?? '';
    if (vid.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://embed.redtube.com/?id=$vid',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.redtube,
    );
  }

  static FeedVideo? fromYouporn(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: FeedVideo.cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.youporn.com/embed/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.youporn,
    );
  }

  static FeedVideo? fromXvideos(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ??
        j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.xvideos.com/embedframe/$id',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views'] ?? j['nb_views']),
      source:   VideoSource.xvideos,
    );
  }

  static FeedVideo? fromXhamster(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumbUrl'] as String? ?? j['thumb'] as String? ??
        j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://xhamster.com/xembed.php?video=$id',
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.xhamster,
    );
  }

  static FeedVideo? fromSpankbang(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://spankbang.com/$id/embed/',
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.spankbang,
    );
  }

  static FeedVideo fromRss({
    required String title,
    required String thumb,
    required String embedUrl,
    required VideoSource source,
  }) => FeedVideo(
    title: cleanTitle(title),
    thumb: thumb,
    embedUrl: embedUrl,
    duration: '',
    views: '',
    source: source,
  );

  static String cleanTitle(String raw) {
    try {
      final bytes = latin1.encode(raw);
      final decoded = utf8.decode(bytes, allowMalformed: true);
      if (decoded.runes.where((r) => r > 127).length <
          raw.runes.where((r) => r > 127).length) {
        return decoded;
      }
    } catch (_) {}
    return raw;
  }

  static String _fmtViews(dynamic raw) {
    if (raw == null) return '';
    final n = int.tryParse(raw.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n > 0 ? n.toString() : '';
  }

  static String fmtViewsPublic(dynamic raw) => _fmtViews(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedFetcher
// ─────────────────────────────────────────────────────────────────────────────
class FeedFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
  ];

  static Future<List<FeedVideo>> fetchEporner(int page) async {
    final term = _terms[page % _terms.length];
    try {
      final r = await http.get(
        Uri.parse('https://www.eporner.com/api/v2/video/search/'
            '?query=$term&per_page=20&page=${page.clamp(1, 60)}&thumbsize=big&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) => FeedVideo.fromEporner(v as Map<String, dynamic>))
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchPornhub(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/search?search=&ordering=newest'
            '&page=${page.clamp(1, 40)}&thumbsize=medium&format=json'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) {
            final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
            return FeedVideo.fromPornhub(inner);
          })
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchRedtube(int page) async {
    final term = _terms[page % _terms.length];
    final order = ['mostviewed', 'rating', 'newestdate'][page % 3];
    try {
      final r = await http.get(
        Uri.parse('https://api.redtube.com/?data=redtube.Videos.searchVideos'
            '&output=json&thumbsize=medium&count=20'
            '&search=$term&ordering=$order&page=$page'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final videos = (data['videos'] as List? ?? []);
      return videos
          .map((v) {
            final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
            return FeedVideo.fromRedtube(inner);
          })
          .whereType<FeedVideo>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedVideo>> fetchYouporn(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.youporn.com/api/video/search/'
            '?is_top=1&page=${page.clamp(1,15)}&per_page=20'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json',
            'Referer': 'https://www.youporn.com/'},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final videos = (data['videos'] ?? data['data'] ?? data) as List? ?? [];
        final result = videos
            .map((v) => FeedVideo.fromYouporn(v as Map<String, dynamic>))
            .whereType<FeedVideo>()
            .toList();
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}
    return [];
  }

  static Future<List<FeedVideo>> fetchXvideos(int page) async {
    final urls = [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 14));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://www.xvideos.com/embedframe/${match.group(1)}',
            source: VideoSource.xvideos,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    final urls = [
      'https://www.xnxx.com/rss/latest_videos',
      'https://www.xnxx.com/rss/best_videos',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video-(\w+)/').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://www.xnxx.com/embedframe/${match.group(1)}',
            source: VideoSource.xhamster,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchSpankbang(int page) async {
    final urls = ['https://spankbang.com/rss/', 'https://spankbang.com/rss/trending/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(Uri.parse(link).path);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title.isEmpty ? 'Vídeo' : title,
            thumb: thumb,
            embedUrl: 'https://spankbang.com/${match.group(1)}/embed/',
            source: VideoSource.spankbang,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchBravotube(int page) async {
    final urls = ['https://www.bravotube.net/rss/new/', 'https://www.bravotube.net/rss/popular/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.bravotube.net/embed/${match.group(1)}/',
            source: VideoSource.bravotube,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchDrtuber(int page) async {
    final urls = ['https://www.drtuber.com/rss/latest', 'https://www.drtuber.com/rss/popular'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video/(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.drtuber.com/embed/${match.group(1)}',
            source: VideoSource.drtuber,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchTxxx(int page) async {
    final urls = ['https://www.txxx.com/rss/new/', 'https://www.txxx.com/rss/popular/'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)/?$').firstMatch(Uri.parse(link).path);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.txxx.com/embed/${match.group(1)}/',
            source: VideoSource.txxx,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchGotporn(int page) async {
    final urls = ['https://www.gotporn.com/rss/latest', 'https://www.gotporn.com/rss/popular'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video-(\d+)').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.gotporn.com/video/embed/${match.group(1)}',
            source: VideoSource.gotporn,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchPorndig(int page) async {
    final urls = ['https://www.porndig.com/rss', 'https://www.porndig.com/rss?category=latest'];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final link  = FeedFetcher._xml(item, 'link');
          final title = FeedFetcher._xml(item, 'title');
          final thumb = FeedFetcher._rssThumb(item);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title: title, thumb: thumb,
            embedUrl: 'https://www.porndig.com/embed/${match.group(1)}',
            source: VideoSource.porndig,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static String _xml(dynamic el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); } catch (_) { return ''; }
  }

  static String _mediaAttr(dynamic item, String localName, String attr) {
    try {
      for (final child in (item as dynamic).childElements) {
        final qn = child.qualifiedName as String? ?? '';
        final ln = child.localName as String? ?? '';
        if (qn == 'media:$localName' || ln == localName) {
          final val = child.getAttribute(attr) as String? ?? '';
          if (val.isNotEmpty) return val;
        }
      }
    } catch (_) {}
    return '';
  }

  static String _rssThumb(dynamic item) {
    final mc = _mediaAttr(item, 'content', 'url');
    if (mc.isNotEmpty) return mc;
    final mt = _mediaAttr(item, 'thumbnail', 'url');
    if (mt.isNotEmpty) return mt;
    try {
      for (final child in (item as dynamic).childElements) {
        final ln = (child.localName as String? ?? '').toLowerCase();
        if (ln == 'enclosure') {
          final url = child.getAttribute('url') as String? ?? '';
          final type = child.getAttribute('type') as String? ?? '';
          if (url.isNotEmpty && (type.startsWith('image') ||
              url.contains('.jpg') || url.contains('.png') || url.contains('.webp'))) {
            return url;
          }
        }
      }
    } catch (_) {}
    try {
      final desc = _xml(item, 'description');
      if (desc.isNotEmpty) {
        final rx = RegExp('<img[^>]+src=["\'](.*?)["\']');
        final m = rx.firstMatch(desc);
        if (m != null) return m.group(1) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static Future<List<FeedVideo>> fetchAll(int page) async {
    final rng = Random(DateTime.now().millisecondsSinceEpoch ^ page.hashCode);
    final epPage = rng.nextInt(60) + 1;
    final phPage = rng.nextInt(40) + 1;
    final rtPage = rng.nextInt(30) + 1;
    final ypPage = rng.nextInt(20) + 1;
    final xvPage = rng.nextInt(50) + 1;
    final xhPage = rng.nextInt(30) + 1;
    final sbPage = rng.nextInt(20) + 1;

    final results = await Future.wait([
      fetchEporner(epPage),
      fetchPornhub(phPage),
      fetchRedtube(rtPage),
      fetchYouporn(ypPage),
      fetchXvideos(xvPage),
      fetchXhamster(xhPage),
      fetchSpankbang(sbPage),
      fetchBravotube(page),
      fetchDrtuber(page),
      fetchTxxx(page),
      fetchGotporn(page),
      fetchPorndig(page),
    ]);

    final merged = <FeedVideo>[];
    final lists = results.where((l) => l.isNotEmpty).toList();
    if (lists.isEmpty) return [];

    int maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < maxLen; i++) {
      for (final list in lists) {
        if (i < list.length) merged.add(list[i]);
      }
    }
    merged.shuffle(rng);
    return merged;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// faviconForSource (helper público, usado por explore_page.dart)
// ─────────────────────────────────────────────────────────────────────────────
String faviconForSource(VideoSource src) {
  switch (src) {
    case VideoSource.eporner:   return 'https://www.eporner.com/favicon.ico';
    case VideoSource.pornhub:   return 'https://www.pornhub.com/favicon.ico';
    case VideoSource.redtube:   return 'https://www.redtube.com/favicon.ico';
    case VideoSource.youporn:   return 'https://www.youporn.com/favicon.ico';
    case VideoSource.xvideos:   return 'https://www.xvideos.com/favicon.ico';
    case VideoSource.xhamster:  return 'https://xhamster.com/favicon.ico';
    case VideoSource.spankbang: return 'https://spankbang.com/favicon.ico';
    case VideoSource.bravotube: return 'https://www.bravotube.net/favicon.ico';
    case VideoSource.drtuber:   return 'https://www.drtuber.com/favicon.ico';
    case VideoSource.txxx:      return 'https://www.txxx.com/favicon.ico';
    case VideoSource.gotporn:   return 'https://www.gotporn.com/favicon.ico';
    case VideoSource.porndig:   return 'https://www.porndig.com/favicon.ico';
  }
}
