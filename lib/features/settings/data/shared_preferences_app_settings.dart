import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesAppSettings implements AppSettingsRepository {
  SharedPreferencesAppSettings({SharedPreferences? preferences})
    : _preferencesFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  static const _lastVaultPathKey = 'last_vault_path';

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
}
