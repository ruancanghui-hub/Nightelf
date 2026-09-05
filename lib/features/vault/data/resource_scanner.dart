import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';
import 'package:ai_workbench/features/vault/data/resource_identity_store.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:path/path.dart' as p;

typedef ResourceIdentityStoreFactory =
    ResourceIdentityStore Function(Directory vaultRoot);

class ResourceScanner {
  ResourceScanner({ResourceIdentityStoreFactory? identityStoreFactory})
    : _identityStoreFactory =
          identityStoreFactory ?? ((root) => ResourceIdentityStore(root));

  final FrontMatterReader _reader = const FrontMatterReader();
  final ResourceIdentityStoreFactory _identityStoreFactory;

  Future<List<ResourceRecord>> scan(VaultHandle vault) async {
    final rootPath = await vault.root.resolveSymbolicLinks();
    final identityStore = _identityStoreFactory(vault.root);
    final candidates = <_ResourceCandidate>[];

    for (final type in ResourceType.values) {
      if (type == ResourceType.skill) {
        candidates.addAll(await _skillCandidates(vault.root, rootPath));
      } else {
        candidates.addAll(await _fileCandidates(vault.root, rootPath, type));
      }
    }

    final records = <ResourceRecord>[];
    for (final candidate in candidates) {
      records.add(await _readRecord(candidate, identityStore));
    }
    records.sort(_compareRecords);
    return records;
  }

  Future<List<_ResourceCandidate>> _skillCandidates(
    Directory vaultRoot,
    String rootPath,
  ) async {
    final skills = Directory(
      p.join(vaultRoot.path, VaultPaths.directoryFor(ResourceType.skill)),
    );
    if (!await skills.exists()) {
      return const [];
    }

    final candidates = <_ResourceCandidate>[];
    await for (final entity in skills.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (_isIgnoredName(name)) {
        continue;
      }
      final directoryPath = await _safeDirectoryPath(entity, rootPath);
      if (directoryPath == null) {
        continue;
      }
      final entryFile = await _safeFile(
        File(p.join(directoryPath, 'SKILL.md')),
        rootPath,
      );
      if (entryFile == null) {
        continue;
      }
      candidates.add(
        _ResourceCandidate(
          type: ResourceType.skill,
          relativePath: p.posix.join('skills', name),
          titleFallback: name,
          source: entryFile,
        ),
      );
    }
    return candidates;
  }

  Future<List<_ResourceCandidate>> _fileCandidates(
    Directory vaultRoot,
    String rootPath,
    ResourceType type,
  ) async {
    final directoryName = VaultPaths.directoryFor(type);
    final directory = Directory(p.join(vaultRoot.path, directoryName));
    if (!await directory.exists()) {
      return const [];
    }
    final candidates = <_ResourceCandidate>[];
    await _collectFiles(
      directory,
      directoryName,
      rootPath,
      type,
      candidates,
      <String>{rootPath, await directory.resolveSymbolicLinks()},
    );
    return candidates;
  }

  Future<void> _collectFiles(
    Directory directory,
    String logicalDirectory,
    String rootPath,
    ResourceType type,
    List<_ResourceCandidate> candidates,
    Set<String> ancestorPaths,
  ) async {
    await for (final entity in directory.list(followLinks: false)) {
      final name = p.basename(entity.path);
      if (_isIgnoredName(name)) {
        continue;
      }
      final relativePath = p.posix.join(logicalDirectory, name);
      final entityType = await FileSystemEntity.type(
        entity.path,
        followLinks: false,
      );
      if (entityType == FileSystemEntityType.file) {
        if (_isSupported(type, name)) {
          candidates.add(
            _ResourceCandidate(
              type: type,
              relativePath: relativePath,
              titleFallback: p.basenameWithoutExtension(name),
              source: File(entity.path),
            ),
          );
        }
        continue;
      }
      if (entityType == FileSystemEntityType.directory) {
        final resolved = await Directory(entity.path).resolveSymbolicLinks();
        await _descend(
          Directory(entity.path),
          resolved,
          relativePath,
          rootPath,
          type,
          candidates,
          ancestorPaths,
        );
        continue;
      }
      if (entityType != FileSystemEntityType.link) {
        continue;
      }

      final resolved = await _safeResolvedPath(entity.path, rootPath);
      if (resolved == null) {
        continue;
      }
      final targetType = await FileSystemEntity.type(resolved);
      if (targetType == FileSystemEntityType.file && _isSupported(type, name)) {
        candidates.add(
          _ResourceCandidate(
            type: type,
            relativePath: relativePath,
            titleFallback: p.basenameWithoutExtension(name),
            source: File(resolved),
          ),
        );
      } else if (targetType == FileSystemEntityType.directory) {
        await _descend(
          Directory(resolved),
          resolved,
          relativePath,
          rootPath,
          type,
          candidates,
          ancestorPaths,
        );
      }
    }
  }

  Future<void> _descend(
    Directory directory,
    String resolvedPath,
    String logicalDirectory,
    String rootPath,
    ResourceType type,
    List<_ResourceCandidate> candidates,
    Set<String> ancestorPaths,
  ) async {
    if (!_isInsideRoot(rootPath, resolvedPath) ||
        _isIgnoredResolvedPath(rootPath, resolvedPath) ||
        ancestorPaths.contains(resolvedPath)) {
      return;
    }
    await _collectFiles(
      directory,
      logicalDirectory,
      rootPath,
      type,
      candidates,
      {...ancestorPaths, resolvedPath},
    );
  }

  Future<ResourceRecord> _readRecord(
    _ResourceCandidate candidate,
    ResourceIdentityStore identityStore,
  ) async {
    final text = utf8.decode(
      await candidate.source.readAsBytes(),
      allowMalformed: true,
    );
    FrontMatterDocument document;
    try {
      document = _reader.read(text);
    } on FormatException {
      document = FrontMatterDocument(metadata: const {}, body: text);
    }
    final title =
        _nonEmptyString(document.metadata['title']) ?? candidate.titleFallback;
    var description = _nonEmptyString(document.metadata['description']) ?? '';
    final scriptPath = _nonEmptyString(document.metadata['scriptPath']);
    if (candidate.type == ResourceType.launcher && scriptPath != null) {
      description = scriptPath;
    }
    final tags = _tags(document.metadata['tags']);
    final id = await identityStore.resolve(
      type: candidate.type,
      relativePath: candidate.relativePath,
      embeddedId: _nonEmptyString(document.metadata['id']),
    );
    final stat = await candidate.source.stat();
    final searchableParts = <String>[
      title,
      description,
      ...tags,
      document.body,
      ?scriptPath,
    ].where((part) => part.isNotEmpty);

    return ResourceRecord(
      id: id,
      type: candidate.type,
      relativePath: candidate.relativePath,
      title: title,
      description: description,
      tags: tags,
      modifiedAt: stat.modified,
      searchableText: searchableParts.join(' '),
    );
  }
}

class _ResourceCandidate {
  const _ResourceCandidate({
    required this.type,
    required this.relativePath,
    required this.titleFallback,
    required this.source,
  });

  final ResourceType type;
  final String relativePath;
  final String titleFallback;
  final File source;
}

int _compareRecords(ResourceRecord left, ResourceRecord right) {
  final typeOrder = left.type.index.compareTo(right.type.index);
  if (typeOrder != 0) {
    return typeOrder;
  }
  final titleOrder = left.title.toLowerCase().compareTo(
    right.title.toLowerCase(),
  );
  if (titleOrder != 0) {
    return titleOrder;
  }
  return left.relativePath.compareTo(right.relativePath);
}

bool _isSupported(ResourceType type, String name) {
  final extension = p.extension(name).toLowerCase();
  return switch (type) {
    ResourceType.prompt => extension == '.md',
    ResourceType.skill => false,
    ResourceType.mcp => extension == '.json',
    ResourceType.link => extension == '.md',
    ResourceType.workflow => const {
      '.mmd',
      '.md',
      '.yaml',
      '.yml',
      '.json',
    }.contains(extension),
    ResourceType.launcher => extension == '.md',
  };
}

bool _isIgnoredName(String name) =>
    name.startsWith('.') ||
    name.endsWith('.nightelf-tmp') ||
    name.endsWith('~') ||
    name.endsWith('.tmp');

bool _isInsideRoot(String rootPath, String targetPath) =>
    p.equals(rootPath, targetPath) || p.isWithin(rootPath, targetPath);

bool _isIgnoredResolvedPath(String rootPath, String targetPath) {
  final relative = p.relative(targetPath, from: rootPath);
  return p.split(relative).any((segment) => segment.startsWith('.'));
}

Future<String?> _safeResolvedPath(String path, String rootPath) async {
  try {
    final resolved = await File(path).resolveSymbolicLinks();
    if (!_isInsideRoot(rootPath, resolved) ||
        _isIgnoredResolvedPath(rootPath, resolved)) {
      return null;
    }
    return resolved;
  } on FileSystemException {
    return null;
  }
}

Future<String?> _safeDirectoryPath(
  FileSystemEntity entity,
  String rootPath,
) async {
  final resolved = await _safeResolvedPath(entity.path, rootPath);
  if (resolved == null ||
      await FileSystemEntity.type(resolved) != FileSystemEntityType.directory) {
    return null;
  }
  return resolved;
}

Future<File?> _safeFile(File file, String rootPath) async {
  final resolved = await _safeResolvedPath(file.path, rootPath);
  if (resolved == null ||
      await FileSystemEntity.type(resolved) != FileSystemEntityType.file) {
    return null;
  }
  return File(resolved);
}

String? _nonEmptyString(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return value.trim();
}

List<String> _tags(Object? value) {
  final values = switch (value) {
    String() => <Object?>[value],
    List<Object?>() => value,
    _ => const <Object?>[],
  };
  return values
      .whereType<Object>()
      .map((tag) => tag.toString().trim())
      .where((tag) => tag.isNotEmpty)
      .toList(growable: false);
}
