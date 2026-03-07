import 'package:shared_preferences/shared_preferences.dart';

class LockService {
  static final LockService instance = LockService._();
  LockService._();

  static const _keyPin     = 'app_pin';
  static const _keyEnabled = 'lock_enabled';
  static const String defaultPin = '0123';

  Future<void> init() async {
    final p = await SharedPreferences.getInstance();
    if (!p.containsKey(_keyPin)) {
      await p.setString(_keyPin, defaultPin);
      await p.setBool(_keyEnabled, true);
    }
  }

  Future<String?> getPin() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_keyPin);
  }

  Future<bool> isEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_keyEnabled) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyEnabled, value);
  }

  Future<bool> verify(String input) async {
    final pin = await getPin();
    return pin == input;
  }

  Future<void> setPin(String newPin) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_keyPin, newPin);
  }
}
