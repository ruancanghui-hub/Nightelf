import 'dart:io';

import 'package:ai_workbench/features/search/data/search_index.dart';
import 'package:ai_workbench/features/search/domain/search_hit.dart';
import 'package:ai_workbench/features/search/domain/search_query.dart';
import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:ai_workbench/features/vault/data/resource_scanner.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';

class FakeVaultRepository implements VaultRepository {
  FakeVaultRepository._({this.handle, this.openError, this.createError});

  factory FakeVaultRepository.opening(VaultHandle handle) =>
      FakeVaultRepository._(handle: handle);

  factory FakeVaultRepository.failingOpen(Object error) =>
      FakeVaultRepository._(openError: error);

  final VaultHandle? handle;
  final Object? openError;
  final Object? createError;
  int openCount = 0;
  int createCount = 0;

  @override
  Future<VaultHandle> create(Directory root, String name) async {
    createCount += 1;
    final error = createError;
    if (error != null) {
      throw error;
    }
    return handle!;
  }

  @override
  Future<VaultHandle> open(Directory root) async {
    openCount += 1;
    final error = openError;
    if (error != null) {
      throw error;
    }
    return handle!;
  }
}

class FakeResourceScanner {
  FakeResourceScanner(this.records);

  List<ResourceRecord> records;
  int scanCount = 0;

  Future<List<ResourceRecord>> scan(VaultHandle vault) async {
    scanCount += 1;
    return List<ResourceRecord>.from(records);
  }
}

class RecordingSearchIndex implements SearchIndex {
  List<ResourceRecord>? rebuiltWith;
  final List<ResourceRecord> upserts = [];
  final List<String> removals = [];

  @override
  Future<void> rebuild(Iterable<ResourceRecord> records) async {
    rebuiltWith = records.toList(growable: false);
  }

  @override
  Future<void> upsert(ResourceRecord record) async {
    upserts.add(record);
  }

  @override
  Future<void> remove(String id) async {
    removals.add(id);
  }

  @override
  Future<List<SearchHit>> query(SearchQuery query) async => const [];

  @override
  Future<void> close() async {}
}

class MemoryAppSettings implements AppSettingsRepository {
  MemoryAppSettings({
    this.lastVaultPath,
    this.lastVaultBookmark,
    this.vaultSyncEnabledByPath,
    this.vaultSyncRemoteUrlByPath,
  });

  String? lastVaultPath;
  String? lastVaultBookmark;
  int writeCount = 0;

  Map<String, bool>? vaultSyncEnabledByPath;
  Map<String, String?>? vaultSyncRemoteUrlByPath;
  Map<String, bool>? vaultAutoPullEnabledByPath;
  Map<String, bool>? vaultAutoPushEnabledByPath;

  @override
  Future<String?> readLastVaultPath() async => lastVaultPath;

  @override
  Future<void> writeLastVaultPath(String? path) async {
    writeCount += 1;
    lastVaultPath = path;
    if (path == null || path.isEmpty) {
      lastVaultBookmark = null;
    }
  }

  @override
  Future<String?> readLastVaultBookmark() async => lastVaultBookmark;

  @override
  Future<void> writeLastVaultBookmark(String? bookmarkBase64) async {
    writeCount += 1;
    lastVaultBookmark = bookmarkBase64;
  }

  @override
  Future<void> writeLastVault({String? path, String? bookmarkBase64}) async {
    writeCount += 1;
    if (path == null || path.isEmpty) {
      lastVaultPath = null;
      lastVaultBookmark = null;
      return;
    }
    lastVaultPath = path;
    lastVaultBookmark = bookmarkBase64;
  }

  @override
  Future<bool> readVaultSyncEnabled(String vaultRootPath) async =>
      vaultSyncEnabledByPath?[vaultRootPath] ?? false;

  @override
  Future<String?> readVaultSyncRemoteUrl(String vaultRootPath) async =>
      vaultSyncRemoteUrlByPath?[vaultRootPath];

  @override
  Future<void> writeVaultSyncConfig({
    required String vaultRootPath,
    required bool enabled,
    String? remoteUrl,
  }) async {
    writeCount += 1;
    vaultSyncEnabledByPath ??= <String, bool>{};
    vaultSyncRemoteUrlByPath ??= <String, String?>{};

    vaultSyncEnabledByPath![vaultRootPath] = enabled;
    if (!enabled) {
      vaultSyncRemoteUrlByPath!.remove(vaultRootPath);
    } else {
      vaultSyncRemoteUrlByPath![vaultRootPath] = remoteUrl;
    }
  }

  @override
  Future<bool> readVaultAutoPullEnabled(String vaultRootPath) async =>
      vaultAutoPullEnabledByPath?[vaultRootPath] ?? false;

  @override
  Future<void> writeVaultAutoPullEnabled({
    required String vaultRootPath,
    required bool enabled,
  }) async {
    writeCount += 1;
    vaultAutoPullEnabledByPath ??= <String, bool>{};
    vaultAutoPullEnabledByPath![vaultRootPath] = enabled;
  }

  @override
  Future<bool> readVaultAutoPushEnabled(String vaultRootPath) async =>
      vaultAutoPushEnabledByPath?[vaultRootPath] ?? false;

  @override
  Future<void> writeVaultAutoPushEnabled({
    required String vaultRootPath,
    required bool enabled,
  }) async {
    writeCount += 1;
    vaultAutoPushEnabledByPath ??= <String, bool>{};
    vaultAutoPushEnabledByPath![vaultRootPath] = enabled;
  }
}

/// Adapts [FakeResourceScanner] to the real scanner call shape used by tests.
extension FakeScannerAsCallable on FakeResourceScanner {
  Future<List<ResourceRecord>> call(VaultHandle vault) => scan(vault);
}
