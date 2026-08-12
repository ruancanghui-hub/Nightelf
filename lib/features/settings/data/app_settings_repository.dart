abstract class AppSettingsRepository {
  Future<String?> readLastVaultPath();

  Future<void> writeLastVaultPath(String? path);

  Future<String?> readLastVaultBookmark();

  Future<void> writeLastVaultBookmark(String? bookmarkBase64);

  /// Writes both path and bookmark (or clears both when path is null).
  Future<void> writeLastVault({String? path, String? bookmarkBase64});

  /// Per-Vault Git sync configuration.
  ///
  /// When disabled, Nightelf MUST NOT run any git commands for this vault.
  Future<bool> readVaultSyncEnabled(String vaultRootPath);

  /// Remote URL used by git (e.g. https://... or git@...).
  ///
  /// May be null when [readVaultSyncEnabled] is false.
  Future<String?> readVaultSyncRemoteUrl(String vaultRootPath);

  /// Writes both enabled flag and remote URL for a vault.
  /// When [enabled] is false, remote url may be cleared.
  Future<void> writeVaultSyncConfig({
    required String vaultRootPath,
    required bool enabled,
    String? remoteUrl,
  });

  /// Per-Vault auto pull flag.
  ///
  /// When true and Git sync is enabled for the vault, Nightelf will run a
  /// best-effort `git pull --rebase` once when opening/activating the vault.
  Future<bool> readVaultAutoPullEnabled(String vaultRootPath);

  Future<void> writeVaultAutoPullEnabled({
    required String vaultRootPath,
    required bool enabled,
  });

  /// Per-Vault auto push flag.
  ///
  /// When true and Git sync is enabled for the vault, Nightelf will run a
  /// best-effort `git push` after a successful auto pull.
  Future<bool> readVaultAutoPushEnabled(String vaultRootPath);

  Future<void> writeVaultAutoPushEnabled({
    required String vaultRootPath,
    required bool enabled,
  });
}
