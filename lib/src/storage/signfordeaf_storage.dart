import 'package:shared_preferences/shared_preferences.dart';

/// Simple key/value store for remembering one-off UI state across app launches
/// (currently how many times the tap-to-translate hint has been shown).
abstract class SignForDeafStorage {
  Future<String?> getItem(String key);
  Future<void> setItem(String key, String value);
}

/// Non-persistent default store that only lives for the current session.
class InMemorySignForDeafStorage implements SignForDeafStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> getItem(String key) async => _store[key];

  @override
  Future<void> setItem(String key, String value) async {
    _store[key] = value;
  }
}

/// `shared_preferences`-backed persistent store (survives app restarts).
class SharedPreferencesSignForDeafStorage implements SignForDeafStorage {
  static const _prefix = 'weaccess_sl_';

  @override
  Future<String?> getItem(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_prefix$key');
  }

  @override
  Future<void> setItem(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_prefix$key', value);
  }
}
