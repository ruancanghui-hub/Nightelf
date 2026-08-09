import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/search/data/search_index.dart';
import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/features/vault/data/vault_change_watcher.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:flutter/foundation.dart';

typedef VaultScan = Future<List<ResourceRecord>> Function(VaultHandle vault);
typedef VaultWatch = Stream<Set<String>> Function(Directory root);

class VaultController extends ChangeNotifier {
  VaultController({
    required VaultRepository repository,
    required VaultScan scan,
    required SearchIndex index,
    required AppSettingsRepository settings,
    VaultWatch? watch,
  }) : _repository = repository,
       _scan = scan,
       _index = index,
       _settings = settings,
       _watch = watch ?? VaultChangeWatcher().watch;

  final VaultRepository _repository;
  final VaultScan _scan;
  final SearchIndex _index;
  final AppSettingsRepository _settings;
  final VaultWatch _watch;

  VaultState _state = const VaultClosed();
  StreamSubscription<Set<String>>? _watchSubscription;

  VaultState get state => _state;

  Future<void> restoreLastVault() async {
    final path = await _settings.readLastVaultPath();
    if (path == null || path.isEmpty) {
      _setState(const VaultClosed());
      return;
    }

    final root = Directory(path);
    if (!await root.exists()) {
      await _settings.writeLastVaultPath(null);
      _setState(const VaultClosed());
      return;
    }

    try {
      await _openRoot(root, remember: true);
    } catch (_) {
      await _settings.writeLastVaultPath(null);
      _setState(const VaultClosed());
    }
  }

  Future<void> createVault(Directory root, String name) async {
    _setState(const VaultOpening());
    try {
      await _cancelWatcher();
      final handle = await _repository.create(root, name);
      await _activate(handle);
    } catch (error) {
      await _cancelWatcher();
      _setState(VaultFailure(_createErrorMessage(error)));
    }
  }

  Future<void> openVault(Directory root) async {
    _setState(const VaultOpening());
    try {
      await _openRoot(root, remember: true);
    } catch (error) {
      await _cancelWatcher();
      _setState(VaultFailure(_openErrorMessage(error)));
    }
  }

  Future<void> closeVault() async {
    await _cancelWatcher();
    await _settings.writeLastVaultPath(null);
    _setState(const VaultClosed());
  }

  Future<void> refreshPaths(Set<String> paths) async {
    final current = _state;
    if (current is! VaultOpen) {
      return;
    }
    // Phase 1: full rescan is acceptable; paths reserved for later optimization.
    try {
      if (!await current.handle.root.exists()) {
        await closeVault();
        return;
      }
      final resources = await _scan(current.handle);
      await _index.rebuild(resources);
      _setState(VaultOpen(handle: current.handle, resources: resources));
    } on PathNotFoundException {
      await closeVault();
    } on FileSystemException {
      await closeVault();
    }
  }

  @override
  void dispose() {
    unawaited(_cancelWatcher());
    super.dispose();
  }

  Future<void> _openRoot(Directory root, {required bool remember}) async {
    await _cancelWatcher();
    final handle = await _repository.open(root);
    await _activate(handle, remember: remember);
  }

  Future<void> _activate(VaultHandle handle, {bool remember = true}) async {
    final resources = await _scan(handle);
    await _index.rebuild(resources);
    if (remember) {
      await _settings.writeLastVaultPath(handle.root.path);
    }
    _watchSubscription = _watch(handle.root).listen((paths) {
      unawaited(refreshPaths(paths));
    });
    _setState(VaultOpen(handle: handle, resources: resources));
  }

  Future<void> _cancelWatcher() async {
    await _watchSubscription?.cancel();
    _watchSubscription = null;
  }

  void _setState(VaultState next) {
    _state = next;
    notifyListeners();
  }

  String _openErrorMessage(Object error) {
    if (error is InvalidVaultException) {
      return '无法打开 Vault：所选文件夹不是有效的资源库。';
    }
    if (error is UnsupportedVaultVersionException) {
      return '无法打开 Vault：资源库版本不受支持。';
    }
    return '无法打开 Vault：${_shortError(error)}';
  }

  String _createErrorMessage(Object error) {
    if (error is VaultAlreadyExistsException) {
      return '无法创建 Vault：目标文件夹已是资源库。';
    }
    return '无法创建 Vault：${_shortError(error)}';
  }

  String _shortError(Object error) {
    final text = error.toString();
    return text.length > 120 ? '${text.substring(0, 120)}…' : text;
  }
}
