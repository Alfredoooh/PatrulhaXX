import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modos de tema suportados
enum AppThemeMode { light, dark, system }

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  late SharedPreferences _p;

  String        _bg            = 'assets/images/background.png';
  AppThemeMode  _themeMode     = AppThemeMode.dark;
  bool          _useWallpaper  = false;
  String        _engine        = 'google';
  int           _lockDelay     = 0;
  bool          _privacyRecent = true;
  bool          _noScreenshot  = true;
  int           _maxVolume     = 100;
  Color?        _wallpaperColor;

  // ── Feed preferences ───────────────────────────────────────────────────────
  int          _feedPageSize = 20;
  bool         _feedAutoplay = false;
  Set<String>  _feedSources  = {
    'eporner', 'pornhub', 'redtube', 'youporn',
    'xvideos', 'xhamster', 'spankbang',
  };

  // ── Getters ────────────────────────────────────────────────────────────────
  String       get bg            => _bg;
  AppThemeMode get themeMode     => _themeMode;
  bool         get useWallpaper  => _useWallpaper;
  String       get engine        => _engine;
  int          get lockDelay     => _lockDelay;
  bool         get privacyRecent => _privacyRecent;
  bool         get noScreenshot  => _noScreenshot;
  int          get maxVolume     => _maxVolume;
  Color?       get wallpaperColor => _wallpaperColor;
  int          get feedPageSize  => _feedPageSize;
  bool         get feedAutoplay  => _feedAutoplay;
  Set<String>  get feedSources   => Set.unmodifiable(_feedSources);

  /// Retrocompatibilidade: true quando o tema efectivo é escuro
  bool get isDark => _themeMode == AppThemeMode.dark ||
      (_themeMode == AppThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  /// ThemeMode do Flutter para passar ao MaterialApp
  ThemeMode get flutterThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:  return ThemeMode.light;
      case AppThemeMode.dark:   return ThemeMode.dark;
      case AppThemeMode.system: return ThemeMode.system;
    }
  }

  // ── Listas estáticas ───────────────────────────────────────────────────────
  static const List<String> wallpapers = [
    'assets/images/background.png',
    'assets/images/bg2.jpg',
    'assets/images/bg3.jpg',
    'assets/images/bg4.jpg',
    'assets/images/bg5.jpg',
    'assets/images/bg6.jpg',
    'assets/images/bg7.jpg',
    'assets/images/bg8.jpg',
    'assets/images/bg9.jpg',
    'assets/images/bg10.jpg',
    'assets/images/bg11.jpg',
    'assets/images/bg12.jpg',
  ];

  static const Map<String, String> engines = {
    'google':     'Google',
    'bing':       'Bing',
    'duckduckgo': 'DuckDuckGo',
    'brave':      'Brave',
  };

  static const Map<String, String> availableFeedSources = {
    'eporner':   'EPorner',
    'pornhub':   'PornHub',
    'redtube':   'RedTube',
    'youporn':   'YouPorn',
    'xvideos':   'XVideos',
    'xhamster':  'xHamster',
    'spankbang': 'SpankBang',
    'bravotube': 'BravoTube',
    'drtuber':   'DrTuber',
    'txxx':      'TXXX',
  };

  // ── Init ───────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _p             = await SharedPreferences.getInstance();
    _bg            = _p.getString('bg')          ?? wallpapers.first;
    _useWallpaper  = _p.getBool('use_wallpaper') ?? false;
    _engine        = _p.getString('engine')      ?? 'google';
    _lockDelay     = _p.getInt('lock_delay')     ?? 0;
    _privacyRecent = _p.getBool('priv_recent')   ?? true;
    _noScreenshot  = _p.getBool('no_ss')         ?? true;
    _maxVolume     = _p.getInt('max_vol')        ?? 100;
    _feedPageSize  = _p.getInt('feed_page_size') ?? 20;
    _feedAutoplay  = _p.getBool('feed_autoplay') ?? false;

    // Migração: ler 'dark' legado e converter para themeMode
    final savedThemeMode = _p.getString('theme_mode');
    if (savedThemeMode != null) {
      _themeMode = _themeModeFromString(savedThemeMode);
    } else {
      // Compatibilidade com versões anteriores que só tinham 'dark'
      final legacyDark = _p.getBool('dark') ?? true;
      _themeMode = legacyDark ? AppThemeMode.dark : AppThemeMode.light;
    }

    final savedColor = _p.getInt('wallpaper_color');
    if (savedColor != null) _wallpaperColor = Color(savedColor);

    final savedSources = _p.getStringList('feed_sources');
    if (savedSources != null && savedSources.isNotEmpty) {
      _feedSources = savedSources.toSet();
    }

    notifyListeners();
  }

  // ── Setters ────────────────────────────────────────────────────────────────
  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    await _p.setString('theme_mode', _themeModeToString(mode));
    // Mantém 'dark' em sync para retrocompatibilidade
    await _p.setBool('dark', mode == AppThemeMode.dark);
    notifyListeners();
  }

  /// Retrocompatibilidade directa com código antigo que chame setDark
  Future<void> setDark(bool v) =>
      setThemeMode(v ? AppThemeMode.dark : AppThemeMode.light);

  Future<void> setBg(String v) async {
    _bg = v;
    await _p.setString('bg', v);
    notifyListeners();
  }

  Future<void> setUseWallpaper(bool v) async {
    _useWallpaper = v;
    await _p.setBool('use_wallpaper', v);
    notifyListeners();
  }

  Future<void> setEngine(String v) async {
    _engine = v;
    await _p.setString('engine', v);
    notifyListeners();
  }

  Future<void> setLockDelay(int v) async {
    _lockDelay = v;
    await _p.setInt('lock_delay', v);
    notifyListeners();
  }

  Future<void> setPrivacyRecent(bool v) async {
    _privacyRecent = v;
    await _p.setBool('priv_recent', v);
    notifyListeners();
  }

  Future<void> setNoScreenshot(bool v) async {
    _noScreenshot = v;
    await _p.setBool('no_ss', v);
    notifyListeners();
  }

  Future<void> setMaxVolume(int v) async {
    _maxVolume = v.clamp(10, 100);
    await _p.setInt('max_vol', _maxVolume);
    notifyListeners();
  }

  Future<void> setFeedPageSize(int v) async {
    _feedPageSize = v.clamp(10, 60);
    await _p.setInt('feed_page_size', _feedPageSize);
    notifyListeners();
  }

  Future<void> setFeedAutoplay(bool v) async {
    _feedAutoplay = v;
    await _p.setBool('feed_autoplay', v);
    notifyListeners();
  }

  Future<void> setWallpaperColor(Color c) async {
    _wallpaperColor = c;
    await _p.setInt('wallpaper_color', c.value);
    notifyListeners();
  }

  Future<void> toggleFeedSource(String sourceId) async {
    if (_feedSources.contains(sourceId)) {
      if (_feedSources.length > 1) _feedSources.remove(sourceId);
    } else {
      _feedSources.add(sourceId);
    }
    await _p.setStringList('feed_sources', _feedSources.toList());
    notifyListeners();
  }

  bool isFeedSourceActive(String sourceId) => _feedSources.contains(sourceId);

  String searchUrl(String q) {
    final e = Uri.encodeComponent(q);
    switch (_engine) {
      case 'bing':       return 'https://www.bing.com/search?q=$e';
      case 'duckduckgo': return 'https://duckduckgo.com/?q=$e';
      case 'brave':      return 'https://search.brave.com/search?q=$e';
      default:           return 'https://www.google.com/search?q=$e';
    }
  }

  String get lockDelayLabel {
    if (_lockDelay == 0)   return 'Imediato';
    if (_lockDelay < 60)   return '$_lockDelay seg';
    if (_lockDelay < 3600) return '${_lockDelay ~/ 60} min';
    return '${_lockDelay ~/ 3600} h';
  }

  // ── Helpers privados ───────────────────────────────────────────────────────
  static String _themeModeToString(AppThemeMode m) {
    switch (m) {
      case AppThemeMode.light:  return 'light';
      case AppThemeMode.dark:   return 'dark';
      case AppThemeMode.system: return 'system';
    }
  }

  static AppThemeMode _themeModeFromString(String s) {
    switch (s) {
      case 'light':  return AppThemeMode.light;
      case 'system': return AppThemeMode.system;
      default:       return AppThemeMode.dark;
    }
  }
}
