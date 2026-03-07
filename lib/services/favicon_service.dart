import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/site_model.dart';

class FaviconService {
  static final FaviconService instance = FaviconService._internal();
  FaviconService._internal();

  final _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));

  final Map<String, String> _pathCache = {};
  final Map<String, Color> _colorCache = {};

  Future<void> preloadAll() async {
    await Future.wait(kSites.where((s) => !s.hasLocalIcon).map(_ensureFavicon));
  }

  Future<String?> getLocalPath(SiteModel site) async {
    if (site.hasLocalIcon) return null;
    if (_pathCache.containsKey(site.id)) return _pathCache[site.id];
    return _ensureFavicon(site);
  }

  Future<String?> _ensureFavicon(SiteModel site) async {
    if (_pathCache.containsKey(site.id)) return _pathCache[site.id];

    final p = await SharedPreferences.getInstance();
    final stored = p.getString('fav_${site.id}');
    if (stored != null && File(stored).existsSync()) {
      _pathCache[site.id] = stored;
      return stored;
    }

    try {
      final dir = await getApplicationDocumentsDirectory();
      final favsDir = Directory('${dir.path}/favicons');
      await favsDir.create(recursive: true);
      final path = '${favsDir.path}/${site.id}.png';
      await _dio.download(site.faviconUrl, path);
      await p.setString('fav_${site.id}', path);
      _pathCache[site.id] = path;
      return path;
    } catch (_) {
      return null;
    }
  }

  Future<Color> extractColor(SiteModel site) async {
    if (_colorCache.containsKey(site.id)) return _colorCache[site.id]!;
    ImageProvider? provider;
    if (site.hasLocalIcon) {
      provider = AssetImage(site.localIconAsset!);
    } else {
      final path = _pathCache[site.id];
      if (path != null && File(path).existsSync()) {
        provider = FileImage(File(path));
      }
    }
    if (provider == null) return site.primaryColor;
    try {
      final palette = await PaletteGenerator.fromImageProvider(
          provider, size: const Size(64, 64), maximumColorCount: 8);
      final color = palette.dominantColor?.color ??
          palette.vibrantColor?.color ?? site.primaryColor;
      final hsl = HSLColor.fromColor(color);
      final result = hsl.withLightness(hsl.lightness.clamp(0.15, 0.45)).toColor();
      _colorCache[site.id] = result;
      return result;
    } catch (_) {
      return site.primaryColor;
    }
  }

  Future<void> clearAll() async {
    _pathCache.clear();
    _colorCache.clear();
    final dir = await getApplicationDocumentsDirectory();
    final favsDir = Directory('${dir.path}/favicons');
    if (favsDir.existsSync()) await favsDir.delete(recursive: true);
    final p = await SharedPreferences.getInstance();
    final keys = p.getKeys().where((k) => k.startsWith('fav_')).toList();
    for (final k in keys) { await p.remove(k); }
  }
}
