import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;

/// Device-local restoration of open tabs and shell chrome.
class WorkspaceRestorationState {
  const WorkspaceRestorationState({
    this.openResourceIds = const [],
    this.activeResourceId,
    this.sidebarWidth = 248,
    this.inspectorVisible = true,
  });

  final List<String> openResourceIds;
  final String? activeResourceId;
  final double sidebarWidth;
  final bool inspectorVisible;
}

class WorkspaceRestorationRepository {
  WorkspaceRestorationRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
  }) : _file = File(
         p.join(vaultRoot.path, VaultPaths.localRoot, 'workspace.json'),
       ),
       _writer = writer ?? AtomicFileWriter();

  static const _version = 1;

  final File _file;
  final AtomicFileWriter _writer;

  Future<WorkspaceRestorationState> load({
    required Set<String> knownResourceIds,
  }) async {
    if (!await _file.exists()) {
      return const WorkspaceRestorationState();
    }
    try {
      final decoded = jsonDecode(await _file.readAsString());
      if (decoded is! Map) {
        return const WorkspaceRestorationState();
      }
      final rawIds = decoded['openResourceIds'];
      final openIds = rawIds is List
          ? rawIds
                .whereType<String>()
                .where(knownResourceIds.contains)
                .toList(growable: false)
          : const <String>[];
      final active = decoded['activeResourceId'];
      final activeId = active is String && knownResourceIds.contains(active)
          ? active
          : (openIds.isEmpty ? null : openIds.first);
      final width = decoded['sidebarWidth'];
      final inspector = decoded['inspectorVisible'];
      return WorkspaceRestorationState(
        openResourceIds: openIds,
        activeResourceId: activeId,
        sidebarWidth: width is num ? width.toDouble() : 248,
        inspectorVisible: inspector is bool ? inspector : true,
      );
    } on FormatException {
      return const WorkspaceRestorationState();
    }
  }

  Future<void> save(WorkspaceRestorationState state) async {
    try {
      await _file.parent.create(recursive: true);
      final payload = <String, Object?>{
        'version': _version,
        'openResourceIds': state.openResourceIds,
        'activeResourceId': state.activeResourceId,
        'sidebarWidth': state.sidebarWidth,
        'inspectorVisible': state.inspectorVisible,
      };
      await _writer.writeString(_file, '${jsonEncode(payload)}\n');
    } on FileSystemException {
      // Ignore when the Vault root vanished.
    }
  }
}
