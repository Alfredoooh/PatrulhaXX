import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as dom;
import 'models.dart';

// ─── CONFIG ──────────────────────────────────────────────────────────────────

const _servers = [
  'https://nuxxconvert1.onrender.com',
  'https://nuxxconvert2.onrender.com',
  'https://nuxxconvert3.onrender.com',
  'https://nuxxconvert4.onrender.com',
  'https://nuxxconvert5.onrender.com',
];

const _terms = [
  '', 'amateur', 'teen', 'milf', 'blonde', 'brunette',
  'asian', 'latina', 'big', 'hot', 'sexy',
];

final _rng = Random();
int _rnd(int max) => _rng.nextInt(max) + 1;
String _pick(List<String> a) => a[_rng.nextInt(a.length)];

const _timeout = Duration(seconds: 9);

// ─── UTILS ───────────────────────────────────────────────────────────────────

String _clean(String? s) {
  if (s == null || s.isEmpty) return '';
  return s
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

String _fmtViews(dynamic n) {
  final v = int.tryParse('$n') ?? 0;
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).round()}K';
  return v > 0 ? '$v' : '';
}

String _absUrl(String base, String href) {
  if (href.isEmpty) return '';
  if (href.startsWith('http')) return href;
  try {
    return Uri.parse(base).resolve(href).toString();
  } catch (_) {
    return '';
  }
}

// ─── HTTP ────────────────────────────────────────────────────────────────────

Future<String?> _directText(String url) async {
  try {
    final r = await http
        .get(Uri.parse(url), headers: {'Accept': 'text/html,*/*', 'User-Agent': 'Mozilla/5.0'})
        .timeout(_timeout);
    if (r.statusCode == 200) return r.body;
  } catch (_) {}
  return null;
}

Future<dynamic> _directJson(String url) async {
  try {
    final r = await http
        .get(Uri.parse(url), headers: {'Accept': 'application/json', 'User-Agent': 'Mozilla/5.0'})
        .timeout(_timeout);
    if (r.statusCode == 200) return jsonDecode(r.body);
  } catch (_) {}
  return null;
}

Future<String?> _proxyText(String url) async {
  for (final s in _servers) {
    try {
      final r = await http
          .get(Uri.parse('$s/proxy?url=${Uri.encodeComponent(url)}'))
          .timeout(_timeout);
      if (r.statusCode == 200) return r.body;
    } catch (_) {}
  }
  return null;
}

Future<dynamic> _proxyJson(String url) async {
  for (final s in _servers) {
    try {
      final r = await http
          .get(Uri.parse('$s/proxy?url=${Uri.encodeComponent(url)}'))
          .timeout(_timeout);
      if (r.statusCode == 200) return jsonDecode(r.body);
    } catch (_) {}
  }
  return null;
}

Future<String?> _tryText(String url) async {
  return await _directText(url) ?? await _proxyText(url);
}

Future<dynamic> _tryJson(String url) async {
  return await _directJson(url) ?? await _proxyJson(url);
}

// ─── EXTRACT VIDEO URL ───────────────────────────────────────────────────────

Future<String> extractVideoUrl(String pageUrl) async {
  for (final s in _servers) {
    try {
      final r = await http
          .get(Uri.parse('$s/extract?url=${Uri.encodeComponent(pageUrl)}'))
          .timeout(const Duration(seconds: 15));
      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        final link = data['link'];
        if (link != null && link.toString().isNotEmpty) return link.toString();
      }
    } catch (_) {}
  }
  throw Exception('Nao foi possivel extrair o video');
}

// ─── DOM SCRAPER GENERICO ────────────────────────────────────────────────────

final _skipHref = RegExp(r'/(out|go|tag|cat|model|channel|pornstar)/', caseSensitive: false);

List<VideoItem> _domScrape(String html, String source, String baseUrl, String itemSel) {
  final doc = htmlParser.parse(html);
  final items = <VideoItem>[];
  final selectors = itemSel.split(',').map((s) => s.trim()).toList();

  for (final sel in selectors) {
    final elements = _querySelectorAll(doc, sel);
    for (final el in elements) {
      try {
        final a = el.querySelector('a');
        final href = a?.attributes['href'] ?? '';
        if (href.isEmpty || _skipHref.hasMatch(href)) continue;
        final videoUrl = _absUrl(baseUrl, href);
        if (videoUrl.isEmpty) continue;

        final img = el.querySelector('img');
        final thumb = img?.attributes['data-src'] ??
            img?.attributes['data-original'] ??
            img?.attributes['src'] ??
            '';
        if (thumb.isEmpty || thumb.contains('data:') || !thumb.startsWith('http')) continue;

        final title = _clean(
          a?.attributes['title'] ??
          el.querySelector('strong')?.text ??
          el.querySelector('.title')?.text ??
          el.querySelector('h3')?.text ??
          '',
        );
        if (title.isEmpty || title.length < 3) continue;

        final durEl = el.querySelector('.duration') ??
            el.querySelector('.l') ??
            el.querySelector('[class*="dur"]');
        final dur = durEl?.text.trim() ?? '';

        items.add(VideoItem(
          title: title, thumb: thumb, videoUrl: videoUrl,
          duration: dur, views: '', source: source,
        ));
      } catch (_) {}
    }
    if (items.length >= 2) break;
  }
  return items;
}

List<dom.Element> _querySelectorAll(dom.Document doc, String sel) {
  try {
    return doc.querySelectorAll(sel);
  } catch (_) {
    return [];
  }
}

Future<List<VideoItem>> _scrapeAny(
  List<String> urls,
  String source,
  String baseUrl, {
  String? itemSel,
}) async {
  final sel = itemSel ?? '.video-item,.thumb-item,.item,.thumb,.video-block,article';
  for (final url in urls) {
    try {
      final html = await _tryText(url);
      if (html == null) continue;
      final items = _domScrape(html, source, baseUrl, sel);
      if (items.length >= 2) return items;
    } catch (_) {}
  }
  return [];
}

// ─── SHUFFLER ────────────────────────────────────────────────────────────────

List<T> _shuffle<T>(List<T> list) {
  final l = List<T>.from(list);
  for (var i = l.length - 1; i > 0; i--) {
    final j = _rng.nextInt(i + 1);
    final tmp = l[i]; l[i] = l[j]; l[j] = tmp;
  }
  return l;
}

// ─── FETCHERS API ────────────────────────────────────────────────────────────

Future<List<VideoItem>> fetchEporner() async {
  try {
    final term = Uri.encodeComponent(_pick(_terms));
    final d = await _tryJson(
      'https://www.eporner.com/api/v2/video/search/?query=$term&per_page=20&page=${_rnd(60)}&thumbsize=big&format=json',
    );
    final videos = (d?['videos'] as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final thumbs = (v['thumbs'] as List?) ?? [];
      thumbs.sort((a, b) => ((b['width'] ?? 0) as int).compareTo((a['width'] ?? 0) as int));
      final thumb = thumbs.isNotEmpty ? (thumbs[0]['src'] ?? '') : '';
      if (thumb.isEmpty) continue;
      items.add(VideoItem(
        title: _clean(v['title']),
        thumb: thumb,
        videoUrl: 'https://www.eporner.com/video/${v['id']}/',
        duration: '${v['duration'] ?? ''}',
        views: _fmtViews(v['views']),
        source: 'eporner',
      ));
    }
    return items;
  } catch (_) { return []; }
}

Future<List<VideoItem>> fetchPornhub() async {
  try {
    final d = await _proxyJson(
      'https://www.pornhub.com/webmasters/search?search=&ordering=newest&page=${_rnd(40)}&thumbsize=medium&format=json',
    );
    final videos = (d?['videos'] as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final i = v['video'] ?? v;
      final vk = i['video_id'] ?? i['viewkey'] ?? '';
      if (vk.toString().isEmpty) continue;
      final thumbs = (i['thumbs'] as List?) ?? [];
      final thumb = thumbs.isNotEmpty
          ? (thumbs[0]['src'] ?? thumbs[0]['url'] ?? '')
          : (i['default_thumb'] ?? '');
      if (thumb.toString().isEmpty) continue;
      items.add(VideoItem(
        title: _clean(i['title']),
        thumb: thumb.toString(),
        videoUrl: 'https://www.pornhub.com/view_video.php?viewkey=$vk',
        duration: '${i['duration'] ?? ''}',
        views: _fmtViews(i['views']),
        source: 'pornhub',
      ));
    }
    return items;
  } catch (_) { return []; }
}

Future<List<VideoItem>> fetchRedtube() async {
  try {
    final term = Uri.encodeComponent(_pick(_terms));
    final d = await _proxyJson(
      'https://api.redtube.com/?data=redtube.Videos.searchVideos&output=json&thumbsize=medium&count=20&search=$term&ordering=newestdate&page=${_rnd(30)}',
    );
    final videos = (d?['videos'] as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final i = v['video'] ?? v;
      final vid = i['video_id'] ?? '';
      if (vid.toString().isEmpty) continue;
      final thumb = i['thumb'] ?? i['default_thumb'] ?? '';
      if (thumb.toString().isEmpty) continue;
      items.add(VideoItem(
        title: _clean(i['title']),
        thumb: thumb.toString(),
        videoUrl: 'https://www.redtube.com/$vid',
        duration: '${i['duration'] ?? ''}',
        views: _fmtViews(i['views']),
        source: 'redtube',
      ));
    }
    return items;
  } catch (_) { return []; }
}

Future<List<VideoItem>> fetchYouporn() async {
  try {
    final d = await _proxyJson(
      'https://www.youporn.com/api/video/search/?is_top=1&page=${_rnd(15)}&per_page=20',
    );
    final videos = ((d?['videos'] ?? d?['data']) as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final id = (v['id'] ?? v['video_id'] ?? '').toString();
      if (id.isEmpty || id == '0') continue;
      final thumb = v['thumb'] ?? v['default_thumb'] ?? '';
      if (thumb.toString().isEmpty) continue;
      items.add(VideoItem(
        title: _clean(v['title']),
        thumb: thumb.toString(),
        videoUrl: 'https://www.youporn.com/watch/$id/',
        duration: '${v['duration'] ?? ''}',
        views: _fmtViews(v['views']),
        source: 'youporn',
      ));
    }
    return items;
  } catch (_) { return []; }
}

Future<List<VideoItem>> fetchBeeg() async {
  try {
    final d = await _tryJson(
      'https://beeg.com/api/v6/index/0?gap=0&start=${_rnd(10) * 20}&lng=en',
    );
    final videos = (d?['videos'] as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final id = v['id'] ?? v['video_id'];
      if (id == null) continue;
      final thumbs = (v['thumbs'] as List?) ?? [];
      final thumb = thumbs.isNotEmpty ? (thumbs[0]['src'] ?? '') : (v['image'] ?? v['thumb'] ?? '');
      if (thumb.toString().isEmpty) continue;
      items.add(VideoItem(
        title: _clean(v['title']),
        thumb: thumb.toString(),
        videoUrl: 'https://beeg.com/$id',
        duration: '${v['duration'] ?? ''}',
        views: _fmtViews(v['views']),
        source: 'beeg',
      ));
    }
    return items;
  } catch (_) { return []; }
}

Future<List<VideoItem>> fetchTube8() async {
  try {
    final d = await _proxyJson(
      'https://www.tube8.com/api/v0/video/search?search_query=&page=${_rnd(20)}&format=json',
    );
    final videos = (d?['videos'] as List?) ?? [];
    final items = <VideoItem>[];
    for (final v in videos) {
      final id = v['video_id'] ?? v['id'];
      if (id == null) continue;
      final thumb = v['thumb'] ?? v['default_thumb'] ?? '';
      if (thumb.toString().isEmpty) continue;
      items.add(VideoItem(
        title: _clean(v['title']),
        thumb: thumb.toString(),
        videoUrl: 'https://www.tube8.com/video/$id',
        duration: '${v['duration'] ?? ''}',
        views: _fmtViews(v['views']),
        source: 'tube8',
      ));
    }
    return items;
  } catch (_) { return []; }
}

// ─── FETCHERS SCRAPE ─────────────────────────────────────────────────────────

Future<List<VideoItem>> fetchXhamster() async {
  final urls = ['https://xhamster.com/newest', 'https://xhamster.com/videos'];
  for (final url in urls) {
    try {
      final html = await _tryText(url);
      if (html == null) continue;

      final mInit = RegExp(
        r'window\.__initials__\s*=\s*(\{[\s\S]{200,}?\})\s*;?\s*<\/script>',
      ).firstMatch(html);
      if (mInit != null) {
        try {
          final d = jsonDecode(mInit.group(1)!);
          final list = (d['videoList']?['models'] ?? d['videos'] ?? []) as List;
          final items = <VideoItem>[];
          for (final v in list.take(20)) {
            final thumb = v['thumbURL'] ?? v['thumbUrl'] ?? v['thumbnail'] ?? '';
            final title = _clean(v['title']);
            var videoUrl = v['pageURL'] ?? v['url'] ?? '';
            if (thumb.isEmpty || title.isEmpty || videoUrl.isEmpty) continue;
            if (!videoUrl.startsWith('http')) videoUrl = 'https://xhamster.com$videoUrl';
            items.add(VideoItem(
              title: title, thumb: thumb, videoUrl: videoUrl,
              duration: '${v['duration'] ?? ''}',
              views: _fmtViews(v['views'] ?? 0),
              source: 'xhamster',
            ));
          }
          if (items.length >= 2) return items;
        } catch (_) {}
      }

      final doc = htmlParser.parse(html);
      final items = <VideoItem>[];
      for (final a in doc.querySelectorAll('a.video-thumb, a[class*="video-thumb"]')) {
        try {
          final href = a.attributes['href'] ?? '';
          if (!href.contains('/videos/')) continue;
          final videoUrl = href.startsWith('http') ? href : 'https://xhamster.com$href';
          final img = a.querySelector('img');
          final thumb = img?.attributes['data-src'] ?? img?.attributes['src'] ?? '';
          if (thumb.isEmpty || thumb.contains('data:')) continue;
          final title = _clean(
            a.attributes['title'] ??
            a.querySelector('[class*="title"]')?.text ??
            '',
          );
          if (title.isEmpty) continue;
          final dur = a.querySelector('[class*="duration"]')?.text.trim() ?? '';
          items.add(VideoItem(
            title: title, thumb: thumb, videoUrl: videoUrl,
            duration: dur, views: '', source: 'xhamster',
          ));
        } catch (_) {}
      }
      if (items.length >= 2) return items;
    } catch (_) {}
  }
  return [];
}

Future<List<VideoItem>> fetchXvideos() async {
  final urls = [
    'https://www.xvideos.com/',
    'https://www.xvideos.com/new/${_rnd(15)}',
  ];
  for (final url in urls) {
    try {
      final html = await _tryText(url);
      if (html == null) continue;
      final items = <VideoItem>[];
      final re = RegExp(
        r'"id"\s*:\s*(\d+)[^}]{0,300}?"tf"\s*:\s*"([^"]+)"[^}]{0,300}?"t"\s*:\s*"([^"]+)"',
      );
      for (final m in re.allMatches(html)) {
        if (items.length >= 20) break;
        final id = m.group(1)!;
        final tf = m.group(2)!;
        final t = m.group(3)!;
        final thumb = tf.startsWith('http') ? tf : 'https://img-l3.xvideos-cdn.com/$tf';
        items.add(VideoItem(
          title: _clean(t), thumb: thumb,
          videoUrl: 'https://www.xvideos.com/video$id/',
          duration: '', views: '', source: 'xvideos',
        ));
      }
      if (items.length >= 2) return items;

      final fb = _domScrape(html, 'xvideos', 'https://www.xvideos.com', '.thumb-block');
      if (fb.length >= 2) return fb;
    } catch (_) {}
  }
  return [];
}

Future<List<VideoItem>> fetchSpankbang() async {
  return _scrapeAny(
    ['https://spankbang.com/trending/', 'https://spankbang.com/new/'],
    'spankbang', 'https://spankbang.com',
    itemSel: '.video-item,.stream_item',
  );
}

Future<List<VideoItem>> fetchGotporn() async {
  final urls = ['https://www.gotporn.com/videos/', 'https://www.gotporn.com/'];
  for (final url in urls) {
    try {
      final html = await _tryText(url);
      if (html == null) continue;
      final doc = htmlParser.parse(html);
      final items = <VideoItem>[];
      for (final a in doc.querySelectorAll('a[href*="/video/"]')) {
        try {
          final href = a.attributes['href'] ?? '';
          if (href.isEmpty || href.contains('/out/') || href.contains('/go/')) continue;
          final videoUrl = href.startsWith('http') ? href : 'https://www.gotporn.com$href';
          dom.Element? card = a.parent;
          while (card != null && card.localName != 'li' && card.localName != 'article') {
            card = card.parent;
          }
          card ??= a.parent;
          final img = card?.querySelector('img');
          final thumb = img?.attributes['data-src'] ?? img?.attributes['src'] ?? '';
          if (thumb.isEmpty || thumb.contains('data:') || !thumb.startsWith('http')) continue;
          final title = _clean(
            a.attributes['title'] ??
            card?.querySelector('strong')?.text ??
            card?.querySelector('.title')?.text ??
            card?.querySelector('h3')?.text ??
            a.text,
          );
          if (title.isEmpty || title.length < 3) continue;
          items.add(VideoItem(
            title: title, thumb: thumb, videoUrl: videoUrl,
            duration: '', views: '', source: 'gotporn',
          ));
        } catch (_) {}
      }
      if (items.length >= 2) return items;
    } catch (_) {}
  }
  return [];
}

// ─── SITES GENERICOS ─────────────────────────────────────────────────────────

List<(String, String, List<String>)> get genericSites => [
  ('bravotube',  'https://www.bravotube.net',  ['https://www.bravotube.net/', 'https://www.bravotube.net/newest/']),
  ('drtuber',    'https://www.drtuber.com',    ['https://www.drtuber.com/', 'https://www.drtuber.com/videos/newest']),
  ('txxx',       'https://www.txxx.com',       ['https://www.txxx.com/', 'https://www.txxx.com/videos/']),
  ('porndig',    'https://www.porndig.com',    ['https://www.porndig.com/', 'https://www.porndig.com/videos/']),
  ('tnaflix',    'https://www.tnaflix.com',    ['https://www.tnaflix.com/', 'https://www.tnaflix.com/videos/']),
  ('empflix',    'https://www.empflix.com',    ['https://www.empflix.com/', 'https://www.empflix.com/videos/']),
  ('porntrex',   'https://www.porntrex.com',   ['https://www.porntrex.com/', 'https://www.porntrex.com/most-popular/${_rnd(5)}/']),
  ('hclips',     'https://hclips.com',         ['https://hclips.com/', 'https://hclips.com/videos/newest/']),
  ('tubedupe',   'https://www.tubedupe.com',   ['https://www.tubedupe.com/', 'https://www.tubedupe.com/newest/']),
  ('sexvid',     'https://sexvid.xxx',         ['https://sexvid.xxx/', 'https://sexvid.xxx/newest/']),
  ('nuvid',      'https://www.nuvid.com',      ['https://www.nuvid.com/videos/', 'https://www.nuvid.com/videos/newest/${_rnd(10)}']),
  ('sunporno',   'https://www.sunporno.com',   ['https://www.sunporno.com/videos/', 'https://www.sunporno.com/videos/newest/${_rnd(10)}']),
  ('pornone',    'https://pornone.com',        ['https://pornone.com/', 'https://pornone.com/videos/']),
  ('slutload',   'https://www.slutload.com',   ['https://www.slutload.com/', 'https://www.slutload.com/new/']),
  ('iceporn',    'https://www.iceporn.com',    ['https://www.iceporn.com/', 'https://www.iceporn.com/videos/newest/']),
  ('vjav',       'https://vjav.com',           ['https://vjav.com/', 'https://vjav.com/videos/newest/']),
  ('jizzbunker', 'https://jizzbunker.com',     ['https://jizzbunker.com/', 'https://jizzbunker.com/new-videos/']),
  ('yeptube',    'https://www.yeptube.com',    ['https://www.yeptube.com/', 'https://www.yeptube.com/newest/']),
  ('cliphunter', 'https://www.cliphunter.com', ['https://www.cliphunter.com/', 'https://www.cliphunter.com/?page=${_rnd(20)}']),
];

// ─── FETCH ALL (streaming) ───────────────────────────────────────────────────

Stream<List<VideoItem>> fetchAllStream() async* {
  final sites = genericSites;
  final futures = <Future<List<VideoItem>>>[
    fetchEporner(),
    fetchPornhub(),
    fetchRedtube(),
    fetchYouporn(),
    fetchBeeg(),
    fetchTube8(),
    fetchXhamster(),
    fetchXvideos(),
    fetchSpankbang(),
    fetchGotporn(),
    ...sites.map((s) => _scrapeAny(s.$3, s.$1, s.$2)),
  ];

  final controller = StreamController<List<VideoItem>>();

  var pending = futures.length;
  for (final f in futures) {
    f.then((items) {
      if (items.isNotEmpty) controller.add(_shuffle(items));
      pending--;
      if (pending == 0) controller.close();
    }).catchError((_) {
      pending--;
      if (pending == 0) controller.close();
    });
  }

  yield* controller.stream;
}
