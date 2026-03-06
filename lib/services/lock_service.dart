import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LockService {
  static final LockService instance = LockService._();
  LockService._();

  static const _storage = FlutterSecureStorage();
  static const _keyPin = 'app_pin';
  static const _keyEnabled = 'lock_enabled';
  static const String defaultPin = '0123';

  /// Inicializa: define o PIN padrão se for a primeira vez
  Future<void> init() async {
    final existing = await _storage.read(key: _keyPin);
    if (existing == null) {
      await _storage.write(key: _keyPin, value: defaultPin);
      await _storage.write(key: _keyEnabled, value: 'true');
    }
  }

  Future<String?> getPin() => _storage.read(key: _keyPin);

  Future<bool> isEnabled() async {
    final v = await _storage.read(key: _keyEnabled);
    return v == 'true';
  }

  Future<void> setEnabled(bool value) async {
    await _storage.write(key: _keyEnabled, value: value ? 'true' : 'false');
  }

  Future<bool> verify(String input) async {
    final pin = await getPin();
    return pin == input;
  }

  Future<void> setPin(String newPin) async {
    await _storage.write(key: _keyPin, value: newPin);
  }
}