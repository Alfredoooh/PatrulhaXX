import 'dart:convert';
import 'package:http/http.dart' as http;

// ─────────────────────────────────────────────────────────────────────────────
// FeedPhoto
// ─────────────────────────────────────────────────────────────────────────────
class FeedPhoto {
  final String id;
  final String url;
  final String thumb;
  final String title;
  final String source;
  final String sourceLabel;
  final int likes;

  const FeedPhoto({
    required this.id,
    required this.url,
    required this.thumb,
    required this.title,
    required this.source,
    required this.sourceLabel,
    this.likes = 0,
  });

  static FeedPhoto? fromPornhub(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['photo_id'] ?? '').toString();
    if (id.isEmpty) return null;
    String url = j['thumb_url'] as String?
        ?? j['url'] as String?
        ?? j['thumbnail'] as String? ?? '';
    if (url.isNotEmpty && url.contains('_160')) {
      url = url.replaceAll('_160', '_720');
    }
    if (url.isEmpty) return null;
    return FeedPhoto(
      id: 'ph_$id', url: url, thumb: url,
      title: j['title'] as String? ?? '',
      source: 'https://www.pornhub.com/favicon.ico',
      sourceLabel: 'Pornhub',
      likes: int.tryParse((j['rating'] ?? j['likes'] ?? '0').toString()) ?? 0,
    );
  }

  static FeedPhoto? fromRedtube(Map<String, dynamic> j) {
    final id = (j['photo_id'] ?? j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final url = j['thumb_url'] as String? ?? j['url'] as String? ?? '';
    if (url.isEmpty) return null;
    return FeedPhoto(
      id: 'rt_$id', url: url, thumb: url,
      title: j['title'] as String? ?? '',
      source: 'https://www.redtube.com/favicon.ico',
      sourceLabel: 'RedTube',
      likes: int.tryParse((j['rating'] ?? '0').toString()) ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PhotoFetcher
// ─────────────────────────────────────────────────────────────────────────────
class PhotoFetcher {
  static const _ua = 'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  static Future<List<FeedPhoto>> fetchAll(int page) async {
    final results = await Future.wait([
      _fetchPornhub(page),
      _fetchRedtube(page),
    ]);
    final all = <FeedPhoto>[];
    for (final list in results) all.addAll(list);
    all.shuffle();
    return all;
  }

  static Future<List<FeedPhoto>> _fetchPornhub(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://www.pornhub.com/webmasters/photos?format=json&page=${page.clamp(1,30)}&thumbsize=medium'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final photos = data['photos'] as List? ?? data['photo'] as List? ?? [];
      return photos
          .map((p) => FeedPhoto.fromPornhub(p as Map<String, dynamic>))
          .whereType<FeedPhoto>()
          .toList();
    } catch (_) { return []; }
  }

  static Future<List<FeedPhoto>> _fetchRedtube(int page) async {
    try {
      final r = await http.get(
        Uri.parse('https://api.redtube.com/?data=redtube.Photos.searchPhotos&output=json&thumbsize=medium&page=${page.clamp(1,20)}&count=20'),
        headers: {'User-Agent': _ua},
      ).timeout(const Duration(seconds: 12));
      if (r.statusCode != 200) return [];
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      final photos = data['photos'] as List? ?? [];
      return photos.map((p) {
        final pm = (p as Map)['photo'] as Map<String, dynamic>? ?? p as Map<String, dynamic>;
        return FeedPhoto.fromRedtube(pm);
      }).whereType<FeedPhoto>().toList();
    } catch (_) { return []; }
  }
}
