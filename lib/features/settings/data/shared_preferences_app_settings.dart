import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppSettings implements AppSettingsRepository {
  SharedPreferencesAppSettings({SharedPreferences? preferences})
    : _preferencesFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  static const _lastVaultPathKey = 'last_vault_path';
  static const _lastVaultBookmarkKey = 'last_vault_bookmark';

  final Future<SharedPreferences> _preferencesFuture;

  @override
  Future<String?> readLastVaultPath() async {
    final preferences = await _preferencesFuture;
    return preferences.getString(_lastVaultPathKey);
  }

  @override
  Future<void> writeLastVaultPath(String? path) async {
    final preferences = await _preferencesFuture;
    if (path == null || path.isEmpty) {
      await preferences.remove(_lastVaultPathKey);
    } else {
      await preferences.setString(_lastVaultPathKey, path);
    }
  }

  @override
  Future<String?> readLastVaultBookmark() async {
    final preferences = await _preferencesFuture;
    return preferences.getString(_lastVaultBookmarkKey);
  }

  @override
  Future<void> writeLastVaultBookmark(String? bookmarkBase64) async {
    final preferences = await _preferencesFuture;
    if (bookmarkBase64 == null || bookmarkBase64.isEmpty) {
      await preferences.remove(_lastVaultBookmarkKey);
    } else {
      await preferences.setString(_lastVaultBookmarkKey, bookmarkBase64);
    }
  }

  @override
  Future<void> writeLastVault({String? path, String? bookmarkBase64}) async {
    final preferences = await _preferencesFuture;
    if (path == null || path.isEmpty) {
      await preferences.remove(_lastVaultPathKey);
      await preferences.remove(_lastVaultBookmarkKey);
      return;
    }
    await preferences.setString(_lastVaultPathKey, path);
    if (bookmarkBase64 == null || bookmarkBase64.isEmpty) {
      await preferences.remove(_lastVaultBookmarkKey);
    } else {
      await preferences.setString(_lastVaultBookmarkKey, bookmarkBase64);
    }
  }
}
