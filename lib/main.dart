import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:xml/xml.dart';

const _extractServers = [
  'https://nuxxconvert1.onrender.com',
  'https://nuxxconvert2.onrender.com',
  'https://nuxxconvert3.onrender.com',
  'https://nuxxconvert4.onrender.com',
  'https://nuxxconvert5.onrender.com',
];

Future<String> extractVideoUrl(String pageUrl) async {
  final completer = Completer<String>();
  int errors = 0;
  for (final server in _extractServers) {
    () async {
      try {
        final uri = Uri.parse('$server/extract?url=${Uri.encodeComponent(pageUrl)}');
        final resp = await http.get(uri).timeout(const Duration(seconds: 20));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body) as Map<String, dynamic>;
          final link = data['link'] as String? ?? '';
          if (link.isNotEmpty && !completer.isCompleted) {
            completer.complete(link);
          } else {
            errors++;
            if (errors == _extractServers.length && !completer.isCompleted)
              completer.completeError('Nenhum servidor conseguiu extrair o vídeo.');
          }
        } else {
          errors++;
          if (errors == _extractServers.length && !completer.isCompleted)
            completer.completeError('Todos os servidores falharam.');
        }
      } catch (_) {
        errors++;
        if (errors == _extractServers.length && !completer.isCompleted)
          completer.completeError('Todos os servidores falharam.');
      }
    }();
  }
  return completer.future;
}

enum VideoSource {
  eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang,
  bravotube, drtuber, txxx, gotporn, porndig,
}

class FeedVideo {
  final String title;
  final String thumb;
  final String embedUrl;
  final String pageUrl;
  final String duration;
  final String views;
  final VideoSource source;
  final DateTime? publishedAt;

  const FeedVideo({
    required this.title,
    required this.thumb,
    required this.embedUrl,
    required this.pageUrl,
    required this.duration,
    required this.views,
    required this.source,
    this.publishedAt,
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
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.eporner.com/embed/$id/',
      pageUrl:  'https://www.eporner.com/video/$id/',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.eporner,
      publishedAt: _parseDate(j['added'] ?? j['published'] ?? j['date']),
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
    // Sempre www — ignora subdomínio de localização (pt, de, fr, etc.)
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.pornhub.com/embed/$viewkey',
      pageUrl:  'https://www.pornhub.com/view_video.php?viewkey=$viewkey',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.pornhub,
      publishedAt: _parseDate(j['publish_date'] ?? j['date_approved'] ?? j['added']),
    );
  }

  static FeedVideo? fromRedtube(Map<String, dynamic> j) {
    final vid = j['video_id'] as String? ?? '';
    if (vid.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    // Sempre www.redtube.com — ignora .com.br e outros regionais
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://embed.redtube.com/?id=$vid',
      pageUrl:  'https://www.redtube.com/$vid',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.redtube,
      publishedAt: _parseDate(j['publish_date'] ?? j['date']),
    );
  }

  static FeedVideo? fromYouporn(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.youporn.com/embed/$id/',
      pageUrl:  'https://www.youporn.com/watch/$id/',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.youporn,
      publishedAt: _parseDate(j['publish_date'] ?? j['date']),
    );
  }

  static FeedVideo? fromXvideos(Map<String, dynamic> j) {
    // XVideos usa formato /video.ID/slug — o ID vem em j['id'] ou j['video_id']
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ??
        j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://www.xvideos.com/embedframe/$id',
      pageUrl:  'https://www.xvideos.com/video.$id/',
      duration: j['duration'] as String? ?? '',
      views:    _fmtViews(j['views'] ?? j['nb_views']),
      source:   VideoSource.xvideos,
      publishedAt: _parseDate(j['added'] ?? j['date']),
    );
  }

  static FeedVideo? fromXhamster(Map<String, dynamic> j) {
    // xHamster: /videos/titulo-ID onde ID é alfanumérico (ex: xhEI9G3)
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumbUrl'] as String? ?? j['thumb'] as String? ??
        j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    final slug = (j['slug'] ?? j['url'] ?? '').toString();
    final pageUrl = slug.startsWith('http')
        ? _normalizeXhamsterUrl(slug)
        : slug.isNotEmpty
            ? 'https://xhamster.com/videos/$slug'
            : 'https://xhamster.com/videos/$id';
    return FeedVideo(
      title:    cleanTitle(j['title'] as String? ?? ''),
      thumb:    thumb,
      embedUrl: 'https://xhamster.com/xembed.php?video=$id',
      pageUrl:  pageUrl,
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.xhamster,
      publishedAt: _parseDate(j['created'] ?? j['added'] ?? j['date']),
    );
  }

  // Remove parâmetros UTM e normaliza domínio xHamster
  static String _normalizeXhamsterUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return Uri(scheme: 'https', host: 'xhamster.com', path: uri.path).toString();
    } catch (_) {
      return url;
    }
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
      pageUrl:  'https://spankbang.com/$id/video/',
      duration: j['duration']?.toString() ?? '',
      views:    _fmtViews(j['views']),
      source:   VideoSource.spankbang,
      publishedAt: _parseDate(j['date'] ?? j['added']),
    );
  }

  static FeedVideo fromRss({
    required String title,
    required String thumb,
    required String embedUrl,
    required String pageUrl,
    required VideoSource source,
    DateTime? publishedAt,
  }) =>
      FeedVideo(
        title:    cleanTitle(title),
        thumb:    thumb,
        embedUrl: embedUrl,
        pageUrl:  pageUrl,
        duration: '',
        views:    '',
        source:   source,
        publishedAt: publishedAt,
      );

  static DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;
    final epoch = int.tryParse(s);
    if (epoch != null) return DateTime.fromMillisecondsSinceEpoch(epoch * 1000);
    try { return DateTime.parse(s); } catch (_) {}
    return null;
  }

  static String cleanTitle(String raw) {
    try {
      final bytes = latin1.encode(raw);
      final decoded = utf8.decode(bytes, allowMalformed: true);
      if (decoded.runes.where((r) => r > 127).length <
          raw.runes.where((r) => r > 127).length) return decoded;
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
}

class FeedFetcher {
  static const _ua =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

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
      return (data['videos'] as List? ?? [])
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
      return (data['videos'] as List? ?? [])
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
      return (data['videos'] as List? ?? [])
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
            '?is_top=1&page=${page.clamp(1, 15)}&per_page=20'),
        headers: {
          'User-Agent': _ua,
          'Accept': 'application/json',
          'Referer': 'https://www.youporn.com/',
        },
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

  // XVideos — RSS devolve links no formato /video.ID/slug
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
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.xvideos.com$rawLink';
          // Formato real: /video.ID/slug ou /videoID/slug
          final match = RegExp(r'/video[./]([a-zA-Z0-9]+)').firstMatch(fullLink);
          if (match == null) continue;
          final id = match.group(1)!;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://www.xvideos.com/embedframe/$id',
            pageUrl:  fullLink,
            source:   VideoSource.xvideos,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // xHamster — RSS real, URL formato /videos/titulo-IDalfanumerico
  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    final urls = [
      'https://xhamster.com/rss',
      'https://xhamster.com/rss?sort=newest',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://xhamster.com$rawLink';
          // Remove UTM e normaliza domínio
          final cleanLink = FeedVideo._normalizeXhamsterUrl(fullLink);
          // Formato: /videos/titulo-xhXXXXXX — ID alfanumérico no fim
          final match = RegExp(r'/videos/[\w-]+-([a-zA-Z0-9]+)$').firstMatch(cleanLink);
          if (match == null) continue;
          final id = match.group(1)!;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://xhamster.com/xembed.php?video=$id',
            pageUrl:  cleanLink,
            source:   VideoSource.xhamster,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
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
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://spankbang.com$rawLink';
          // Formato: /ID/video/titulo
          final match = RegExp(r'spankbang\.com/([A-Za-z0-9]+)/').firstMatch(fullLink);
          if (match == null) continue;
          final id = match.group(1)!;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://spankbang.com/$id/embed/',
            pageUrl:  fullLink,
            source:   VideoSource.spankbang,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // BravoTube — formato /videos/titulo/ (sem ID numérico no slug)
  static Future<List<FeedVideo>> fetchBravotube(int page) async {
    final urls = [
      'https://www.bravotube.net/rss/new/',
      'https://www.bravotube.net/rss/popular/',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.bravotube.net$rawLink';
          // Tenta extrair ID numérico se existir, senão usa o link completo
          final matchId = RegExp(r'-(\d+)\.html').firstMatch(fullLink);
          final embedUrl = matchId != null
              ? 'https://www.bravotube.net/embed/${matchId.group(1)}/'
              : '';
          if (embedUrl.isEmpty && !fullLink.contains('/videos/')) continue;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: embedUrl,
            pageUrl:  fullLink,
            source:   VideoSource.bravotube,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // DrTuber — pageUrl real: /video/ID/titulo (não /video/download/save/ID)
  static Future<List<FeedVideo>> fetchDrtuber(int page) async {
    final urls = [
      'https://www.drtuber.com/rss/latest',
      'https://www.drtuber.com/rss/popular',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.drtuber.com$rawLink';
          // Normaliza: remove /download/save/ se presente
          final cleanLink = fullLink
              .replaceFirst(RegExp(r'/video/download/save/'), '/video/')
              .replaceFirst(RegExp(r'^https?://m\.drtuber'), 'https://www.drtuber');
          final match = RegExp(r'/video/(\d+)').firstMatch(cleanLink);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://www.drtuber.com/embed/${match.group(1)}',
            pageUrl:  cleanLink,
            source:   VideoSource.drtuber,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchTxxx(int page) async {
    final urls = [
      'https://www.txxx.com/rss/new/',
      'https://www.txxx.com/rss/popular/',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.txxx.com$rawLink';
          final match = RegExp(r'-(\d+)/?$').firstMatch(Uri.parse(fullLink).path);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://www.txxx.com/embed/${match.group(1)}/',
            pageUrl:  fullLink,
            source:   VideoSource.txxx,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // GotPorn — ignora links de redirect /out/, usa apenas links directos /video-ID
  static Future<List<FeedVideo>> fetchGotporn(int page) async {
    final urls = [
      'https://www.gotporn.com/rss/latest',
      'https://www.gotporn.com/rss/popular',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          // Ignora links de redirect /out/
          if (rawLink.contains('/out/') || rawLink.contains('/out?')) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.gotporn.com$rawLink';
          final match = RegExp(r'/video-(\d+)').firstMatch(fullLink);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://www.gotporn.com/video/embed/${match.group(1)}',
            pageUrl:  fullLink,
            source:   VideoSource.gotporn,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  static Future<List<FeedVideo>> fetchPorndig(int page) async {
    final urls = [
      'https://www.porndig.com/rss',
      'https://www.porndig.com/rss?category=latest',
    ];
    final items = <FeedVideo>[];
    for (final url in urls) {
      try {
        final r = await http.get(Uri.parse(url), headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (r.statusCode != 200) continue;
        final doc = XmlDocument.parse(r.body);
        for (final item in doc.findAllElements('item')) {
          final rawLink = _xml(item, 'link');
          final title   = _xml(item, 'title');
          final thumb   = _rssThumb(item);
          final pubDate = _xml(item, 'pubDate');
          if (rawLink.isEmpty) continue;
          final fullLink = rawLink.startsWith('http')
              ? rawLink
              : 'https://www.porndig.com$rawLink';
          final match = RegExp(r'-(\d+)\.html').firstMatch(fullLink);
          if (match == null) continue;
          items.add(FeedVideo.fromRss(
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            embedUrl: 'https://www.porndig.com/embed/${match.group(1)}',
            pageUrl:  fullLink,
            source:   VideoSource.porndig,
            publishedAt: pubDate.isNotEmpty ? _tryParseRssDate(pubDate) : null,
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
          final url  = child.getAttribute('url') as String? ?? '';
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
        final m = RegExp('<img[^>]+src=["\'](.*?)["\']').firstMatch(desc);
        if (m != null) return m.group(1) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static DateTime? _tryParseRssDate(String raw) {
    try { return DateTime.parse(raw); } catch (_) {}
    try {
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final rx = RegExp(r'\w+,\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})');
      final m = rx.firstMatch(raw);
      if (m != null) {
        return DateTime.utc(
          int.parse(m.group(3)!), months[m.group(2)] ?? 1, int.parse(m.group(1)!),
          int.parse(m.group(4)!), int.parse(m.group(5)!), int.parse(m.group(6)!),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<List<FeedVideo>> fetchAll(int page) async {
    final rng = Random(DateTime.now().millisecondsSinceEpoch ^ page.hashCode);
    final results = await Future.wait([
      fetchEporner(rng.nextInt(60) + 1),
      fetchPornhub(rng.nextInt(40) + 1),
      fetchRedtube(rng.nextInt(30) + 1),
      fetchYouporn(rng.nextInt(20) + 1),
      fetchXvideos(rng.nextInt(50) + 1),
      fetchXhamster(rng.nextInt(30) + 1),
      fetchSpankbang(rng.nextInt(20) + 1),
      fetchBravotube(page),
      fetchDrtuber(page),
      fetchTxxx(page),
      fetchGotporn(page),
      fetchPorndig(page),
    ]);
    final merged = <FeedVideo>[];
    final lists = results.where((l) => l.isNotEmpty).toList();
    if (lists.isEmpty) return [];
    final maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < maxLen; i++) {
      for (final list in lists) {
        if (i < list.length) merged.add(list[i]);
      }
    }
    merged.shuffle(rng);
    return merged;
  }
}

void main() => runApp(const NuxxApp());

class NuxxApp extends StatelessWidget {
  const NuxxApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuxx',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111111),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9000),
          surface: Color(0xFF1A1A1A),
        ),
      ),
      home: const FeedPage(),
    );
  }
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final List<FeedVideo> _videos = [];
  int _page = 1;
  bool _loading = false;
  bool _hasMore = true;
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMore();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore();
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final newVideos = await FeedFetcher.fetchAll(_page);
      setState(() {
        _videos.addAll(newVideos);
        _page++;
        if (newVideos.isEmpty) _hasMore = false;
      });
    } catch (_) {
      setState(() => _hasMore = false);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('NUXX', style: TextStyle(
          color: Color(0xFFFF9000), fontWeight: FontWeight.w900,
          fontSize: 22, letterSpacing: 4,
        )),
        centerTitle: true,
        elevation: 0,
      ),
      body: _videos.isEmpty && _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF9000)))
          : ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(12),
              itemCount: _videos.length + (_loading ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _videos.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: Color(0xFFFF9000))),
                  );
                }
                return _VideoCard(video: _videos[i]);
              },
            ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final FeedVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => VideoPlayerPage(video: video))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: video.thumb.isNotEmpty
                    ? Image.network(video.thumb, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF222222),
                          child: const Icon(Icons.broken_image, color: Colors.white24, size: 40),
                        ))
                    : Container(color: const Color(0xFF222222),
                        child: const Icon(Icons.video_library, color: Colors.white24, size: 40)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9000),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(video.sourceInitial, style: const TextStyle(
                      color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900,
                    )),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.title.isNotEmpty ? video.title : 'Sem título',
                          maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 13,
                              fontWeight: FontWeight.w600),
                        ),
                        if (video.views.isNotEmpty || video.duration.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            if (video.views.isNotEmpty)
                              Text('${video.views} views',
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                            if (video.views.isNotEmpty && video.duration.isNotEmpty)
                              const Text('  ·  ',
                                  style: TextStyle(color: Colors.white38, fontSize: 11)),
                            if (video.duration.isNotEmpty)
                              Text(video.duration,
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final FeedVideo video;
  const VideoPlayerPage({super.key, required this.video});
  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  VideoPlayerController? _controller;
  bool _extracting = true;
  String? _error;
  bool _showControls = true;

  @override
  void initState() { super.initState(); _extract(); }

  Future<void> _extract() async {
    setState(() { _extracting = true; _error = null; });
    try {
      final directUrl = await extractVideoUrl(widget.video.pageUrl);
      final ctrl = VideoPlayerController.networkUrl(Uri.parse(directUrl));
      await ctrl.initialize();
      ctrl.play();
      if (mounted) setState(() { _controller = ctrl; _extracting = false; });
    } catch (e) {
      if (mounted) setState(() { _extracting = false; _error = e.toString(); });
    }
  }

  @override
  void dispose() { _controller?.dispose(); super.dispose(); }

  void _toggleControls() => setState(() => _showControls = !_showControls);

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: _toggleControls,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    if (_extracting)
                      const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        CircularProgressIndicator(color: Color(0xFFFF9000)),
                        SizedBox(height: 12),
                        Text('A extrair vídeo...', style: TextStyle(color: Colors.white54, fontSize: 13)),
                      ])
                    else if (_error != null)
                      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.white54, fontSize: 12),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: _extract,
                          child: const Text('Tentar novamente',
                              style: TextStyle(color: Color(0xFFFF9000))),
                        ),
                      ])
                    else if (_controller != null)
                      VideoPlayer(_controller!),
                    if (_controller != null && _showControls)
                      _ControlsOverlay(
                        controller: _controller!,
                        fmt: _fmt,
                        onBack: () => Navigator.pop(context),
                      ),
                    if (!_showControls)
                      Positioned(
                        top: 8, left: 8,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.video.title.isNotEmpty ? widget.video.title : 'Sem título',
                      style: const TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9000),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(widget.video.sourceLabel, style: const TextStyle(
                          color: Colors.black, fontSize: 11, fontWeight: FontWeight.w900,
                        )),
                      ),
                      if (widget.video.views.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text('${widget.video.views} views',
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                      if (widget.video.duration.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(widget.video.duration,
                            style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;
  final String Function(Duration) fmt;
  final VoidCallback onBack;
  const _ControlsOverlay({required this.controller, required this.fmt, required this.onBack});
  @override
  State<_ControlsOverlay> createState() => _ControlsOverlayState();
}

class _ControlsOverlayState extends State<_ControlsOverlay> {
  @override
  void initState() { super.initState(); widget.controller.addListener(_update); }
  @override
  void dispose() { widget.controller.removeListener(_update); super.dispose(); }
  void _update() { if (mounted) setState(() {}); }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final pos  = ctrl.value.position;
    final dur  = ctrl.value.duration;
    final playing = ctrl.value.isPlaying;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black54],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: widget.onBack,
            ),
          ]),
          IconButton(
            iconSize: 56,
            icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: Colors.white),
            onPressed: () => playing ? ctrl.pause() : ctrl.play(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(children: [
              VideoProgressIndicator(ctrl, allowScrubbing: true,
                  colors: const VideoProgressColors(
                    playedColor: Color(0xFFFF9000),
                    bufferedColor: Colors.white24,
                    backgroundColor: Colors.white12,
                  )),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(widget.fmt(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text(widget.fmt(dur), style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}