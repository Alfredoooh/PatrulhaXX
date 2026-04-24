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
  slutload, iceporn, vjav, jizzbunker, cliphunter,
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
      case VideoSource.eporner:    return 'Eporner';
      case VideoSource.pornhub:    return 'Pornhub';
      case VideoSource.redtube:    return 'RedTube';
      case VideoSource.youporn:    return 'YouPorn';
      case VideoSource.xvideos:    return 'XVideos';
      case VideoSource.xhamster:   return 'xHamster';
      case VideoSource.spankbang:  return 'SpankBang';
      case VideoSource.bravotube:  return 'BravoTube';
      case VideoSource.drtuber:    return 'DrTuber';
      case VideoSource.txxx:       return 'TXXX';
      case VideoSource.gotporn:    return 'GotPorn';
      case VideoSource.porndig:    return 'PornDig';
      case VideoSource.beeg:       return 'Beeg';
      case VideoSource.tube8:      return 'Tube8';
      case VideoSource.tnaflix:    return 'TNAFlix';
      case VideoSource.empflix:    return 'EmpFlix';
      case VideoSource.porntrex:   return 'PornTrex';
      case VideoSource.hclips:     return 'HClips';
      case VideoSource.tubedupe:   return 'TubeDupe';
      case VideoSource.nuvid:      return 'Nuvid';
      case VideoSource.sunporno:   return 'SunPorno';
      case VideoSource.pornone:    return 'PornOne';
      case VideoSource.slutload:   return 'SlutLoad';
      case VideoSource.iceporn:    return 'IcePorn';
      case VideoSource.vjav:       return 'vJav';
      case VideoSource.jizzbunker: return 'JizzBunker';
      case VideoSource.cliphunter: return 'ClipHunter';
    }
  }

  String get sourceInitial {
    switch (source) {
      case VideoSource.eporner:    return 'EP';
      case VideoSource.pornhub:    return 'PH';
      case VideoSource.redtube:    return 'RT';
      case VideoSource.youporn:    return 'YP';
      case VideoSource.xvideos:    return 'XV';
      case VideoSource.xhamster:   return 'XH';
      case VideoSource.spankbang:  return 'SB';
      case VideoSource.bravotube:  return 'BT';
      case VideoSource.drtuber:    return 'DT';
      case VideoSource.txxx:       return 'TX';
      case VideoSource.gotporn:    return 'GP';
      case VideoSource.porndig:    return 'PD';
      case VideoSource.beeg:       return 'BG';
      case VideoSource.tube8:      return 'T8';
      case VideoSource.tnaflix:    return 'TN';
      case VideoSource.empflix:    return 'EF';
      case VideoSource.porntrex:   return 'PTX';
      case VideoSource.hclips:     return 'HC';
      case VideoSource.tubedupe:   return 'TD';
      case VideoSource.nuvid:      return 'NV';
      case VideoSource.sunporno:   return 'SP';
      case VideoSource.pornone:    return 'P1';
      case VideoSource.slutload:   return 'SL';
      case VideoSource.iceporn:    return 'IC';
      case VideoSource.vjav:       return 'VJ';
      case VideoSource.jizzbunker: return 'JB';
      case VideoSource.cliphunter: return 'CH';
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
// FeedFetcher — 27 fontes: API + RSS + DOM scraper
// ─────────────────────────────────────────────────────────────────────────────
class FeedFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';
  static const _timeout = Duration(seconds: 12);
  static final _rng = Random();
  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian', 'latina',
    'big', 'hot', 'sexy', 'beautiful', 'wild', 'homemade', 'mature',
  ];
  static String _term(int p) => _terms[p % _terms.length];
  static int _rnd(int max) => _rng.nextInt(max) + 1;

  // ── HTTP ───────────────────────────────────────────────────────────────────

  static Future<String?> _get(String url, {Map<String, String>? extra}) async {
    try {
      final r = await http.get(Uri.parse(url), headers: {
        'User-Agent': _ua,
        'Accept': 'text/html,application/json,*/*',
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

  // ── DOM scraper genérico ───────────────────────────────────────────────────

  static final _skipHref = RegExp(
    r'/(out|go|tag|tags|cat|category|model|channel|pornstar|studio|actor)(/|$)',
    caseSensitive: false,
  );

  static List<FeedVideo> _domScrape(
    String html,
    VideoSource src,
    String base,
    List<String> selectors,
  ) {
    final doc = htmlParser.parse(html);
    final seen = <String>{};
    final items = <FeedVideo>[];

    for (final sel in selectors) {
      List elements = [];
      try { elements = doc.querySelectorAll(sel); } catch (_) { continue; }

      for (final el in elements) {
        try {
          // link
          final a = el.querySelector('a') ?? (el.localName == 'a' ? el : null);
          final href = a?.attributes['href'] ?? '';
          if (href.isEmpty || _skipHref.hasMatch(href)) continue;
          final videoUrl = _abs(base, href);
          if (videoUrl.isEmpty || seen.contains(videoUrl)) continue;

          // thumbnail
          final img = el.querySelector('img');
          final thumb = img?.attributes['data-src'] ??
              img?.attributes['data-original'] ??
              img?.attributes['data-lazy-src'] ??
              img?.attributes['src'] ?? '';
          if (thumb.isEmpty || thumb.contains('data:') || !thumb.startsWith('http')) continue;

          // title
          final title = _txt(
            a?.attributes['title'] ??
            el.querySelector('.title,[class*="title"],[class*="name"],strong,h3,h2')?.text ?? '',
          );
          if (title.isEmpty || title.length < 3) continue;

          // duration & views
          final dur = el.querySelector('.duration,.time,[class*="dur"],[class*="time"]')?.text.trim() ?? '';
          final views = el.querySelector('.views,.count,[class*="view"],[class*="count"]')?.text.trim() ?? '';

          seen.add(videoUrl);
          items.add(FeedVideo.fromScraped(
            title: title, thumb: thumb, videoUrl: videoUrl,
            source: src, duration: dur, views: views,
          ));
        } catch (_) {}
      }
      if (items.length >= 8) break;
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

  // ── RSS parser genérico ────────────────────────────────────────────────────

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
        final m = RegExp(r'<img[^>]+src=["\'](.*?)["\']').firstMatch(desc);
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

  // ── API fetchers ───────────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchEporner(int page) async {
    final term = Uri.encodeComponent(_term(page));
    final d = await _json(
      'https://www.eporner.com/api/v2/video/search/?query=$term&per_page=20&page=${page.clamp(1, 60)}&thumbsize=big&format=json');
    if (d == null) return [];
    return ((d['videos'] as List?) ?? [])
        .map((v) => FeedVideo.fromEporner(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList();
  }

  static Future<List<FeedVideo>> fetchPornhub(int page) async {
    final d = await _json(
      'https://www.pornhub.com/webmasters/search?search=&ordering=newest&page=${page.clamp(1, 40)}&thumbsize=medium&format=json');
    if (d == null) return [];
    return ((d['videos'] as List?) ?? []).map((v) {
      final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
      return FeedVideo.fromPornhub(inner);
    }).whereType<FeedVideo>().toList();
  }

  static Future<List<FeedVideo>> fetchRedtube(int page) async {
    final term  = Uri.encodeComponent(_term(page));
    final order = ['mostviewed', 'rating', 'newestdate'][page % 3];
    final d = await _json(
      'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=medium&count=20&search=$term&ordering=$order&page=$page');
    if (d == null) return [];
    return ((d['videos'] as List?) ?? []).map((v) {
      final inner = v['video'] as Map<String, dynamic>? ?? v as Map<String, dynamic>;
      return FeedVideo.fromRedtube(inner);
    }).whereType<FeedVideo>().toList();
  }

  static Future<List<FeedVideo>> fetchYouporn(int page) async {
    final d = await _json(
      'https://www.youporn.com/api/video/search/?is_top=1&page=${page.clamp(1, 15)}&per_page=20',
      extra: {'Referer': 'https://www.youporn.com/'});
    if (d == null) return [];
    final list = (d['videos'] ?? d['data'] ?? d) as List? ?? [];
    return list.map((v) => FeedVideo.fromYouporn(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList();
  }

  static Future<List<FeedVideo>> fetchBeeg(int page) async {
    final d = await _json(
      'https://beeg.com/api/v6/index?step=2&page=${page.clamp(1, 30)}&format=json');
    if (d == null) return [];
    final list = (d['videos'] ?? d) as List? ?? [];
    return list.map((v) => FeedVideo.fromBeeg(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList();
  }

  static Future<List<FeedVideo>> fetchTube8(int page) async {
    final term = Uri.encodeComponent(_term(page));
    final d = await _json(
      'https://www.tube8.com/api/videos/?search_query=$term&page=${page.clamp(1, 20)}&thumbsize=medium&format=json');
    if (d == null) return [];
    final list = (d['videos'] ?? d) as List? ?? [];
    return list.map((v) => FeedVideo.fromTube8(v as Map<String, dynamic>))
        .whereType<FeedVideo>().toList();
  }

  // ── RSS + DOM fetchers ─────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchXvideos(int page) async {
    // 1) RSS
    for (final url in [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
    ]) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.xvideos,
        (link) => link.startsWith('http') ? link : 'https://www.xvideos.com$link',
        (link) => RegExp(r'/video(\d+)').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    // 2) DOM regex fallback
    final html = await _get('https://www.xvideos.com/');
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
      if (items.isNotEmpty) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchXhamster(int page) async {
    for (final url in ['https://xhamster.com/newest', 'https://xhamster.com/videos']) {
      final html = await _get(url);
      if (html == null) continue;
      // JSON embedded
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
          if (items.length >= 3) return items;
        } catch (_) {}
      }
      // DOM fallback
      final items = _domScrape(html, VideoSource.xhamster, 'https://xhamster.com',
          ['a.video-thumb', 'a[class*="video-thumb"]', '.thumb-list__item', '.video-thumb__wrap']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchSpankbang(int page) async {
    // RSS
    for (final url in ['https://spankbang.com/rss/', 'https://spankbang.com/rss/trending/']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.spankbang,
        (link) => link.startsWith('http') ? link : 'https://spankbang.com$link',
        (link) {
          final m = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(Uri.tryParse(link)?.path ?? '');
          return m?.group(1) ?? '';
        });
      if (items.isNotEmpty) return items;
    }
    // DOM
    for (final url in ['https://spankbang.com/trending/', 'https://spankbang.com/new/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.spankbang, 'https://spankbang.com',
          ['.video-item', '.stream_item', '.video-item-main', 'li[class*="video"]']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchBravotube(int page) async {
    for (final url in ['https://www.bravotube.net/rss/new/', 'https://www.bravotube.net/rss/popular/']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.bravotube,
        (link) => link.startsWith('http') ? link : 'https://www.bravotube.net$link',
        (link) => RegExp(r'-(\d+)\.html').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    for (final url in ['https://www.bravotube.net/newest/', 'https://www.bravotube.net/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.bravotube, 'https://www.bravotube.net',
          ['.thumb-item', '.video-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchDrtuber(int page) async {
    for (final url in ['https://www.drtuber.com/rss/latest', 'https://www.drtuber.com/rss/popular']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.drtuber,
        (link) => link.startsWith('http') ? link : 'https://www.drtuber.com$link',
        (link) => RegExp(r'/video/(\d+)').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    for (final url in ['https://www.drtuber.com/videos/newest', 'https://www.drtuber.com/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.drtuber, 'https://www.drtuber.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchTxxx(int page) async {
    for (final url in ['https://www.txxx.com/rss/new/', 'https://www.txxx.com/rss/popular/']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.txxx,
        (link) => link.startsWith('http') ? link : 'https://www.txxx.com$link',
        (link) => RegExp(r'-(\d+)/?$').firstMatch(Uri.tryParse(link)?.path ?? '')?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    for (final url in ['https://www.txxx.com/videos/', 'https://www.txxx.com/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.txxx, 'https://www.txxx.com',
          ['.thumb-item', '.video-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchGotporn(int page) async {
    for (final url in ['https://www.gotporn.com/rss/latest', 'https://www.gotporn.com/rss/popular']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.gotporn,
        (link) => link.startsWith('http') ? link : 'https://www.gotporn.com$link',
        (link) => RegExp(r'/video-?(\d+)').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    for (final url in ['https://www.gotporn.com/videos/', 'https://www.gotporn.com/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.gotporn, 'https://www.gotporn.com',
          ['.video-item', 'li.item', 'article', '.thumb', 'a[href*="/video"]']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchPorndig(int page) async {
    for (final url in ['https://www.porndig.com/rss', 'https://www.porndig.com/rss?category=latest']) {
      final body = await _get(url);
      if (body == null) continue;
      final items = _parseRss(body, VideoSource.porndig,
        (link) => link.startsWith('http') ? link : 'https://www.porndig.com$link',
        (link) => RegExp(r'-(\d+)\.html').firstMatch(link)?.group(1) ?? '');
      if (items.isNotEmpty) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchTnaflix(int page) async {
    for (final url in ['https://www.tnaflix.com/', 'https://www.tnaflix.com/videos/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.tnaflix, 'https://www.tnaflix.com',
          ['.videoThumb', '.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchEmpflix(int page) async {
    for (final url in ['https://www.empflix.com/', 'https://www.empflix.com/videos/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.empflix, 'https://www.empflix.com',
          ['.videoThumb', '.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchPorntrex(int page) async {
    final p = _rnd(5);
    for (final url in ['https://www.porntrex.com/', 'https://www.porntrex.com/most-popular/$p/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.porntrex, 'https://www.porntrex.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchHclips(int page) async {
    for (final url in ['https://hclips.com/', 'https://hclips.com/videos/newest/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.hclips, 'https://hclips.com',
          ['.thumb-item', '.video-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchTubedupe(int page) async {
    for (final url in ['https://www.tubedupe.com/', 'https://www.tubedupe.com/newest/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.tubedupe, 'https://www.tubedupe.com',
          ['.thumb-item', '.video-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchNuvid(int page) async {
    final p = _rnd(10);
    for (final url in ['https://www.nuvid.com/videos/', 'https://www.nuvid.com/videos/newest/$p']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.nuvid, 'https://www.nuvid.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchSunporno(int page) async {
    final p = _rnd(10);
    for (final url in ['https://www.sunporno.com/videos/', 'https://www.sunporno.com/videos/newest/$p']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.sunporno, 'https://www.sunporno.com',
          ['.thumb-item', '.video-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchPornone(int page) async {
    for (final url in ['https://pornone.com/', 'https://pornone.com/videos/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.pornone, 'https://pornone.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchSlutload(int page) async {
    for (final url in ['https://www.slutload.com/', 'https://www.slutload.com/new/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.slutload, 'https://www.slutload.com',
          ['.video-item', '.thumb-item', '.videoBlock', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchIceporn(int page) async {
    for (final url in ['https://www.iceporn.com/', 'https://www.iceporn.com/videos/newest/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.iceporn, 'https://www.iceporn.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchVjav(int page) async {
    for (final url in ['https://vjav.com/', 'https://vjav.com/videos/newest/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.vjav, 'https://vjav.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchJizzbunker(int page) async {
    for (final url in ['https://jizzbunker.com/', 'https://jizzbunker.com/new-videos/']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.jizzbunker, 'https://jizzbunker.com',
          ['.video-item', '.thumb-item', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  static Future<List<FeedVideo>> fetchCliphunter(int page) async {
    final p = _rnd(20);
    for (final url in ['https://www.cliphunter.com/', 'https://www.cliphunter.com/?page=$p']) {
      final html = await _get(url);
      if (html == null) continue;
      final items = _domScrape(html, VideoSource.cliphunter, 'https://www.cliphunter.com',
          ['.video-item', '.thumb-item', '.pc_thumb', 'article', '.item']);
      if (items.length >= 3) return items;
    }
    return [];
  }

  // ── fetchAll ───────────────────────────────────────────────────────────────

  static Future<List<FeedVideo>> fetchAll(int page) async {
    final rng = Random(DateTime.now().millisecondsSinceEpoch ^ page.hashCode);
    final results = await Future.wait([
      fetchEporner(rng.nextInt(60) + 1),
      fetchPornhub(rng.nextInt(40) + 1),
      fetchRedtube(rng.nextInt(30) + 1),
      fetchYouporn(rng.nextInt(20) + 1),
      fetchBeeg(rng.nextInt(30) + 1),
      fetchTube8(rng.nextInt(20) + 1),
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
    ]);

    final lists = results.where((l) => l.isNotEmpty).toList();
    if (lists.isEmpty) return [];

    final merged = <FeedVideo>[];
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

// ─────────────────────────────────────────────────────────────────────────────
// faviconForSource
// ─────────────────────────────────────────────────────────────────────────────
String faviconForSource(VideoSource src) {
  switch (src) {
    case VideoSource.eporner:    return 'https://www.eporner.com/favicon.ico';
    case VideoSource.pornhub:    return 'https://www.pornhub.com/favicon.ico';
    case VideoSource.redtube:    return 'https://www.redtube.com/favicon.ico';
    case VideoSource.youporn:    return 'https://www.youporn.com/favicon.ico';
    case VideoSource.xvideos:    return 'https://www.xvideos.com/favicon.ico';
    case VideoSource.xhamster:   return 'https://xhamster.com/favicon.ico';
    case VideoSource.spankbang:  return 'https://spankbang.com/favicon.ico';
    case VideoSource.bravotube:  return 'https://www.bravotube.net/favicon.ico';
    case VideoSource.drtuber:    return 'https://www.drtuber.com/favicon.ico';
    case VideoSource.txxx:       return 'https://www.txxx.com/favicon.ico';
    case VideoSource.gotporn:    return 'https://www.gotporn.com/favicon.ico';
    case VideoSource.porndig:    return 'https://www.porndig.com/favicon.ico';
    case VideoSource.beeg:       return 'https://beeg.com/favicon.ico';
    case VideoSource.tube8:      return 'https://www.tube8.com/favicon.ico';
    case VideoSource.tnaflix:    return 'https://www.tnaflix.com/favicon.ico';
    case VideoSource.empflix:    return 'https://www.empflix.com/favicon.ico';
    case VideoSource.porntrex:   return 'https://www.porntrex.com/favicon.ico';
    case VideoSource.hclips:     return 'https://hclips.com/favicon.ico';
    case VideoSource.tubedupe:   return 'https://www.tubedupe.com/favicon.ico';
    case VideoSource.nuvid:      return 'https://www.nuvid.com/favicon.ico';
    case VideoSource.sunporno:   return 'https://www.sunporno.com/favicon.ico';
    case VideoSource.pornone:    return 'https://pornone.com/favicon.ico';
    case VideoSource.slutload:   return 'https://www.slutload.com/favicon.ico';
    case VideoSource.iceporn:    return 'https://www.iceporn.com/favicon.ico';
    case VideoSource.vjav:       return 'https://vjav.com/favicon.ico';
    case VideoSource.jizzbunker: return 'https://jizzbunker.com/favicon.ico';
    case VideoSource.cliphunter: return 'https://www.cliphunter.com/favicon.ico';
  }
}