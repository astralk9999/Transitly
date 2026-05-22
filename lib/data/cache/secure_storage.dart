import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveSession(String key, String value) async {
    await _storage.write(key: 'supabase_$key', value: value);
  }

  static Future<String?> readSession(String key) async {
    return await _storage.read(key: 'supabase_$key');
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
