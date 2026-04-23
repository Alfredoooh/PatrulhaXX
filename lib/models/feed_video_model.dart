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
  final String pageUrl; // ← URL real da página do vídeo
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

  Color get sourceColor => const Color(0xFF222222);

  // ── Parsers de API ──────────────────────────────────────────────────────────

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
    final url = 'https://www.eporner.com/video/$id/';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.eporner.com/embed/$id/',
      pageUrl: url,
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
    final url = 'https://www.pornhub.com/view_video.php?viewkey=$viewkey';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.pornhub.com/embed/$viewkey',
      pageUrl: url,
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
    final url = 'https://www.redtube.com/$vid';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://embed.redtube.com/?id=$vid',
      pageUrl: url,
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
    final url = 'https://www.youporn.com/watch/$id';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.youporn.com/embed/$id/',
      pageUrl: url,
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.youporn,
      publishedAt: _parseDate(j['publish_date'] ?? j['date']),
    );
  }

  static FeedVideo? fromXvideos(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty || id == '0') return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ?? j['default_thumb'] as String? ?? '';
    if (thumb.isEmpty) return null;
    final url = 'https://www.xvideos.com/video$id';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://www.xvideos.com/embedframe/$id',
      pageUrl: url,
      duration: j['duration'] as String? ?? '',
      views: _fmtViews(j['views'] ?? j['nb_views']),
      source: VideoSource.xvideos,
      publishedAt: _parseDate(j['added'] ?? j['date']),
    );
  }

  static FeedVideo? fromXhamster(Map<String, dynamic> j) {
    final id = (j['id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumbUrl'] as String? ?? j['thumb'] as String? ?? j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    final url = 'https://xhamster.com/videos/$id';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://xhamster.com/xembed.php?video=$id',
      pageUrl: url,
      duration: j['duration']?.toString() ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.xhamster,
      publishedAt: _parseDate(j['created'] ?? j['added'] ?? j['date']),
    );
  }

  static FeedVideo? fromSpankbang(Map<String, dynamic> j) {
    final id = (j['id'] ?? j['video_id'] ?? '').toString();
    if (id.isEmpty) return null;
    final thumb = j['thumb'] as String? ?? j['thumbnail'] as String? ?? '';
    if (thumb.isEmpty) return null;
    final url = 'https://spankbang.com/$id';
    return FeedVideo(
      title: cleanTitle(j['title'] as String? ?? ''),
      thumb: thumb,
      embedUrl: 'https://spankbang.com/$id/embed/',
      pageUrl: url,
      duration: j['duration']?.toString() ?? '',
      views: _fmtViews(j['views']),
      source: VideoSource.spankbang,
      publishedAt: _parseDate(j['date'] ?? j['added']),
    );
  }

  // ── Continuar padrão para Bravotube, DrTuber, TXXX, GotPorn e PornDig ──
  // Cada um segue o mesmo padrão: pageUrl = link da página, embedUrl = link embed.

  // ── Helpers ───────────────────────────────────────────────────────────────
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