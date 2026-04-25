import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:xml/xml.dart';

// ─────────────────────────────────────────────────────────────────────────────
// VideoSource
// ─────────────────────────────────────────────────────────────────────────────
enum VideoSource {
  eporner, pornhub, redtube, youporn, xvideos, xhamster, spankbang,
  bravotube, drtuber, txxx, gotporn, porndig, beeg, tube8, tnaflix,
  empflix, porntrex, hclips, tubedupe, nuvid, sunporno, pornone,
  slutload, iceporn, vjav, jizzbunker, cliphunter, sexvid, yeptube,
  xnxx, pornoxo, anysex, fuqer, fapster, proporn, h2porn,
  alphaporno, watchmygf, xcafe, tubecup, vidlox, naughtyamerica,
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedVideo
// ─────────────────────────────────────────────────────────────────────────────
class FeedVideo {
  final String title;
  final String thumb;
  final String videoUrl;
  final String duration;
  final String views;
  final VideoSource source;
  final DateTime? publishedAt;

  const FeedVideo({
    required this.title,
    required this.thumb,
    required this.videoUrl,
    required this.duration,
    required this.views,
    required this.source,
    this.publishedAt,
  });

  String get sourceLabel {
    switch (source) {
      case VideoSource.eporner:        return 'Eporner';
      case VideoSource.pornhub:        return 'Pornhub';
      case VideoSource.redtube:        return 'RedTube';
      case VideoSource.youporn:        return 'YouPorn';
      case VideoSource.xvideos:        return 'XVideos';
      case VideoSource.xhamster:       return 'xHamster';
      case VideoSource.spankbang:      return 'SpankBang';
      case VideoSource.bravotube:      return 'BravoTube';
      case VideoSource.drtuber:        return 'DrTuber';
      case VideoSource.txxx:           return 'TXXX';
      case VideoSource.gotporn:        return 'GotPorn';
      case VideoSource.porndig:        return 'PornDig';
      case VideoSource.beeg:           return 'Beeg';
      case VideoSource.tube8:          return 'Tube8';
      case VideoSource.tnaflix:        return 'TNAFlix';
      case VideoSource.empflix:        return 'EmpFlix';
      case VideoSource.porntrex:       return 'PornTrex';
      case VideoSource.hclips:         return 'HClips';
      case VideoSource.tubedupe:       return 'TubeDupe';
      case VideoSource.nuvid:          return 'Nuvid';
      case VideoSource.sunporno:       return 'SunPorno';
      case VideoSource.pornone:        return 'PornOne';
      case VideoSource.slutload:       return 'SlutLoad';
      case VideoSource.iceporn:        return 'IcePorn';
      case VideoSource.vjav:           return 'vJav';
      case VideoSource.jizzbunker:     return 'JizzBunker';
      case VideoSource.cliphunter:     return 'ClipHunter';
      case VideoSource.sexvid:         return 'SexVid';
      case VideoSource.yeptube:        return 'YepTube';
      case VideoSource.xnxx:           return 'XNXX';
      case VideoSource.pornoxo:        return 'PornoXO';
      case VideoSource.anysex:         return 'AnySex';
      case VideoSource.fuqer:          return 'Fuqer';
      case VideoSource.fapster:        return 'Fapster';
      case VideoSource.proporn:        return 'ProPorn';
      case VideoSource.h2porn:         return 'H2Porn';
      case VideoSource.alphaporno:     return 'AlphaPorno';
      case VideoSource.watchmygf:      return 'WatchMyGF';
      case VideoSource.xcafe:          return 'xCafe';
      case VideoSource.tubecup:        return 'TubeCup';
      case VideoSource.vidlox:         return 'Vidlox';
      case VideoSource.naughtyamerica: return 'NaughtyAmerica';
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:        return 'EP';
      case VideoSource.pornhub:        return 'PH';
      case VideoSource.redtube:        return 'RT';
      case VideoSource.youporn:        return 'YP';
      case VideoSource.xvideos:        return 'XV';
      case VideoSource.xhamster:       return 'XH';
      case VideoSource.spankbang:      return 'SB';
      case VideoSource.bravotube:      return 'BT';
      case VideoSource.drtuber:        return 'DT';
      case VideoSource.txxx:           return 'TX';
      case VideoSource.gotporn:        return 'GP';
      case VideoSource.porndig:        return 'PD';
      case VideoSource.beeg:           return 'BG';
      case VideoSource.tube8:          return 'T8';
      case VideoSource.tnaflix:        return 'TN';
      case VideoSource.empflix:        return 'EF';
      case VideoSource.porntrex:       return 'PTX';
      case VideoSource.hclips:         return 'HC';
      case VideoSource.tubedupe:       return 'TD';
      case VideoSource.nuvid:          return 'NV';
      case VideoSource.sunporno:       return 'SP';
      case VideoSource.pornone:        return 'P1';
      case VideoSource.slutload:       return 'SL';
      case VideoSource.iceporn:        return 'IC';
      case VideoSource.vjav:           return 'VJ';
      case VideoSource.jizzbunker:     return 'JB';
      case VideoSource.cliphunter:     return 'CH';
      case VideoSource.sexvid:         return 'SV';
      case VideoSource.yeptube:        return 'YT';
      case VideoSource.xnxx:           return 'XN';
      case VideoSource.pornoxo:        return 'PX';
      case VideoSource.anysex:         return 'AS';
      case VideoSource.fuqer:          return 'FQ';
      case VideoSource.fapster:        return 'FS';
      case VideoSource.proporn:        return 'PP';
      case VideoSource.h2porn:         return 'H2';
      case VideoSource.alphaporno:     return 'AP';
      case VideoSource.watchmygf:      return 'WG';
      case VideoSource.xcafe:          return 'XC';
      case VideoSource.tubecup:        return 'TC';
      case VideoSource.vidlox:         return 'VL';
      case VideoSource.naughtyamerica: return 'NA';
    }
  }

  Color get sourceColor => const Color(0xFF222222);

  // ── Parsers ────────────────────────────────────────────────────────────────

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
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://www.eporner.com/video/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.eporner,
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
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://www.pornhub.com/view_video.php?viewkey=$viewkey',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.pornhub,
      publishedAt: _parseDate(j['publish_date'] ?? j['date_approved'] ?? j['added']),
    );
  }

  static FeedVideo? fromRedtube(Map<String, dynamic> j) {
    final vid = j['video_id'] as String? ?? '';
    if (vid.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://www.redtube.com/$vid',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.redtube,
      publishedAt: _parseDate(j['publish_date'] ?? j['date']),
    );
  }

  static FeedVideo? fromYouporn(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://www.youporn.com/watch/$id/',
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.youporn,
      publishedAt: _parseDate(j['publish_date'] ?? j['date']),
    );
  }

  static FeedVideo? fromBeeg(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    String thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) thumb = 'https://static.beeg.com/autothumb/$id/bigthumb.jpg';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://beeg.com/$id',
      duration: j['duration']?.toString() ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.beeg,
      publishedAt: _parseDate(j['date'] ?? j['created']),
    );
  }

  static FeedVideo? fromTube8(Map<String, dynamic> j) {
    final id = (j['video_id'] ?? j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      videoUrl: 'https://www.tube8.com/video/$id',
      duration: '${j['duration'] ?? ''}',
      views: _fmtViews(j['views']),
      source: VideoSource.tube8,
      publishedAt: _parseDate(j['date'] ?? j['added']),
    );
  }

  static FeedVideo fromScraped({
    required String title,
    required String thumb,
    required String videoUrl,
    required VideoSource source,
    String duration = '',
    String views = '',
    DateTime? publishedAt,
  }) => FeedVideo(
    title: cleanTitle(title),
    thumb: thumb,
    videoUrl: videoUrl,
    duration: duration,
    views: views,
    source: source,
    publishedAt: publishedAt,
  );

  // ── Helpers ────────────────────────────────────────────────────────────────

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

  static String fmtViewsPublic(dynamic raw) => _fmtViews(raw);
}

// ─────────────────────────────────────────────────────────────────────────────
// FeedFetcher
// ─────────────────────────────────────────────────────────────────────────────
class FeedFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  static const _timeout = Duration(seconds: 14);
  static final _rng = Random();

  // Termos aleatórios para variedade nos pedidos
  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'wild', 'homemade', 'mature',
    'babe', 'hardcore', 'lesbian', 'threesome', 'pov', 'creampie',
    'riding', 'blowjob', 'anal', 'busty', 'petite', 'ebony', 'redhead',
  ];

  // Cache global de URLs já vistas — evita repetições entre chamadas
  static final Set<String> _seenUrls = {};

  static String _term() => _terms[_rng.nextInt(_terms.length)];
  static int _rnd(int max) => _rng.nextInt(max) + 1;

  // ── HTTP ───────────────────────────────────────────────────────────────────

  static Future<String?> _get(String url, {Map<String, String>? extra}) async {
    try {
      final r = await http.get(Uri.parse(url), headers: {
        'User-Agent': _ua,
        'Accept': 'text/html,application/json,*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        ...?extra,
      }).timeout(_timeout);
      if (r.statusCode == 200) return r.body;
    } catch (_) {}
    return null;
  }

  static Future<dynamic> _json(String url, {Map<String, String>? extra}) async {
    final body = await _get(url, extra: extra);
    if (body == null) return null;
    try { return jsonDecode(body); } catch (_) { return null; }
  }

  // ── Deduplicação ───────────────────────────────────────────────────────────

  static List<FeedVideo> _dedup(List<FeedVideo> items) {
    final result = <FeedVideo>[];
    for (final v in items) {
      if (_seenUrls.contains(v.videoUrl)) continue;
      _seenUrls.add(v.videoUrl);
      result.add(v);
    }
    // Limitar cache a 5000 para não crescer infinitamente
    if (_seenUrls.length > 5000) _seenUrls.clear();
    return result;
  }

  // ── DOM scraper ────────────────────────────────────────────────────────────

  static final _skipHref = RegExp(
    r'/(out|go|tag|tags|cat|category|model|channel|pornstar|studio|actor|login|register|signup)(/|$)',
    caseSensitive: false,
  );

  static List<FeedVideo> _domScrape(
    String html,
    VideoSource src,
    String base,
    List<String> selectors,
  ) {
    final doc = htmlParser.parse(html);
    final items = <FeedVideo>[];

    for (final sel in selectors) {
      List elements = [];
      try { elements = doc.querySelectorAll(sel); } catch (_) { continue; }

      for (final el in elements) {
        try {
          final a = el.querySelector('a') ?? (el.localName == 'a' ? el : null);
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty || _skipHref.hasMatch(href)) continue;
          final videoUrl = _abs(base, href);
          if (videoUrl.isEmpty) continue;

          final img = el.querySelector('img');
          final thumb = img?.attributes['data-src'] ??
              img?.attributes['data-original'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['data-thumb'] ??
              img?.attributes['src'] ?? '';
          if (thumb.isEmpty || thumb.contains('data:') || !thumb.startsWith('http')) continue;

          final title = _txt(
            a?.attributes['title'] ??
            el.querySelector('.title,[class*="title"],[class*="name"],strong,h3,h2,h4')?.text ?? '',
          );
          if (title.isEmpty || title.length < 3) continue;

          final dur   = el.querySelector('.duration,.time,[class*="dur"],[class*="time"]')?.text.trim() ?? '';
          final views = el.querySelector('.views,.count,[class*="view"],[class*="count"]')?.text.trim() ?? '';

          items.add(FeedVideo.fromScraped(
            title: title, thumb: thumb, videoUrl: videoUrl,
            source: src, duration: dur, views: views,
          ));
        } catch (_) {}
      }
      if (items.length >= 12) break;
    }
    return items;
  }

  static String _abs(String base, String href) {
    if (href.isEmpty) return '';
    if (href.startsWith('http')) return href;
    try { return Uri.parse(base).resolve(href).toString(); } catch (_) { return ''; }
  }

  static String _txt(String? s) {
    if (s == null || s.isEmpty) return '';
    return s.replaceAll(RegExp(r'&\w+;'), ' ')
            .replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  // ── RSS parser ─────────────────────────────────────────────────────────────

  static String _xmlTag(dynamic el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); } catch (_) { return ''; }
  }

  static String _rssThumb(dynamic item) {
    try {
      for (final child in (item as dynamic).childElements) {
        final qn = (child.qualifiedName as String? ?? '').toLowerCase();
        final ln = (child.localName as String? ?? '').toLowerCase();
        if (qn.contains('content') || qn.contains('thumbnail') ||
            ln == 'content' || ln == 'thumbnail') {
          final u = child.getAttribute('url') as String? ?? '';
          if (u.isNotEmpty) return u;
        }
        if (ln == 'enclosure') {
          final u = child.getAttribute('url') as String? ?? '';
          final t = child.getAttribute('type') as String? ?? '';
          if (u.isNotEmpty && (t.startsWith('image') || u.contains('.jpg') || u.contains('.png'))) return u;
        }
      }
    } catch (_) {}
    try {
      final desc = _xmlTag(item, 'description');
      if (desc.isNotEmpty) {
        final m = RegExp('<img[^>]+src=["\'](.*?)["\']').firstMatch(desc);
        if (m != null) return m.group(1) ?? '';
      }
    } catch (_) {}
    return '';
  }

  static DateTime? _rssDate(String raw) {
    try { return DateTime.parse(raw); } catch (_) {}
    try {
      const months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
      };
      final m = RegExp(r'\w+,\s+(\d{1,2})\s+(\w{3})\s+(\d{4})\s+(\d{2}):(\d{2}):(\d{2})').firstMatch(raw);
      if (m != null) return DateTime.utc(
        int.parse(m.group(3)!), months[m.group(2)] ?? 1, int.parse(m.group(1)!),
        int.parse(m.group(4)!), int.parse(m.group(5)!), int.parse(m.group(6)!),
      );
    } catch (_) {}
    return null;
  }

  static List<FeedVideo> _parseRss(
    String body,
    VideoSource src,
    String Function(String link) toUrl,
    String Function(String link) extractId,
  ) {
    final items = <FeedVideo>[];
    try {
      final doc = XmlDocument.parse(body);
      for (final item in doc.findAllElements('item')) {
        final link  = _xmlTag(item, 'link');
        final title = _xmlTag(item, 'title');
        final thumb = _rssThumb(item);
        final pub   = _xmlTag(item, 'pubDate');
        if (link.isEmpty || thumb.isEmpty) continue;
        final id = extractId(link);
        if (id.isEmpty) continue;
        items.add(FeedVideo.fromScraped(
          title: title.isEmpty ? 'Vídeo' : title,
          thumb: thumb,
          videoUrl: toUrl(link),
          source: src,
          publishedAt: pub.isNotEmpty ? _rssDate(pub) : null,
        ));
      }
    } catch (_) {}
    return items;
  }

  // ── FETCHERS API ───────────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchEporner(int page) async {
    final results = <FeedVideo>[];
    // Múltiplos pedidos com termos diferentes para variedade máxima
    final futures = List.generate(3, (_) async {
      final term = Uri.encodeComponent(_term());
      final p = _rng.nextInt(80) + 1;
      final d = await _json(
        'https://www.eporner.com/api/v2/video/search/?query=$term&per_page=20&page=$p&thumbsize=big&format=json&order=latest');
      if (d == null) return <FeedVideo>[];
      return ((d['videos'] as List?) ?? [])
          .map((v) => FeedVideo.fromEporner(v as Map<String, dynamic>))
          .whereType<FeedVideo>().toList();
    });
    final all = await Future.wait(futures);
    for (final l in all) results.addAll(l);
    // Limitar a 15 para não dominar o feed
    results.shuffle(_rng);
    return _dedup(results.take(15).toList());
  }

  static Future<List<FeedVideo>> fetchPornhub(int page) async {
    final results = <FeedVideo>[];
    final orders = ['newest', 'mostviewed', 'rating', 'featured'];
    final futures = List.generate(2, (i) async {
      final order = orders[_rng.nextInt(orders.length)];
      final p = _rng.nextInt(50) + 1;
      final d = await _json(
        'https://www.pornhub.com/webmasters/search?search=${Uri.encodeComponent(_term())}&ordering=$order&page=$p&thumbsize=medium&format=json');
      if (d == null) return <FeedVideo>[];
      return ((d['videos'] as List?) ?? []).map((v) {
        final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
        return FeedVideo.fromPornhub(inner);
      }).whereType<FeedVideo>().toList();
    });
    final all = await Future.wait(futures);
    for (final l in all) results.addAll(l);
    results.shuffle(_rng);
    return _dedup(results.take(20).toList());
  }

  static Future<List<FeedVideo>> fetchRedtube(int page) async {
    final results = <FeedVideo>[];
    final orders = ['mostviewed', 'rating', 'newestdate', 'featured'];
    final futures = List.generate(2, (_) async {
      final term  = Uri.encodeComponent(_term());
      final order = orders[_rng.nextInt(orders.length)];
      final p = _rng.nextInt(40) + 1;
      final d = await _json(
        'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=medium&count=20&search=$term&ordering=$order&page=$p');
      if (d == null) return <FeedVideo>[];
      return ((d['videos'] as List?) ?? []).map((v) {
        final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
        return FeedVideo.fromRedtube(inner);
      }).whereType<FeedVideo>().toList();
    });
    final all = await Future.wait(futures);
    for (final l in all) results.addAll(l);
    results.shuffle(_rng);
    return _dedup(results.take(20).toList());
  }

  static Future<List<FeedVideo>> fetchYouporn(int page) async {
    final results = <FeedVideo>[];
    final futures = List.generate(2, (_) async {
      final p = _rng.nextInt(20) + 1;
      final d = await _json(
        'https://www.youporn.com/api/video/search/?is_top=1&page=$p&per_page=20',
        extra: {'Referer': 'https://www.youporn.com/'});
      if (d == null) return <FeedVideo>[];
      final list = (d['videos'] ?? d['data'] ?? d) as List? ?? [];
      return list.map((v) => FeedVideo.fromYouporn(v as Map<String, dynamic>))
          .whereType<FeedVideo>().toList();
    });
    final all = await Future.wait(futures);
    for (final l in all) results.addAll(l);
    results.shuffle(_rng);
    return _dedup(results.take(20).toList());
  }

  static Future<List<FeedVideo>> fetchBeeg(int page) async {
    final p = _rnd(30);
    final d = await _json(
      'https://beeg.com/api/v6/index?step=2&page=$p&format=json');
    if (d == null) return [];
    final list = (d['videos'] ?? d) as List? ?? [];
    return _dedup(list.map((v) => FeedVideo.fromBeeg(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList());
  }

  static Future<List<FeedVideo>> fetchTube8(int page) async {
    final term = Uri.encodeComponent(_term());
    final p = _rnd(20);
    final d = await _json(
      'https://www.tube8.com/api/videos/?search_query=$term&page=$p&thumbsize=medium&format=json');
    if (d == null) return [];
    final list = (d['videos'] ?? d) as List? ?? [];
    return _dedup(list.map((v) => FeedVideo.fromTube8(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList());
  }

  // ── FETCHERS RSS + DOM ────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchXvideos(int page) async {
    // Várias feeds RSS para mais variedade
    final feeds = [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-weekly/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-monthly/0',
    ];
    for (final url in feeds) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.xvideos,
        (link) => link.startsWith('http') ? link : 'https://www.xvideos.com$link',
        (link) => RegExp(r'/video(\d+)').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return _dedup(items);
    }
    // JSON embed fallback
    final html = await _get('https://www.xvideos.com/?k=${Uri.encodeComponent(_term())}');
    if (html != null) {
      final items = <FeedVideo>[];
      final re = RegExp(r'"id"\s*:\s*(\d+)[^}]{0,300}?"tf"\s*:\s*"([^"]+)"[^}]{0,300}?"t"\s*:\s*"([^"]+)"');
      for (final m in re.allMatches(html)) {
        if (items.length >= 20) break;
        final id = m.group(1)!;
        final tf = m.group(2)!;
        final t  = m.group(3)!;
        final thumb = tf.startsWith('http') ? tf : 'https://img-l3.xvideos-cdn.com/$tf';
        items.add(FeedVideo.fromScraped(
          title: FeedVideo.cleanTitle(t), thumb: thumb,
          videoUrl: 'https://www.xvideos.com/video$id/', source: VideoSource.xvideos));
      }
      if (items.isNotEmpty) return _dedup(items);
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    final urls = ['https://xhamster.com/newest', 'https://xhamster.com/videos', 'https://xhamster.com/best'];
    for (final url in urls) {
      final html = await _get(url);
      if (html == null) continue;
      final mInit = RegExp(r'window\.__initials__\s*=\s*(\{[\s\S]{200,}?\})\s*;?\s*<\/script>').firstMatch(html);
      if (mInit != null) {
        try {
          final d = jsonDecode(mInit.group(1)!);
          final list = (d['videoList']?['models'] ?? d['videos'] ?? []) as List;
          final items = <FeedVideo>[];
          for (final v in list.take(20)) {
            final thumb = v['thumbURL'] ?? v['thumbUrl'] ?? v['thumbnail'] ?? '';
            final title = FeedVideo.cleanTitle((v['title'] ?? '').toString());
            var vUrl = v['pageURL'] ?? v['url'] ?? '';
            if (thumb.toString().isEmpty || title.isEmpty || vUrl.toString().isEmpty) continue;
            if (!vUrl.toString().startsWith('http')) vUrl = 'https://xhamster.com$vUrl';
            items.add(FeedVideo.fromScraped(
              title: title, thumb: thumb.toString(), videoUrl: vUrl.toString(),
              source: VideoSource.xhamster,
              duration: v['duration']?.toString() ?? '',
              views: FeedVideo.fmtViewsPublic(v['views']),
            ));
          }
          if (items.length >= 3) return _dedup(items);
        } catch (_) {}
      }
      final items = _domScrape(html, VideoSource.xhamster, 'https://xhamster.com',
          ['a.video-thumb', 'a[class*="video-thumb"]', '.thumb-list__item', '.video-thumb__wrap']);
      if (items.length >= 3) return _dedup(items);
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchSpankbang(int page) async {
    for (final url in ['https://spankbang.com/rss/', 'https://spankbang.com/rss/trending/', 'https://spankbang.com/rss/new/']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.spankbang,
        (link) => link.startsWith('http') ? link : 'https://spankbang.com$link',
        (link) {
          final m = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(Uri.tryParse(link)?.path ?? '');
          return m?.group(1) ?? '';
        });
      if (items.isNotEmpty) return _dedup(items);
    }
    for (final url in ['https://spankbang.com/trending/', 'https://spankbang.com/new/', 'https://spankbang.com/most-popular/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.spankbang, 'https://spankbang.com',
          ['.video-item', '.stream_item', '.video-item-main', 'li[class*="video"]']);
      if (items.length >= 3) return _dedup(items);
    }
    return [];
  }

  static Future<List<FeedVideo>> _rssOrDom(
    List<String> rssUrls,
    List<String> domUrls,
    VideoSource src,
    String base,
    List<String> domSelectors,
    String Function(String) extractId,
  ) async {
    for (final url in rssUrls) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, src,
        (link) => link.startsWith('http') ? link : '$base$link',
        extractId);
      if (items.isNotEmpty) return _dedup(items);
    }
    for (final url in domUrls) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, src, base, domSelectors);
      if (items.length >= 3) return _dedup(items);
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchBravotube(int page) => _rssOrDom(
    ['https://www.bravotube.net/rss/new/', 'https://www.bravotube.net/rss/popular/'],
    ['https://www.bravotube.net/newest/', 'https://www.bravotube.net/'],
    VideoSource.bravotube, 'https://www.bravotube.net',
    ['.thumb-item', '.video-item', 'article', '.item'],
    (link) => RegExp(r'-(\d+)\.html').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchDrtuber(int page) => _rssOrDom(
    ['https://www.drtuber.com/rss/latest', 'https://www.drtuber.com/rss/popular'],
    ['https://www.drtuber.com/videos/newest', 'https://www.drtuber.com/'],
    VideoSource.drtuber, 'https://www.drtuber.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/video/(\d+)').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchTxxx(int page) => _rssOrDom(
    ['https://www.txxx.com/rss/new/', 'https://www.txxx.com/rss/popular/'],
    ['https://www.txxx.com/videos/', 'https://www.txxx.com/'],
    VideoSource.txxx, 'https://www.txxx.com',
    ['.thumb-item', '.video-item', 'article', '.item'],
    (link) => RegExp(r'-(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchGotporn(int page) => _rssOrDom(
    ['https://www.gotporn.com/rss/latest', 'https://www.gotporn.com/rss/popular'],
    ['https://www.gotporn.com/videos/', 'https://www.gotporn.com/'],
    VideoSource.gotporn, 'https://www.gotporn.com',
    ['.video-item', 'li.item', 'article', '.thumb', 'a[href*="/video"]'],
    (link) => RegExp(r'/video-?(\d+)').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchPorndig(int page) => _rssOrDom(
    ['https://www.porndig.com/rss', 'https://www.porndig.com/rss?category=latest'],
    ['https://www.porndig.com/videos/', 'https://www.porndig.com/'],
    VideoSource.porndig, 'https://www.porndig.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'-(\d+)\.html').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchTnaflix(int page) => _rssOrDom(
    ['https://www.tnaflix.com/rss/most-viewed', 'https://www.tnaflix.com/rss/new-videos'],
    ['https://www.tnaflix.com/', 'https://www.tnaflix.com/videos/'],
    VideoSource.tnaflix, 'https://www.tnaflix.com',
    ['.videoThumb', '.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/video/(\d+)').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchEmpflix(int page) => _rssOrDom(
    ['https://www.empflix.com/rss/most-viewed', 'https://www.empflix.com/rss/new-videos'],
    ['https://www.empflix.com/', 'https://www.empflix.com/videos/'],
    VideoSource.empflix, 'https://www.empflix.com',
    ['.videoThumb', '.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/video/(\d+)').firstMatch(link)?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchPorntrex(int page) => _rssOrDom(
    ['https://www.porntrex.com/rss/newest/', 'https://www.porntrex.com/rss/top-rated/'],
    ['https://www.porntrex.com/', 'https://www.porntrex.com/most-popular/${_rnd(5)}/'],
    VideoSource.porntrex, 'https://www.porntrex.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchHclips(int page) => _rssOrDom(
    ['https://hclips.com/rss/', 'https://hclips.com/rss/new/'],
    ['https://hclips.com/', 'https://hclips.com/videos/newest/'],
    VideoSource.hclips, 'https://hclips.com',
    ['.thumb-item', '.video-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchTubedupe(int page) => _rssOrDom(
    ['https://www.tubedupe.com/rss/newest/', 'https://www.tubedupe.com/rss/popular/'],
    ['https://www.tubedupe.com/', 'https://www.tubedupe.com/newest/'],
    VideoSource.tubedupe, 'https://www.tubedupe.com',
    ['.thumb-item', '.video-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchNuvid(int page) => _rssOrDom(
    ['https://www.nuvid.com/rss/new/', 'https://www.nuvid.com/rss/popular/'],
    ['https://www.nuvid.com/videos/', 'https://www.nuvid.com/videos/newest/${_rnd(10)}'],
    VideoSource.nuvid, 'https://www.nuvid.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchSunporno(int page) => _rssOrDom(
    ['https://www.sunporno.com/rss/newest/', 'https://www.sunporno.com/rss/most-popular/'],
    ['https://www.sunporno.com/videos/', 'https://www.sunporno.com/videos/newest/${_rnd(10)}'],
    VideoSource.sunporno, 'https://www.sunporno.com',
    ['.thumb-item', '.video-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchPornone(int page) => _rssOrDom(
    ['https://pornone.com/rss/new/', 'https://pornone.com/rss/popular/'],
    ['https://pornone.com/', 'https://pornone.com/videos/'],
    VideoSource.pornone, 'https://pornone.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchSlutload(int page) => _rssOrDom(
    ['https://www.slutload.com/rss/newest/', 'https://www.slutload.com/rss/most-popular/'],
    ['https://www.slutload.com/', 'https://www.slutload.com/new/'],
    VideoSource.slutload, 'https://www.slutload.com',
    ['.video-item', '.thumb-item', '.videoBlock', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchIceporn(int page) => _rssOrDom(
    ['https://www.iceporn.com/rss/newest/', 'https://www.iceporn.com/rss/popular/'],
    ['https://www.iceporn.com/', 'https://www.iceporn.com/videos/newest/'],
    VideoSource.iceporn, 'https://www.iceporn.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchVjav(int page) => _rssOrDom(
    ['https://vjav.com/rss/', 'https://vjav.com/rss/newest/'],
    ['https://vjav.com/', 'https://vjav.com/videos/newest/'],
    VideoSource.vjav, 'https://vjav.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchJizzbunker(int page) => _rssOrDom(
    ['https://www.jizzbunker.com/rss', 'https://www.jizzbunker.com/rss/newest'],
    ['https://jizzbunker.com/', 'https://jizzbunker.com/new-videos/'],
    VideoSource.jizzbunker, 'https://jizzbunker.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchCliphunter(int page) => _rssOrDom(
    ['https://www.cliphunter.com/rss/newest', 'https://www.cliphunter.com/rss/popular'],
    ['https://www.cliphunter.com/', 'https://www.cliphunter.com/?page=${_rnd(20)}'],
    VideoSource.cliphunter, 'https://www.cliphunter.com',
    ['.video-item', '.thumb-item', '.pc_thumb', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchSexvid(int page) => _rssOrDom(
    ['https://sexvid.xxx/rss/', 'https://sexvid.xxx/rss/new/'],
    ['https://sexvid.xxx/', 'https://sexvid.xxx/videos/newest/'],
    VideoSource.sexvid, 'https://sexvid.xxx',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchYeptube(int page) => _rssOrDom(
    ['https://www.yeptube.com/rss/newest/', 'https://www.yeptube.com/rss/popular/'],
    ['https://www.yeptube.com/', 'https://www.yeptube.com/videos/'],
    VideoSource.yeptube, 'https://www.yeptube.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  // ── FETCHERS novos ────────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchXnxx(int page) async {
    final term = Uri.encodeComponent(_term());
    final p = _rnd(30);
    for (final url in [
      'https://www.xnxx.com/search/${term}/$p',
      'https://www.xnxx.com/',
    ]) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.xnxx, 'https://www.xnxx.com',
          ['.mozaique .thumb-block', '.thumb-block', 'div[class*="thumb"]', '.mozaique > div']);
      if (items.length >= 3) return _dedup(items);
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchPornoxo(int page) => _rssOrDom(
    ['https://www.pornoxo.com/rss/new/', 'https://www.pornoxo.com/rss/popular/'],
    ['https://www.pornoxo.com/', 'https://www.pornoxo.com/videos/newest/'],
    VideoSource.pornoxo, 'https://www.pornoxo.com',
    ['.video-item', '.thumb-item', 'article', '.item', 'li[class*="video"]'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchAnysex(int page) => _rssOrDom(
    ['https://anysex.com/rss/', 'https://anysex.com/rss/new/'],
    ['https://anysex.com/', 'https://anysex.com/videos/'],
    VideoSource.anysex, 'https://anysex.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchFuqer(int page) => _rssOrDom(
    ['https://fuqer.com/rss/', 'https://fuqer.com/rss/new/'],
    ['https://fuqer.com/', 'https://fuqer.com/videos/'],
    VideoSource.fuqer, 'https://fuqer.com',
    ['.video-item', '.thumb-item', 'article', '.item', 'li[class*="video"]'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchFapster(int page) => _rssOrDom(
    ['https://fapster.xxx/rss/', 'https://fapster.xxx/rss/newest/'],
    ['https://fapster.xxx/', 'https://fapster.xxx/videos/newest/'],
    VideoSource.fapster, 'https://fapster.xxx',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchProporn(int page) => _rssOrDom(
    ['https://proporn.com/rss/', 'https://proporn.com/rss/new/'],
    ['https://proporn.com/', 'https://proporn.com/videos/'],
    VideoSource.proporn, 'https://proporn.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchH2porn(int page) => _rssOrDom(
    ['https://www.h2porn.com/rss/', 'https://www.h2porn.com/rss/new/'],
    ['https://www.h2porn.com/', 'https://www.h2porn.com/newest/'],
    VideoSource.h2porn, 'https://www.h2porn.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchAlphaporno(int page) => _rssOrDom(
    ['https://www.alphaporno.com/rss/', 'https://www.alphaporno.com/rss/newest/'],
    ['https://www.alphaporno.com/', 'https://www.alphaporno.com/videos/'],
    VideoSource.alphaporno, 'https://www.alphaporno.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchXcafe(int page) => _rssOrDom(
    ['https://xcafe.com/rss/', 'https://xcafe.com/rss/new/'],
    ['https://xcafe.com/', 'https://xcafe.com/videos/newest/'],
    VideoSource.xcafe, 'https://xcafe.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  static Future<List<FeedVideo>> fetchTubecup(int page) => _rssOrDom(
    ['https://tubecup.com/rss/', 'https://tubecup.com/rss/newest/'],
    ['https://tubecup.com/', 'https://tubecup.com/newest/'],
    VideoSource.tubecup, 'https://tubecup.com',
    ['.video-item', '.thumb-item', 'article', '.item'],
    (link) => RegExp(r'/(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '',
  );

  // ── fetchAll — balanceado, sem dominância ──────────────────────────────────

  static Future<List<FeedVideo>> fetchAll(int page) async {
    final seed = DateTime.now().millisecondsSinceEpoch ^ page.hashCode ^ _rng.nextInt(9999);
    final rng  = Random(seed);

    // Cada fonte tem peso 1 — nenhuma domina
    // Todas correm em paralelo com timeout de 14s cada
    final results = await Future.wait([
      // APIs (mais fiáveis, mais variedade por pedido)
      fetchPornhub(rng.nextInt(50) + 1),
      fetchRedtube(rng.nextInt(40) + 1),
      fetchYouporn(rng.nextInt(20) + 1),
      fetchEporner(rng.nextInt(80) + 1),
      fetchBeeg(rng.nextInt(30) + 1),
      fetchTube8(rng.nextInt(20) + 1),
      // RSS + DOM (cada uma capped a ~12 itens pelo _domScrape)
      fetchXvideos(page),
      fetchXhamster(page),
      fetchSpankbang(page),
      fetchBravotube(page),
      fetchDrtuber(page),
      fetchTxxx(page),
      fetchGotporn(page),
      fetchPorndig(page),
      fetchTnaflix(page),
      fetchEmpflix(page),
      fetchPorntrex(page),
      fetchHclips(page),
      fetchTubedupe(page),
      fetchNuvid(page),
      fetchSunporno(page),
      fetchPornone(page),
      fetchSlutload(page),
      fetchIceporn(page),
      fetchVjav(page),
      fetchJizzbunker(page),
      fetchCliphunter(page),
      fetchSexvid(page),
      fetchYeptube(page),
      // Novas fontes
      fetchXnxx(page),
      fetchPornoxo(page),
      fetchAnysex(page),
      fetchFuqer(page),
      fetchFapster(page),
      fetchProporn(page),
      fetchH2porn(page),
      fetchAlphaporno(page),
      fetchXcafe(page),
      fetchTubecup(page),
    ].map((f) => f.timeout(const Duration(seconds: 14), onTimeout: () => [])));

    // Filtrar listas vazias
    final lists = results.where((l) => l.isNotEmpty).toList();
    if (lists.isEmpty) return [];

    // Limitar cada fonte a 8 vídeos máximo para evitar dominância
    final capped = lists.map((l) {
      final copy = List<FeedVideo>.from(l)..shuffle(rng);
      return copy.take(8).toList();
    }).toList();

    // Intercalar round-robin (1 de cada fonte por vez)
    final merged = <FeedVideo>[];
    final maxLen = capped.map((l) => l.length).reduce((a, b) => a > b ? a : b);
    for (int i = 0; i < maxLen; i++) {
      // Ordem aleatória das fontes a cada round
      final indices = List.generate(capped.length, (j) => j)..shuffle(rng);
      for (final j in indices) {
        if (i < capped[j].length) merged.add(capped[j][i]);
      }
    }

    // Shuffle final para mistura máxima
    merged.shuffle(rng);
    return merged;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// faviconForSource
// ─────────────────────────────────────────────────────────────────────────────
String faviconForSource(VideoSource src) {
  switch (src) {
    case VideoSource.eporner:        return 'https://www.eporner.com/favicon.ico';
    case VideoSource.pornhub:        return 'https://www.pornhub.com/favicon.ico';
    case VideoSource.redtube:        return 'https://www.redtube.com/favicon.ico';
    case VideoSource.youporn:        return 'https://www.youporn.com/favicon.ico';
    case VideoSource.xvideos:        return 'https://www.xvideos.com/favicon.ico';
    case VideoSource.xhamster:       return 'https://xhamster.com/favicon.ico';
    case VideoSource.spankbang:      return 'https://spankbang.com/favicon.ico';
    case VideoSource.bravotube:      return 'https://www.bravotube.net/favicon.ico';
    case VideoSource.drtuber:        return 'https://www.drtuber.com/favicon.ico';
    case VideoSource.txxx:           return 'https://www.txxx.com/favicon.ico';
    case VideoSource.gotporn:        return 'https://www.gotporn.com/favicon.ico';
    case VideoSource.porndig:        return 'https://www.porndig.com/favicon.ico';
    case VideoSource.beeg:           return 'https://beeg.com/favicon.ico';
    case VideoSource.tube8:          return 'https://www.tube8.com/favicon.ico';
    case VideoSource.tnaflix:        return 'https://www.tnaflix.com/favicon.ico';
    case VideoSource.empflix:        return 'https://www.empflix.com/favicon.ico';
    case VideoSource.porntrex:       return 'https://www.porntrex.com/favicon.ico';
    case VideoSource.hclips:         return 'https://hclips.com/favicon.ico';
    case VideoSource.tubedupe:       return 'https://www.tubedupe.com/favicon.ico';
    case VideoSource.nuvid:          return 'https://www.nuvid.com/favicon.ico';
    case VideoSource.sunporno:       return 'https://www.sunporno.com/favicon.ico';
    case VideoSource.pornone:        return 'https://pornone.com/favicon.ico';
    case VideoSource.slutload:       return 'https://www.slutload.com/favicon.ico';
    case VideoSource.iceporn:        return 'https://www.iceporn.com/favicon.ico';
    case VideoSource.vjav:           return 'https://vjav.com/favicon.ico';
    case VideoSource.jizzbunker:     return 'https://jizzbunker.com/favicon.ico';
    case VideoSource.cliphunter:     return 'https://www.cliphunter.com/favicon.ico';
    case VideoSource.sexvid:         return 'https://sexvid.xxx/favicon.ico';
    case VideoSource.yeptube:        return 'https://www.yeptube.com/favicon.ico';
    case VideoSource.xnxx:           return 'https://www.xnxx.com/favicon.ico';
    case VideoSource.pornoxo:        return 'https://www.pornoxo.com/favicon.ico';
    case VideoSource.anysex:         return 'https://anysex.com/favicon.ico';
    case VideoSource.fuqer:          return 'https://fuqer.com/favicon.ico';
    case VideoSource.fapster:        return 'https://fapster.xxx/favicon.ico';
    case VideoSource.proporn:        return 'https://proporn.com/favicon.ico';
    case VideoSource.h2porn:         return 'https://www.h2porn.com/favicon.ico';
    case VideoSource.alphaporno:     return 'https://www.alphaporno.com/favicon.ico';
    case VideoSource.watchmygf:      return 'https://watchmygf.me/favicon.ico';
    case VideoSource.xcafe:          return 'https://xcafe.com/favicon.ico';
    case VideoSource.tubecup:        return 'https://tubecup.com/favicon.ico';
    case VideoSource.vidlox:         return 'https://vidlox.me/favicon.ico';
    case VideoSource.naughtyamerica: return 'https://www.naughtyamerica.com/favicon.ico';
  }
}