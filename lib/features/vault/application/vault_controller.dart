import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/search/data/search_index.dart';
import 'package:ai_workbench/features/settings/data/app_settings_repository.dart';
import 'package:ai_workbench/features/vault/application/vault_state.dart';
import 'package:ai_workbench/features/vault/data/vault_change_watcher.dart';
import 'package:ai_workbench/features/vault/data/vault_repository.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/platform/directory_picker_service.dart';
import 'package:ai_workbench/shared/platform/folder_icon_service.dart';
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
    DirectoryPickerService? vaultAccess,
    FolderIconService? folderIcons,
  }) : _repository = repository,
       _scan = scan,
       _index = index,
       _settings = settings,
       _watch = watch ?? VaultChangeWatcher().watch,
       _vaultAccess = vaultAccess ?? defaultDirectoryPickerService(),
       _folderIcons = folderIcons ?? defaultFolderIconService();

  final VaultRepository _repository;
  final VaultScan _scan;
  final SearchIndex _index;
  final AppSettingsRepository _settings;
  final VaultWatch _watch;
  final DirectoryPickerService _vaultAccess;
  final FolderIconService _folderIcons;

  VaultState _state = const VaultClosed();
  StreamSubscription<Set<String>>? _watchSubscription;
  String? _activeAccessPath;
  String? _pendingBookmark;

  VaultState get state => _state;

  Future<void> restoreLastVault() async {
    final path = await _settings.readLastVaultPath();
    if (path == null || path.isEmpty) {
      _setState(const VaultClosed());
      return;
    }

    _setState(const VaultOpening());

    final bookmark = await _settings.readLastVaultBookmark();
    Directory? root;
    String? resolvedBookmark = bookmark;

    if (bookmark != null && bookmark.isNotEmpty) {
      try {
        final resolved = await _vaultAccess.resolveBookmark(bookmark);
        if (resolved != null) {
          root = Directory(resolved.path);
          _activeAccessPath = resolved.path;
          if (resolved.bookmarkBase64 != null) {
            resolvedBookmark = resolved.bookmarkBase64;
          }
        }
      } catch (_) {
        root = null;
      }
    }

    root ??= Directory(path);
    if (!await root.exists()) {
      await _settings.writeLastVault();
      _setState(const VaultClosed());
      return;
    }

    try {
      await _openRoot(
        root,
        remember: true,
        bookmarkBase64: resolvedBookmark,
      );
    } catch (error) {
      // Keep prefs so the user can retry or re-pick; only missing paths clear.
      _setState(
        VaultFailure(
          '无法打开上次 Vault，请重新选择。${_shortError(error)}',
        ),
      );
    }
  }

  Future<void> createVault(
    Directory root,
    String name, {
    String? bookmarkBase64,
  }) async {
    _setState(const VaultOpening());
    try {
      await _cancelWatcher();
      _pendingBookmark = bookmarkBase64;
      final handle = await _repository.create(root, name);
      await _activate(handle);
    } catch (error) {
      _pendingBookmark = null;
      await _cancelWatcher();
      _setState(VaultFailure(_createErrorMessage(error)));
    }
  }

  Future<void> openVault(Directory root, {String? bookmarkBase64}) async {
    _setState(const VaultOpening());
    try {
      await _openRoot(root, remember: true, bookmarkBase64: bookmarkBase64);
    } catch (error) {
      await _cancelWatcher();
      _setState(VaultFailure(_openErrorMessage(error)));
    }
  }

  Future<void> closeVault() async {
    await _cancelWatcher();
    await _releaseAccess();
    await _settings.writeLastVault();
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
    unawaited(_releaseAccess());
    super.dispose();
  }

  Future<void> _openRoot(
    Directory root, {
    required bool remember,
    String? bookmarkBase64,
  }) async {
    await _cancelWatcher();
    _pendingBookmark = bookmarkBase64;
    final handle = await _repository.open(root);
    await _activate(handle, remember: remember);
  }

  Future<void> _activate(VaultHandle handle, {bool remember = true}) async {
    final resources = await _scan(handle);
    await _index.rebuild(resources);
    var bookmark = _pendingBookmark;
    _pendingBookmark = null;

    if (remember) {
      if (bookmark == null || bookmark.isEmpty) {
        try {
          bookmark = await _vaultAccess.createBookmark(handle.root.path);
        } catch (_) {
          bookmark = null;
        }
      }
      await _settings.writeLastVault(
        path: handle.root.path,
        bookmarkBase64: bookmark,
      );
      _activeAccessPath ??= handle.root.path;
    }

    unawaited(_brandFolder(handle.root.path));

    _watchSubscription = _watch(handle.root).listen((paths) {
      unawaited(refreshPaths(paths));
    });
    _setState(VaultOpen(handle: handle, resources: resources));
  }

  Future<void> _brandFolder(String path) async {
    try {
      await _folderIcons.setFolderIcon(path);
    } catch (_) {
      // Best-effort Finder branding; never fail vault open/create.
    }
  }

  Future<void> _releaseAccess() async {
    final path = _activeAccessPath;
    _activeAccessPath = null;
    if (path == null || path.isEmpty) {
      return;
    }
    try {
      await _vaultAccess.stopAccessing(path);
    } catch (_) {}
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
