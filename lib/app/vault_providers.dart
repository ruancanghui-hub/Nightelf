import 'package:ai_workbench/features/search/data/search_index.dart';
import 'package:ai_workbench/features/search/data/sqlite_search_index.dart';
import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:ai_workbench/features/settings/data/shared_preferences_app_settings.dart';
import 'package:ai_workbench/features/vault/application/vault_controller.dart';
import 'package:ai_workbench/features/vault/data/file_vault_repository.dart';
import 'package:ai_workbench/features/vault/data/resource_scanner.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appSettingsProvider = Provider<AppSettingsRepository>(
  (ref) => SharedPreferencesAppSettings(),
);

final vaultRepositoryProvider = Provider<VaultRepository>(
  (ref) => FileVaultRepository(),
);

final resourceScannerProvider = Provider<ResourceScanner>(
  (ref) => ResourceScanner(),
);

final searchIndexProvider = Provider<SearchIndex>((ref) {
  final index = SqliteSearchIndex.inMemory();
  ref.onDispose(index.close);
  return index;
});

final vaultControllerProvider = Provider<VaultController>((ref) {
  final controller = VaultController(
    repository: ref.watch(vaultRepositoryProvider),
    scan: ref.watch(resourceScannerProvider).scan,
    index: ref.watch(searchIndexProvider),
    settings: ref.watch(appSettingsProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});
