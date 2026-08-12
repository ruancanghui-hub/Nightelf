import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SharedPreferencesAppSettings implements AppSettingsRepository {
  SharedPreferencesAppSettings({SharedPreferences? preferences})
    : _preferencesFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  static const _lastVaultPathKey = 'last_vault_path';
  static const _lastVaultBookmarkKey = 'last_vault_bookmark';

  static const _vaultSyncEnabledMapKey = 'vault_sync_enabled_by_path';
  static const _vaultSyncRemoteUrlMapKey = 'vault_sync_remote_url_by_path';
  static const _vaultSyncAutoPullMapKey = 'vault_sync_auto_pull_enabled_by_path';
  static const _vaultSyncAutoPushMapKey = 'vault_sync_auto_push_enabled_by_path';

  final Future<SharedPreferences> _preferencesFuture;

  Future<Map<String, dynamic>> _readStringKeyedMap(
    String key,
  ) async {
    final preferences = await _preferencesFuture;
    final raw = preferences.getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return <String, dynamic>{};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  Future<void> _writeStringKeyedMap(String key, Map<String, dynamic> map) async {
    final preferences = await _preferencesFuture;
    await preferences.setString(key, jsonEncode(map));
  }

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

  @override
  Future<bool> readVaultSyncEnabled(String vaultRootPath) async {
    final map = await _readStringKeyedMap(_vaultSyncEnabledMapKey);
    final value = map[vaultRootPath];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  Future<String?> readVaultSyncRemoteUrl(String vaultRootPath) async {
    final map = await _readStringKeyedMap(_vaultSyncRemoteUrlMapKey);
    final value = map[vaultRootPath];
    if (value == null) {
      return null;
    }
    return value.toString();
  }

  @override
  Future<void> writeVaultSyncConfig({
    required String vaultRootPath,
    required bool enabled,
    String? remoteUrl,
  }) async {
    // Force a mutable copy to avoid potential unmodifiable-map returns.
    final enabledMap =
        Map<String, dynamic>.from(await _readStringKeyedMap(_vaultSyncEnabledMapKey));
    final remoteMap = Map<String, dynamic>.from(
      await _readStringKeyedMap(_vaultSyncRemoteUrlMapKey),
    );

    enabledMap[vaultRootPath] = enabled;

    if (!enabled) {
      remoteMap.remove(vaultRootPath);
    } else if (remoteUrl == null || remoteUrl.trim().isEmpty) {
      remoteMap.remove(vaultRootPath);
    } else {
      remoteMap[vaultRootPath] = remoteUrl.trim();
    }

    await _writeStringKeyedMap(_vaultSyncEnabledMapKey, enabledMap);
    await _writeStringKeyedMap(_vaultSyncRemoteUrlMapKey, remoteMap);
  }

  @override
  Future<bool> readVaultAutoPullEnabled(String vaultRootPath) async {
    final map = await _readStringKeyedMap(_vaultSyncAutoPullMapKey);
    final value = map[vaultRootPath];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  Future<void> writeVaultAutoPullEnabled({
    required String vaultRootPath,
    required bool enabled,
  }) async {
    final autoPullMap = Map<String, dynamic>.from(
      await _readStringKeyedMap(_vaultSyncAutoPullMapKey),
    );
    autoPullMap[vaultRootPath] = enabled;
    await _writeStringKeyedMap(_vaultSyncAutoPullMapKey, autoPullMap);
  }

  @override
  Future<bool> readVaultAutoPushEnabled(String vaultRootPath) async {
    final map = await _readStringKeyedMap(_vaultSyncAutoPushMapKey);
    final value = map[vaultRootPath];
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    return false;
  }

  @override
  Future<void> writeVaultAutoPushEnabled({
    required String vaultRootPath,
    required bool enabled,
  }) async {
    final autoPushMap = Map<String, dynamic>.from(
      await _readStringKeyedMap(_vaultSyncAutoPushMapKey),
    );
    autoPushMap[vaultRootPath] = enabled;
    await _writeStringKeyedMap(_vaultSyncAutoPushMapKey, autoPushMap);
  }
}
