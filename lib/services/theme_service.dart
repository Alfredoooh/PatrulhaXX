import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  static const _s = FlutterSecureStorage();

  String _bg            = 'assets/images/background.png';
  bool   _dark          = true;
  String _engine        = 'google';
  int    _lockDelay     = 0;       // seconds; 0 = immediate
  bool   _privacyRecent = true;
  bool   _noScreenshot  = true;
  int    _maxVolume     = 100;

  String get bg             => _bg;
  bool   get isDark         => _dark;
  String get engine         => _engine;
  int    get lockDelay      => _lockDelay;
  bool   get privacyRecent  => _privacyRecent;
  bool   get noScreenshot   => _noScreenshot;
  int    get maxVolume      => _maxVolume;

  // All images that live in assets/images/ (declare them all in pubspec)
  static const List<String> wallpapers = [
    'assets/images/background.png',
    'assets/images/bg2.png',
    'assets/images/bg3.png',
    'assets/images/bg4.png',
    'assets/images/bg5.png',
  ];

  static const Map<String, String> engines = {
    'google':     'Google',
    'bing':       'Bing',
    'duckduckgo': 'DuckDuckGo',
    'brave':      'Brave',
  };

  Future<void> init() async {
    _bg            = await _s.read(key: 'bg')     ?? wallpapers.first;
    _dark          = (await _s.read(key: 'dark')) != 'false';
    _engine        = await _s.read(key: 'engine') ?? 'google';
    _lockDelay     = int.tryParse(await _s.read(key: 'lock_delay') ?? '0') ?? 0;
    _privacyRecent = (await _s.read(key: 'priv_recent')) != 'false';
    _noScreenshot  = (await _s.read(key: 'no_ss')) != 'false';
    _maxVolume     = int.tryParse(await _s.read(key: 'max_vol') ?? '100') ?? 100;
    notifyListeners();
  }

  Future<void> setBg(String v)           async { _bg = v;            await _s.write(key:'bg',          value:v);                      notifyListeners(); }
  Future<void> setDark(bool v)           async { _dark = v;          await _s.write(key:'dark',        value:v?'true':'false');        notifyListeners(); }
  Future<void> setEngine(String v)       async { _engine = v;        await _s.write(key:'engine',      value:v);                      notifyListeners(); }
  Future<void> setLockDelay(int v)       async { _lockDelay = v;     await _s.write(key:'lock_delay',  value:v.toString());           notifyListeners(); }
  Future<void> setPrivacyRecent(bool v)  async { _privacyRecent = v; await _s.write(key:'priv_recent', value:v?'true':'false');        notifyListeners(); }
  Future<void> setNoScreenshot(bool v)   async { _noScreenshot = v;  await _s.write(key:'no_ss',       value:v?'true':'false');        notifyListeners(); }
  Future<void> setMaxVolume(int v)       async { _maxVolume = v.clamp(10,100); await _s.write(key:'max_vol', value:_maxVolume.toString()); notifyListeners(); }

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
    if (_lockDelay == 0)    return 'Imediato';
    if (_lockDelay < 60)    return '$_lockDelay seg';
    if (_lockDelay < 3600)  return '${_lockDelay ~/ 60} min';
    return '${_lockDelay ~/ 3600} h';
  }
}
