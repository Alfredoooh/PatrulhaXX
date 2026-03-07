import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._();
  ThemeService._();

  late SharedPreferences _p;

  String _bg            = 'assets/images/background.png';
  bool   _dark          = true;
  String _engine        = 'google';
  int    _lockDelay     = 0;
  bool   _privacyRecent = true;
  bool   _noScreenshot  = true;
  int    _maxVolume     = 100;

  String get bg            => _bg;
  bool   get isDark        => _dark;
  String get engine        => _engine;
  int    get lockDelay     => _lockDelay;
  bool   get privacyRecent => _privacyRecent;
  bool   get noScreenshot  => _noScreenshot;
  int    get maxVolume     => _maxVolume;

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

  Future<void> init() async {
    _p            = await SharedPreferences.getInstance();
    _bg            = _p.getString('bg')         ?? wallpapers.first;
    _dark          = _p.getBool('dark')         ?? true;
    _engine        = _p.getString('engine')     ?? 'google';
    _lockDelay     = _p.getInt('lock_delay')    ?? 0;
    _privacyRecent = _p.getBool('priv_recent')  ?? true;
    _noScreenshot  = _p.getBool('no_ss')        ?? true;
    _maxVolume     = _p.getInt('max_vol')       ?? 100;
    notifyListeners();
  }

  Future<void> setBg(String v)          async { _bg = v;            await _p.setString('bg', v);          notifyListeners(); }
  Future<void> setDark(bool v)          async { _dark = v;          await _p.setBool('dark', v);           notifyListeners(); }
  Future<void> setEngine(String v)      async { _engine = v;        await _p.setString('engine', v);      notifyListeners(); }
  Future<void> setLockDelay(int v)      async { _lockDelay = v;     await _p.setInt('lock_delay', v);     notifyListeners(); }
  Future<void> setPrivacyRecent(bool v) async { _privacyRecent = v; await _p.setBool('priv_recent', v);   notifyListeners(); }
  Future<void> setNoScreenshot(bool v)  async { _noScreenshot = v;  await _p.setBool('no_ss', v);         notifyListeners(); }
  Future<void> setMaxVolume(int v)      async { _maxVolume = v.clamp(10,100); await _p.setInt('max_vol', _maxVolume); notifyListeners(); }

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
}
