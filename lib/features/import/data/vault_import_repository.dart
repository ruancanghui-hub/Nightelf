import 'dart:io';

import 'package:ai_workbench/features/import/domain/import_name_allocator.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/import/domain/import_result.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

typedef CopyHandler =
    Future<void> Function({
      required String sourcePath,
      required String destinationPath,
      required bool isDirectory,
    });

class VaultImportRepository {
  VaultImportRepository({
    ImportNameAllocator? allocator,
    CopyHandler? copyHandler,
    String Function()? tempIdFactory,
  }) : _allocator = allocator ?? const ImportNameAllocator(),
       _copyHandler = copyHandler ?? _defaultCopy,
       _tempIdFactory = tempIdFactory ?? (() => const Uuid().v4());

  final ImportNameAllocator _allocator;
  final CopyHandler _copyHandler;
  final String Function() _tempIdFactory;

  Future<ImportResult> importItem(
    VaultHandle vault,
    ImportPlanItem item,
  ) async {
    final type = item.selectedType;
    if (!item.isSelected) {
      return ImportResult(item: item, succeeded: false, failureReason: '该项未选中');
    }
    if (type == null) {
      return ImportResult(
        item: item,
        succeeded: false,
        failureReason: '请先选择资源类型',
      );
    }

    if (type == ResourceType.skill) {
      final skillError = await _validateSkillSource(item);
      if (skillError != null) {
        return ImportResult(
          item: item,
          succeeded: false,
          failureReason: skillError,
        );
      }
    }

    final destinationDir = Directory(
      p.join(vault.root.path, VaultPaths.directoryFor(type)),
    );
    await destinationDir.create(recursive: true);

    final basename = await _allocator.nextAvailable(
      destinationDir.path,
      item.targetBasename,
    );
    final finalPath = p.join(destinationDir.path, basename);
    final tempPath = p.join(
      destinationDir.path,
      '.importing-${_tempIdFactory()}-$basename',
    );

    try {
      final sourceType = await FileSystemEntity.type(
        item.candidate.sourcePath,
        followLinks: false,
      );
      if (sourceType == FileSystemEntityType.link) {
        return ImportResult(
          item: item,
          succeeded: false,
          failureReason: '不支持导入符号链接',
        );
      }

      await _copyHandler(
        sourcePath: item.candidate.sourcePath,
        destinationPath: tempPath,
        isDirectory: item.candidate.isDirectory,
      );

      if (item.candidate.isDirectory) {
        await Directory(tempPath).rename(finalPath);
      } else {
        await File(tempPath).rename(finalPath);
      }

      return ImportResult(
        item: item.copyWith(targetBasename: basename),
        resourcePath: finalPath,
        succeeded: true,
      );
    } catch (error) {
      await _cleanup(tempPath);
      await _cleanup(finalPath);
      return ImportResult(
        item: item,
        succeeded: false,
        failureReason: '导入失败：$error',
      );
    }
  }

  static Future<void> _defaultCopy({
    required String sourcePath,
    required String destinationPath,
    required bool isDirectory,
  }) async {
    if (isDirectory) {
      await _copyDirectory(Directory(sourcePath), Directory(destinationPath));
    } else {
      await File(sourcePath).copy(destinationPath);
    }
  }

  static Future<void> _copyDirectory(
    Directory source,
    Directory destination,
  ) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: false,
      followLinks: false,
    )) {
      final name = p.basename(entity.path);
      final targetPath = p.join(destination.path, name);
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type == FileSystemEntityType.link) {
        throw StateError('目录内包含符号链接: ${entity.path}');
      }
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(targetPath));
      } else if (entity is File) {
        await entity.copy(targetPath);
      }
    }
  }

  Future<void> _cleanup(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    if (type == FileSystemEntityType.directory) {
      final dir = Directory(path);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } else if (type == FileSystemEntityType.file) {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  Future<String?> _validateSkillSource(ImportPlanItem item) async {
    final sourcePath = item.candidate.sourcePath;
    final sourceType = await FileSystemEntity.type(
      sourcePath,
      followLinks: false,
    );
    if (sourceType == FileSystemEntityType.file) {
      return 'SKILL 必须导入文件夹（含根级 SKILL.md），不能只导入单个文件';
    }
    if (sourceType != FileSystemEntityType.directory) {
      return 'SKILL 源路径无效';
    }
    final entry = File(p.join(sourcePath, 'SKILL.md'));
    if (!await entry.exists()) {
      return 'SKILL 文件夹必须包含根级 SKILL.md，否则无法出现在列表中';
    }
    if (!item.candidate.isDirectory) {
      return 'SKILL 必须作为文件夹导入';
    }
    return null;
  }
}

String defaultBasenameFor(ImportPlanItem item, ResourceType type) {
  final sourceName = p.basename(item.candidate.sourcePath);
  if (type == ResourceType.skill) {
    return sourceName;
  }
  if (type == ResourceType.link && !sourceName.toLowerCase().endsWith('.md')) {
    final stem = p.basenameWithoutExtension(sourceName);
    return '$stem.md';
  }
  return sourceName;
}
