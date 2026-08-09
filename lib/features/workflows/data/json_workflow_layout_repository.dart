import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/workflows/data/workflow_layout_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_layout.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;

class JsonWorkflowLayoutRepository implements WorkflowLayoutRepository {
  JsonWorkflowLayoutRepository({
    required Directory root,
    AtomicFileWriter? writer,
  }) : _root = root,
       _writer = writer ?? AtomicFileWriter();

  final Directory _root;
  final AtomicFileWriter _writer;

  Directory get _dir =>
      Directory(p.join(_root.path, VaultPaths.workflowLayouts));

  File _fileFor(String workflowId) =>
      File(p.join(_dir.path, '$workflowId.json'));

  @override
  Future<WorkflowLayout?> load(String workflowId) async {
    final file = _fileFor(workflowId);
    if (!await file.exists()) {
      return null;
    }
    final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    if (json['schemaVersion'] != 1) {
      throw StateError('不支持的 layout schema：${json['schemaVersion']}');
    }
    final positionsRaw = json['positions'] as Map<String, dynamic>? ?? {};
    final positions = <String, CanvasPoint>{};
    final sortedKeys = positionsRaw.keys.toList()..sort();
    for (final key in sortedKeys) {
      final point = positionsRaw[key] as Map<String, dynamic>;
      positions[key] = CanvasPoint(
        (point['x'] as num).toDouble(),
        (point['y'] as num).toDouble(),
      );
    }
    final viewportRaw = json['viewport'] as Map<String, dynamic>? ?? {};
    final collapsed = ((json['collapsedNodeIds'] as List?) ?? const [])
        .map((e) => e.toString())
        .toSet();
    return WorkflowLayout(
      workflowId: json['workflowId'] as String? ?? workflowId,
      positions: positions,
      viewport: WorkflowViewport(
        offsetX: (viewportRaw['offsetX'] as num?)?.toDouble() ?? 0,
        offsetY: (viewportRaw['offsetY'] as num?)?.toDouble() ?? 0,
        scale: (viewportRaw['scale'] as num?)?.toDouble() ?? 1,
      ),
      collapsedNodeIds: collapsed,
    );
  }

  @override
  Future<void> save(WorkflowLayout layout) async {
    await _dir.create(recursive: true);
    final keys = layout.positions.keys.toList()..sort();
    final positions = <String, Object>{};
    for (final key in keys) {
      final point = layout.positions[key]!;
      positions[key] = {'x': point.x, 'y': point.y};
    }
    final collapsed = layout.collapsedNodeIds.toList()..sort();
    final payload = <String, Object?>{
      'schemaVersion': 1,
      'workflowId': layout.workflowId,
      'positions': positions,
      'viewport': {
        'offsetX': layout.viewport.offsetX,
        'offsetY': layout.viewport.offsetY,
        'scale': layout.viewport.scale,
      },
      'collapsedNodeIds': collapsed,
    };
    await _writer.writeString(
      _fileFor(layout.workflowId),
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  @override
  Future<void> delete(String workflowId) async {
    final file = _fileFor(workflowId);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
