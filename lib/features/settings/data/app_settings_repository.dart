abstract class AppSettingsRepository {
  Future<String?> readLastVaultPath();

  Future<void> writeLastVaultPath(String? path);

  Future<String?> readLastVaultBookmark();

  Future<void> writeLastVaultBookmark(String? bookmarkBase64);

  /// Writes both path and bookmark (or clears both when path is null).
  Future<void> writeLastVault({String? path, String? bookmarkBase64});
}
