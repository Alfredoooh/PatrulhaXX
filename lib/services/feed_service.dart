import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class FeedItem {
  final String id;
  final String title;
  final String thumb;
  // url = URL da PÁGINA (para exibir título, info, etc.)
  final String url;
  // embedUrl = URL do EMBED PURO — só o player, sem o site
  // É ESTE que vai para o InAppWebView
  final String embedUrl;
  final String duration;
  final String views;
  final String source;
  final String type;

  const FeedItem({
    required this.id,
    required this.title,
    required this.thumb,
    required this.url,
    String? embedUrl,
    this.duration = '',
    this.views    = '',
    required this.source,
    this.type = 'video',
  }) : embedUrl = embedUrl ?? url;

  /// Converte uma URL de página para URL de embed puro.
  /// Cada fonte tem a sua lógica de embed.
  static String toEmbed(String pageUrl) {
    if (pageUrl.isEmpty) return pageUrl;

    final uri = Uri.tryParse(pageUrl);
    if (uri == null) return pageUrl;
    final host = uri.host.toLowerCase();
    final path = uri.path;

    // ── RedTube ───────────────────────────────────────────────────────────────
    // Página:  https://www.redtube.com/123456
    // Embed:   https://embed.redtube.com/?id=123456
    if (host.contains('redtube')) {
      // Extrai o ID numérico do path
      final match = RegExp(r'/(\d+)').firstMatch(path);
      if (match != null) {
        return 'https://embed.redtube.com/?bgcolor=000000&id=${match.group(1)}';
      }
    }

    // ── Eporner ───────────────────────────────────────────────────────────────
    // Página:  https://www.eporner.com/video-ABCDEF/titulo
    // Embed:   https://www.eporner.com/embed/ABCDEF/
    if (host.contains('eporner')) {
      final match = RegExp(r'/video-([A-Za-z0-9]+)').firstMatch(path);
      if (match != null) {
        return 'https://www.eporner.com/embed/${match.group(1)}/';
      }
    }

    // ── PornHub ───────────────────────────────────────────────────────────────
    // Página:  https://www.pornhub.com/view_video.php?viewkey=ph5e3c...
    // Embed:   https://www.pornhub.com/embed/ph5e3c...
    if (host.contains('pornhub')) {
      final viewkey = uri.queryParameters['viewkey'] ?? '';
      if (viewkey.isNotEmpty) {
        return 'https://www.pornhub.com/embed/$viewkey';
      }
      // Algumas URLs têm o viewkey no path
      final match = RegExp(r'/embed/([A-Za-z0-9]+)').firstMatch(path);
      if (match != null) return pageUrl; // já é embed
    }

    // ── XVideos ───────────────────────────────────────────────────────────────
    // Página:  https://www.xvideos.com/video12345678/titulo
    // Embed:   https://www.xvideos.com/embedframe/12345678
    if (host.contains('xvideos')) {
      final match = RegExp(r'/video(\d+)').firstMatch(path);
      if (match != null) {
        return 'https://www.xvideos.com/embedframe/${match.group(1)}';
      }
    }

    // ── xHamster ─────────────────────────────────────────────────────────────
    // Página:  https://xhamster.com/videos/titulo-12345678
    // Embed:   https://xhamster.com/xembed.php?video=12345678
    if (host.contains('xhamster')) {
      final match = RegExp(r'-(\d+)$').firstMatch(path);
      if (match != null) {
        return 'https://xhamster.com/xembed.php?video=${match.group(1)}';
      }
    }

    // ── YouPorn ───────────────────────────────────────────────────────────────
    // Página:  https://www.youporn.com/watch/12345678/titulo/
    // Embed:   https://www.youporn.com/embed/12345678/
    if (host.contains('youporn')) {
      final match = RegExp(r'/watch/(\d+)').firstMatch(path);
      if (match != null) {
        return 'https://www.youporn.com/embed/${match.group(1)}/';
      }
    }

    // ── SpankBang ─────────────────────────────────────────────────────────────
    // Página:  https://spankbang.com/ABCDE/video/titulo
    // Embed:   https://spankbang.com/ABCDE/embed/
    if (host.contains('spankbang')) {
      final match = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(path);
      if (match != null && match.group(1) != 'rss') {
        return 'https://spankbang.com/${match.group(1)}/embed/';
      }
    }

    // ── BravoTube ─────────────────────────────────────────────────────────────
    // Página:  https://www.bravotube.net/video/titulo-123456.html
    // Embed:   https://www.bravotube.net/embed/123456/
    if (host.contains('bravotube')) {
      final match = RegExp(r'-(\d+)\.html').firstMatch(path);
      if (match != null) {
        return 'https://www.bravotube.net/embed/${match.group(1)}/';
      }
    }

    // ── DrTuber ───────────────────────────────────────────────────────────────
    // Página:  https://www.drtuber.com/video/123456/titulo
    // Embed:   https://www.drtuber.com/embed/123456
    if (host.contains('drtuber')) {
      final match = RegExp(r'/video/(\d+)').firstMatch(path);
      if (match != null) {
        return 'https://www.drtuber.com/embed/${match.group(1)}';
      }
    }

    // ── TXXX ──────────────────────────────────────────────────────────────────
    // Página:  https://www.txxx.com/videos/titulo-123456/
    // Embed:   https://www.txxx.com/embed/123456/
    if (host.contains('txxx')) {
      final match = RegExp(r'-(\d+)/?$').firstMatch(path);
      if (match != null) {
        return 'https://www.txxx.com/embed/${match.group(1)}/';
      }
    }

    // ── GotPorn ───────────────────────────────────────────────────────────────
    // Página:  https://www.gotporn.com/titulo/video-123456
    // Embed:   https://www.gotporn.com/video/embed/123456
    if (host.contains('gotporn')) {
      final match = RegExp(r'/video-(\d+)').firstMatch(path);
      if (match != null) {
        return 'https://www.gotporn.com/video/embed/${match.group(1)}';
      }
    }

    // ── PornDig ───────────────────────────────────────────────────────────────
    // Página:  https://www.porndig.com/videos/titulo-123456.html
    // Embed:   https://www.porndig.com/embed/123456
    if (host.contains('porndig')) {
      final match = RegExp(r'-(\d+)\.html').firstMatch(path);
      if (match != null) {
        return 'https://www.porndig.com/embed/${match.group(1)}';
      }
    }

    // Fallback — devolve a URL original se não souber converter
    return pageUrl;
  }
}

class FeedService {
  static final FeedService instance = FeedService._();
  FeedService._();

  List<FeedItem> _items  = [];
  bool           _loaded = false;
  List<FeedItem> get items => _items;

  static const _ua =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static const _terms = [
    '', 'amateur', 'teen', 'milf', 'blonde', 'brunette', 'asian',
    'latina', 'hot', 'sexy', 'beautiful', 'young', 'wild', 'homemade',
    'big', 'lesbian', 'college', 'mature', 'ebony', 'babe',
  ];

  static String _rndTerm() => _terms[Random().nextInt(_terms.length)];
  static int    _rndPage(int max) => Random().nextInt(max) + 1;

  Future<List<FeedItem>> load({bool force = false}) async {
    if (_loaded && !force) return _items;

    final results = await Future.wait([
      _fetchRedTube(),
      _fetchEporner(),
      _fetchPornHub(),
      _fetchXVideos(),
      _fetchXHamster(),
      _fetchYouPorn(),
      _fetchSpankBang(),
      _fetchBravoTube(),
      _fetchDrTuber(),
      _fetchTXXX(),
      _fetchGotPorn(),
      _fetchPornDig(),
      _fetchBlogs(),
    ]);

    final lists = results.where((l) => l.isNotEmpty).toList();
    final all   = <FeedItem>[];
    if (lists.isNotEmpty) {
      final maxLen = lists.map((l) => l.length).reduce((a, b) => a > b ? a : b);
      for (int i = 0; i < maxLen; i++) {
        for (final list in lists) {
          if (i < list.length) all.add(list[i]);
        }
      }
    }
    all
      ..removeWhere((f) => f.url.isEmpty)
      ..shuffle(Random(DateTime.now().millisecondsSinceEpoch));

    _items  = all;
    _loaded = all.isNotEmpty;
    return _items;
  }

  List<FeedItem> search(String query) {
    if (query.trim().isEmpty) return _items;
    final q = query.toLowerCase();
    return _items
        .where((i) =>
            i.title.toLowerCase().contains(q) ||
            i.source.toLowerCase().contains(q))
        .toList();
  }

  // ── RedTube ─────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchRedTube() async {
    final orders = ['newest', 'mostviewed', 'hottest', 'rating'];
    final items  = <FeedItem>[];
    for (final order in orders) {
      try {
        final term = _rndTerm();
        final res  = await http.get(
          Uri.parse('https://api.redtube.com/?data=redtube.Videos.searchVideos'
              '&output=json&search=${Uri.encodeComponent(term)}'
              '&thumbsize=big&count=30&ordering=$order'
              '&page=${_rndPage(20)}'),
          headers: {'User-Agent': _ua},
        ).timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final json   = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = json['videos'] as List? ?? [];
        for (final v in videos) {
          final vm    = (v as Map)['video'] as Map<String, dynamic>? ?? {};
          final thumb = vm['thumb'] as String? ?? '';
          final id    = vm['video_id']?.toString() ?? '';
          if (thumb.isEmpty || id.isEmpty) continue;
          // Embed directo — sem página do site
          final embed = 'https://embed.redtube.com/?bgcolor=000000&id=$id';
          items.add(FeedItem(
            id:       'rt_$id',
            title:    vm['title']    as String? ?? 'Vídeo',
            thumb:    thumb,
            url:      'https://www.redtube.com/$id',
            embedUrl: embed,
            duration: vm['duration'] as String? ?? '',
            views:    vm['views']    as String? ?? '',
            source:   'RedTube',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── Eporner ─────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchEporner() async {
    final orders = ['latest', 'top-weekly', 'top-monthly'];
    final items  = <FeedItem>[];
    for (final order in orders) {
      try {
        final term = _rndTerm();
        final res  = await http.get(
          Uri.parse('https://www.eporner.com/api/v2/video/search/'
              '?per_page=30&page=${_rndPage(40)}&order=$order&format=json'
              '&thumbsize=big&query=${Uri.encodeComponent(term)}'),
          headers: {'User-Agent': _ua},
        ).timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final json   = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = json['videos'] as List? ?? [];
        for (final v in videos) {
          final vm        = v as Map<String, dynamic>;
          final id        = vm['id'] as String? ?? '';
          if (id.isEmpty) continue;
          final thumbList = vm['thumbs'] as List?;
          final thumb = thumbList != null && thumbList.isNotEmpty
              ? (thumbList.last['src'] as String? ?? '')
              : (vm['thumb'] as String? ?? '');
          if (thumb.isEmpty) continue;
          // Embed directo — sem página do site
          final embed = 'https://www.eporner.com/embed/$id/';
          items.add(FeedItem(
            id:       'ep_$id',
            title:    vm['title']      as String? ?? 'Vídeo',
            thumb:    thumb,
            url:      'https://www.eporner.com/video-$id/',
            embedUrl: embed,
            duration: vm['length_min'] as String? ?? '',
            views:    vm['views']      as String? ?? '',
            source:   'Eporner',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── PornHub ─────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchPornHub() async {
    final orders = ['newest', 'mostviewed', 'rating', 'featured'];
    final items  = <FeedItem>[];
    for (final order in orders.take(2)) {
      try {
        final term = _rndTerm();
        final res  = await http.get(
          Uri.parse('https://www.pornhub.com/webmasters/search'
              '?search=${Uri.encodeComponent(term)}'
              '&ordering=$order&page=${_rndPage(30)}'
              '&thumbsize=medium&format=json'),
          headers: {'User-Agent': _ua},
        ).timeout(const Duration(seconds: 14));
        if (res.statusCode != 200) continue;
        final data   = jsonDecode(res.body) as Map<String, dynamic>;
        final videos = data['videos'] as List? ?? data['video'] as List? ?? [];
        for (final v in videos) {
          final vm      = v as Map<String, dynamic>;
          final viewkey = vm['video_id'] as String? ?? vm['viewkey'] as String? ?? '';
          if (viewkey.isEmpty) continue;
          String thumb = '';
          final thumbs = vm['thumbs'] as List?;
          if (thumbs != null && thumbs.isNotEmpty) {
            thumb = (thumbs.first['src'] ?? thumbs.first['url'] ?? '') as String;
          }
          if (thumb.isEmpty) thumb = vm['default_thumb'] as String? ?? '';
          if (thumb.isEmpty) continue;
          // Embed directo — player PH sem página
          final embed = 'https://www.pornhub.com/embed/$viewkey';
          items.add(FeedItem(
            id:       'ph_$viewkey',
            title:    vm['title']    as String? ?? 'Vídeo',
            thumb:    thumb,
            url:      'https://www.pornhub.com/view_video.php?viewkey=$viewkey',
            embedUrl: embed,
            duration: vm['duration'] as String? ?? '',
            views:    vm['views']    as String? ?? '',
            source:   'PornHub',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── XVideos ─────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchXVideos() async {
    final endpoints = [
      'https://www.xvideos.com/feeds/rss-new/0',
      'https://www.xvideos.com/feeds/rss-most-viewed-alltime/0',
      'https://www.xvideos.com/feeds/rss-new/straight/0',
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
          // Extrai ID do path /videoXXXXXXXX/
          final match = RegExp(r'/video(\d+)').firstMatch(link);
          final embed = match != null
              ? 'https://www.xvideos.com/embedframe/${match.group(1)}'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'xv_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'XVideos',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── xHamster ────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchXHamster() async {
    final items = <FeedItem>[];
    try {
      final term = _rndTerm();
      final res  = await http.get(
        Uri.parse('https://xhamster.com/api/front/search'
            '?q=${Uri.encodeComponent(term)}'
            '&page=${_rndPage(20)}&sectionName=video'),
        headers: {
          'User-Agent': _ua,
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
        },
      ).timeout(const Duration(seconds: 14));
      if (res.statusCode != 200) return items;
      final data   = jsonDecode(res.body) as Map<String, dynamic>;
      final models = (data['data']?['videos']?['models'] as List?) ?? [];
      for (final v in models) {
        final vm    = v as Map<String, dynamic>;
        final id    = (vm['id'] ?? '').toString();
        final thumb = vm['thumbUrl'] as String? ?? vm['thumb'] as String? ?? '';
        final url   = vm['pageURL'] as String? ?? vm['url'] as String? ?? '';
        if (id.isEmpty || thumb.isEmpty || url.isEmpty) continue;
        // Embed xHamster
        final embed = 'https://xhamster.com/xembed.php?video=$id';
        items.add(FeedItem(
          id:       'xh_$id',
          title:    vm['title'] as String? ?? 'Vídeo',
          thumb:    thumb,
          url:      url,
          embedUrl: embed,
          duration: vm['duration']?.toString() ?? '',
          views:    _fmtViews(vm['views']),
          source:   'xHamster',
        ));
      }
    } catch (_) {}
    return items;
  }

  // ── YouPorn ─────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchYouPorn() async {
    final items = <FeedItem>[];
    try {
      final res = await http.get(
        Uri.parse('https://www.youporn.com/api/video/search/'
            '?is_top=1&page=${_rndPage(15)}&per_page=30'),
        headers: {'User-Agent': _ua, 'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return items;
      final data   = jsonDecode(res.body);
      final videos = (data['videos'] ?? data['data'] ?? data) as List? ?? [];
      for (final v in videos) {
        final vm    = v as Map<String, dynamic>;
        final id    = (vm['id'] ?? vm['video_id'] ?? '').toString();
        final thumb = vm['thumb'] as String? ?? vm['default_thumb'] as String? ?? '';
        if (id.isEmpty || id == '0' || thumb.isEmpty) continue;
        final embed = 'https://www.youporn.com/embed/$id/';
        items.add(FeedItem(
          id:       'yp_$id',
          title:    vm['title'] as String? ?? 'Vídeo',
          thumb:    thumb,
          url:      'https://www.youporn.com/watch/$id/',
          embedUrl: embed,
          duration: vm['duration'] as String? ?? '',
          views:    _fmtViews(vm['views']),
          source:   'YouPorn',
        ));
      }
    } catch (_) {}
    return items;
  }

  // ── SpankBang ────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchSpankBang() async {
    final endpoints = [
      'https://spankbang.com/rss/',
      'https://spankbang.com/rss/trending/',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
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
          // Extrai slug do path /SLUG/video/titulo
          final match = RegExp(r'^/([A-Za-z0-9]+)/').firstMatch(Uri.parse(link).path);
          final embed = match != null
              ? 'https://spankbang.com/${match.group(1)}/embed/'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'sb_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'SpankBang',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── BravoTube ────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchBravoTube() async {
    final endpoints = [
      'https://www.bravotube.net/rss/new/',
      'https://www.bravotube.net/rss/popular/',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
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
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          final embed = match != null
              ? 'https://www.bravotube.net/embed/${match.group(1)}/'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'bt_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'BravoTube',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── DrTuber ──────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchDrTuber() async {
    final endpoints = [
      'https://www.drtuber.com/rss/latest',
      'https://www.drtuber.com/rss/popular',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
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
          final match = RegExp(r'/video/(\d+)').firstMatch(link);
          final embed = match != null
              ? 'https://www.drtuber.com/embed/${match.group(1)}'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'dt_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'DrTuber',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── TXXX ─────────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchTXXX() async {
    final endpoints = [
      'https://www.txxx.com/rss/new/',
      'https://www.txxx.com/rss/popular/',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:content').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
          if (link.isEmpty) continue;
          final match = RegExp(r'-(\d+)/?$').firstMatch(Uri.parse(link).path);
          final embed = match != null
              ? 'https://www.txxx.com/embed/${match.group(1)}/'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'tx_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'TXXX',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── GotPorn ──────────────────────────────────────────────────────────────────
  Future<List<FeedItem>> _fetchGotPorn() async {
    final endpoints = [
      'https://www.gotporn.com/rss/latest',
      'https://www.gotporn.com/rss/popular',
    ];
    final items = <FeedItem>[];
    for (final url in endpoints) {
      try {
        final res = await http.get(Uri.parse(url),
            headers: {'User-Agent': _ua})
            .timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) continue;
        final doc = XmlDocument.parse(res.body);
        for (final item in doc.findAllElements('item')) {
          final link  = _xml(item, 'link');
          final title = _xml(item, 'title');
          final thumb = _firstOf([
            item.findElements('media:thumbnail').firstOrNull?.getAttribute('url'),
            item.findElements('enclosure').firstOrNull?.getAttribute('url'),
          ]);
          if (link.isEmpty) continue;
          final match = RegExp(r'/video-(\d+)').firstMatch(link);
          final embed = match != null
              ? 'https://www.gotporn.com/video/embed/${match.group(1)}'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'gp_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'GotPorn',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── PornDig ──────────────────────────────────────────────────────────────────
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
            .timeout(const Duration(seconds: 12));
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
          final match = RegExp(r'-(\d+)\.html').firstMatch(link);
          final embed = match != null
              ? 'https://www.porndig.com/embed/${match.group(1)}'
              : FeedItem.toEmbed(link);
          items.add(FeedItem(
            id:       'pd_${link.hashCode}',
            title:    title.isEmpty ? 'Vídeo' : title,
            thumb:    thumb,
            url:      link,
            embedUrl: embed,
            source:   'PornDig',
          ));
        }
        if (items.isNotEmpty) break;
      } catch (_) {}
    }
    return items;
  }

  // ── Blogs ────────────────────────────────────────────────────────────────────
  // Artigos não têm embed — usam a URL de página (tipo='article')
  Future<List<FeedItem>> _fetchBlogs() async {
    final sources = <String, String>{
      'https://ainews.xxx/feed/':              'AINews.xxx',
      'https://rogreviews.com/feed':           'RogReviews',
      'https://theporndude.com/blog/feed':     'ThePornDude',
      'https://therealpornwikileaks.com/feed': 'TRPWL',
      'https://lukeisback.com/feed':           'LukeIsBack',
      'https://adultfyi.com/feed':             'AdultFYI',
      'https://mikesouth.com/feed':            'MikeSouth',
      'https://ynot.com/feed':                 'YNotMasters',
      'https://xbiz.com/rss/all.xml':          'XBIZ',
      'https://queermenow.net/blog/feed':      'QueerMeNow',
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
            thumb:  thumb,
            url:    link,
            source: entry.value,
            type:   'article',
          ));
        }
      } catch (_) {}
    }
    return items;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  String _firstOf(List<String?> values) {
    for (final v in values) { if (v != null && v.isNotEmpty) return v; }
    return '';
  }

  String _xml(XmlElement el, String tag) {
    try { return el.findElements(tag).first.innerText.trim(); }
    catch (_) { return ''; }
  }

  static String _fmtViews(dynamic v) {
    final n = int.tryParse(v?.toString() ?? '') ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(0)}k';
    return n > 0 ? '$n' : '';
  }
}
