import 'package:shared_preferences/shared_preferences.dart';

import '../core/app_constants.dart';

/// Thin wrapper around [SharedPreferences] for persisting the Gemini API
/// key locally on-device.
class SettingsService {
  SharedPreferences? _prefs;

  /// Must be awaited once at startup (before first frame).
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  SharedPreferences get _storage {
    final SharedPreferences? prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'SettingsService.init() must complete before reading settings.',
      );
    }
    return prefs;
  }

  /// Returns the saved key, or an empty string when none is stored.
  String getApiKey() => _prefs?.getString(AppConstants.apiKeyStorageKey) ?? '';

  /// Whether a non-empty API key is currently stored.
  bool get hasApiKey => getApiKey().trim().isNotEmpty;

  /// Persists a new key. Empty input clears the stored value.
  Future<void> saveApiKey(String apiKey) async {
    await init();
    final String trimmed = apiKey.trim();
    if (trimmed.isEmpty) {
      await _storage.remove(AppConstants.apiKeyStorageKey);
    } else {
      await _storage.setString(AppConstants.apiKeyStorageKey, trimmed);
    }
  }
}
