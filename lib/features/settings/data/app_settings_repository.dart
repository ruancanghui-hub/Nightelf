abstract class AppSettingsRepository {
  Future<String?> readLastVaultPath();

  Future<void> writeLastVaultPath(String? path);
}
