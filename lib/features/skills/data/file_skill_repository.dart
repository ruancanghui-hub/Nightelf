import 'dart:io';
import 'dart:typed_data';

import 'package:ai_workbench/features/skills/data/skill_repository.dart';
import 'package:ai_workbench/features/skills/domain/import_progress.dart';
import 'package:ai_workbench/features/skills/domain/skill_resource.dart';
import 'package:ai_workbench/features/skills/domain/skill_tree_node.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class SkillImportException implements Exception {
  const SkillImportException(this.message);

  final String message;

  @override
  String toString() => 'SkillImportException: $message';
}

class FileSkillRepository implements SkillRepository {
  FileSkillRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    String Function()? idFactory,
    DateTime Function()? clock,
    int chunkSizeBytes = 1024 * 1024,
    int largeFileThresholdBytes = 50 * 1024 * 1024,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now,
       _chunkSizeBytes = chunkSizeBytes,
       _largeFileThresholdBytes = largeFileThresholdBytes;

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final String Function() _idFactory;
  final DateTime Function() _clock;
  final int _chunkSizeBytes;
  final int _largeFileThresholdBytes;

  Directory get _skillsDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.skill)),
  );

  @override
  Stream<ImportProgress> importDirectory(
    Directory source, {
    ConfirmLargeFile? confirmLargeFile,
  }) async* {
    final vaultResolved = await _vaultRoot.resolveSymbolicLinks();
    if (!await source.exists()) {
      throw const SkillImportException('源目录不存在');
    }
    final sourceResolved = await source.resolveSymbolicLinks();
    if (sourceResolved == vaultResolved) {
      throw const SkillImportException('不能导入 Vault 根目录');
    }
    if (p.isWithin(sourceResolved, vaultResolved)) {
      throw const SkillImportException('导入目标位于源目录内部');
    }

    final entry = File(p.join(source.path, 'SKILL.md'));
    if (!await entry.exists()) {
      final packages = await _immediateSkillPackages(source);
      if (packages.isEmpty) {
        throw const SkillImportException('SKILL 目录必须包含根级 SKILL.md');
      }
      SkillResource? last;
      var copiedFiles = 0;
      var copiedBytes = 0;
      for (final package in packages) {
        await for (final progress in importDirectory(
          package,
          confirmLargeFile: confirmLargeFile,
        )) {
          copiedFiles = progress.copiedFiles;
          copiedBytes = progress.copiedBytes;
          yield ImportProgress(
            copiedFiles: copiedFiles,
            copiedBytes: copiedBytes,
            currentRelativePath:
                '${p.basename(package.path)}/${progress.currentRelativePath}',
            skill: progress.skill,
          );
          if (progress.skill != null) {
            last = progress.skill;
          }
        }
      }
      if (last != null) {
        yield ImportProgress(
          copiedFiles: copiedFiles,
          copiedBytes: copiedBytes,
          currentRelativePath: last.entryRelativePath,
          skill: last,
        );
      }
      return;
    }

    await _skillsDir.create(recursive: true);
    final folderName = await _allocateFolderName(p.basename(source.path));
    final destination = Directory(p.join(_skillsDir.path, folderName));
    await destination.create(recursive: true);

    var copiedFiles = 0;
    var copiedBytes = 0;
    SkillResource? skill;

    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p.relative(entity.path, from: source.path);
      final posixRelative = p.posix.joinAll(p.split(relative));

      if (entity is Link) {
        final target = await entity.resolveSymbolicLinks();
        if (!p.isWithin(sourceResolved, target) && target != sourceResolved) {
          throw SkillImportException('符号链接指向源目录之外：$posixRelative');
        }
        continue;
      }

      if (entity is Directory) {
        final dirTarget = Directory(p.join(destination.path, relative));
        await dirTarget.create(recursive: true);
        continue;
      }

      if (entity is! File) {
        continue;
      }

      final length = await entity.length();
      if (length > _largeFileThresholdBytes) {
        final confirm = confirmLargeFile;
        if (confirm == null || !await confirm(entity.path, length)) {
          throw SkillImportException('文件超过 50 MiB，已取消导入：$posixRelative');
        }
      }

      final destFile = File(p.join(destination.path, relative));
      await destFile.parent.create(recursive: true);
      await _copyInChunks(entity, destFile);
      copiedFiles += 1;
      copiedBytes += length;
      yield ImportProgress(
        copiedFiles: copiedFiles,
        copiedBytes: copiedBytes,
        currentRelativePath: posixRelative,
      );
    }

    skill = SkillResource(
      id: _idFactory(),
      title: folderName,
      relativeDirectory: p.posix.join('skills', folderName),
      entryRelativePath: p.posix.join('skills', folderName, 'SKILL.md'),
    );
    yield ImportProgress(
      copiedFiles: copiedFiles,
      copiedBytes: copiedBytes,
      currentRelativePath: 'SKILL.md',
      skill: skill,
    );
  }

  @override
  Future<SkillResource> read(String relativeDirectory) async {
    final directory = Directory(p.join(_vaultRoot.path, relativeDirectory));
    if (!await directory.exists()) {
      throw StateError('SKILL 目录不存在：$relativeDirectory');
    }
    final entry = File(p.join(directory.path, 'SKILL.md'));
    if (!await entry.exists()) {
      throw StateError('缺少 SKILL.md：$relativeDirectory');
    }
    return SkillResource(
      id: relativeDirectory,
      title: p.basename(relativeDirectory),
      relativeDirectory: relativeDirectory,
      entryRelativePath: p.posix.join(relativeDirectory, 'SKILL.md'),
    );
  }

  @override
  Future<List<SkillTreeNode>> listChildren(String relativeDirectory) async {
    final directory = Directory(p.join(_vaultRoot.path, relativeDirectory));
    if (!await directory.exists()) {
      return const [];
    }

    final nodes = <SkillTreeNode>[];
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith('.')) {
        continue;
      }
      final relativePath = p.posix.join(relativeDirectory, name);
      if (entity is Directory) {
        nodes.add(
          SkillTreeNode(
            name: name,
            relativePath: relativePath,
            isDirectory: true,
          ),
        );
      } else if (entity is File) {
        nodes.add(
          SkillTreeNode(
            name: name,
            relativePath: relativePath,
            isDirectory: false,
            childrenLoaded: true,
          ),
        );
      }
    }

    nodes.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return nodes;
  }

  @override
  Future<String> readTextFile(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    return file.readAsString();
  }

  @override
  Future<void> writeTextFile(String relativePath, String contents) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, contents);
  }

  @override
  Future<SkillResource> duplicate(String relativeDirectory) async {
    final source = await read(relativeDirectory);
    final baseName = '${source.title}-副本';
    final folderName = await _allocateFolderName(baseName);
    final sourceDir = Directory(p.join(_vaultRoot.path, relativeDirectory));
    final destination = Directory(p.join(_skillsDir.path, folderName));
    await _copyDirectory(sourceDir, destination);
    return SkillResource(
      id: _idFactory(),
      title: folderName,
      relativeDirectory: p.posix.join('skills', folderName),
      entryRelativePath: p.posix.join('skills', folderName, 'SKILL.md'),
    );
  }

  @override
  Future<String> moveToTrash(String relativeDirectory) async {
    final source = Directory(p.join(_vaultRoot.path, relativeDirectory));
    if (!await source.exists()) {
      throw StateError('SKILL 目录不存在：$relativeDirectory');
    }
    final stamp = _clock().toUtc().toIso8601String().replaceAll(':', '-');
    final destination = Directory(
      p.join(
        _vaultRoot.path,
        VaultPaths.localRoot,
        'trash',
        stamp,
        relativeDirectory,
      ),
    );
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    return p.relative(destination.path, from: _vaultRoot.path);
  }

  Future<String> _allocateFolderName(String preferred) async {
    var candidate = preferred;
    var index = 2;
    while (await Directory(p.join(_skillsDir.path, candidate)).exists()) {
      candidate = '$preferred-$index';
      index += 1;
    }
    return candidate;
  }

  Future<List<Directory>> _immediateSkillPackages(Directory root) async {
    final packages = <Directory>[];
    await for (final entity in root.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (name.startsWith('.')) {
        continue;
      }
      final type = await FileSystemEntity.type(entity.path, followLinks: false);
      if (type != FileSystemEntityType.directory) {
        continue;
      }
      if (await File(p.join(entity.path, 'SKILL.md')).exists()) {
        packages.add(Directory(entity.path));
      }
    }
    packages.sort(
      (a, b) => p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase()),
    );
    return packages;
  }

  Future<void> _copyInChunks(File source, File destination) async {
    final reader = await source.open(mode: FileMode.read);
    final writer = await destination.open(mode: FileMode.write);
    try {
      final buffer = Uint8List(_chunkSizeBytes);
      while (true) {
        final read = await reader.readInto(buffer);
        if (read <= 0) {
          break;
        }
        await writer.writeFrom(buffer, 0, read);
      }
    } finally {
      await reader.close();
      await writer.close();
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(
      recursive: true,
      followLinks: false,
    )) {
      final relative = p.relative(entity.path, from: source.path);
      final targetPath = p.join(destination.path, relative);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await _copyInChunks(entity, File(targetPath));
      }
    }
  }
}
