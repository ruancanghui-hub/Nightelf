import 'dart:io';

import 'package:ai_workbench/features/launchers/data/launcher_markdown_codec.dart';
import 'package:ai_workbench/features/launchers/data/launcher_repository.dart';
import 'package:ai_workbench/features/launchers/domain/launcher_document.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileLauncherRepository implements LauncherRepository {
  FileLauncherRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    LauncherMarkdownCodec? codec,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _codec = codec ?? const LauncherMarkdownCodec(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final LauncherMarkdownCodec _codec;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Directory get _launchersDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.launcher)),
  );

  @override
  Future<LauncherDocument> create({
    required String title,
    required String scriptPath,
  }) async {
    await _launchersDir.create(recursive: true);
    final relativePath = await _allocateRelativePath(title);
    return save(
      LauncherDocument(
        id: _idFactory(),
        title: title,
        scriptPath: scriptPath,
        relativePath: relativePath,
      ),
    );
  }

  @override
  Future<LauncherDocument> read(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    return _codec.decode(await file.readAsString(), relativePath);
  }

  @override
  Future<LauncherDocument> save(LauncherDocument document) async {
    final file = File(p.join(_vaultRoot.path, document.relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, _codec.encode(document));
    return document;
  }

  @override
  Future<LauncherDocument> rename(
    String relativePath, {
    required String title,
    String? scriptPath,
  }) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('标题不能为空');
    }
    final source = await read(relativePath);
    final nextPath = await _allocateRelativePath(
      trimmed,
      excluding: relativePath,
    );
    final renamed = source.copyWith(
      title: trimmed,
      scriptPath: scriptPath ?? source.scriptPath,
      relativePath: nextPath,
    );
    await save(renamed);
    if (nextPath != relativePath) {
      final oldFile = File(p.join(_vaultRoot.path, relativePath));
      if (await oldFile.exists()) {
        await oldFile.delete();
      }
    }
    return renamed;
  }

  @override
  Future<List<LauncherDocument>> listAll() async {
    if (!await _launchersDir.exists()) {
      return const [];
    }
    final documents = <LauncherDocument>[];
    await for (final entity in _launchersDir.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (p.extension(entity.path).toLowerCase() != '.md') {
        continue;
      }
      final relative = p.relative(entity.path, from: _vaultRoot.path);
      documents.add(await read(relative));
    }
    documents.sort((a, b) => a.title.compareTo(b.title));
    return documents;
  }

  @override
  Future<String> moveToTrash(String relativePath) async {
    final source = File(p.join(_vaultRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('启动器不存在：$relativePath');
    }
    final stamp = _clock().toUtc().toIso8601String().replaceAll(':', '-');
    final destination = File(
      p.join(
        _vaultRoot.path,
        VaultPaths.localRoot,
        'trash',
        stamp,
        relativePath,
      ),
    );
    await destination.parent.create(recursive: true);
    await source.rename(destination.path);
    return p.relative(destination.path, from: _vaultRoot.path);
  }

  Future<String> _allocateRelativePath(
    String title, {
    String? excluding,
  }) async {
    final base = slugifyLauncherTitle(title);
    var candidate = 'launchers/$base.md';
    var index = 2;
    while (true) {
      if (candidate == excluding) {
        return candidate;
      }
      if (!await File(p.join(_vaultRoot.path, candidate)).exists()) {
        return candidate;
      }
      candidate = 'launchers/$base-$index.md';
      index += 1;
    }
  }
}

String slugifyLauncherTitle(String title) {
  final buffer = StringBuffer();
  var pendingDash = false;
  for (final rune in title.trim().runes) {
    final char = String.fromCharCode(rune);
    final isAsciiLetter =
        (rune >= 65 && rune <= 90) || (rune >= 97 && rune <= 122);
    final isDigit = rune >= 48 && rune <= 57;
    final isChinese = rune >= 0x4E00 && rune <= 0x9FFF;
    if (isAsciiLetter || isDigit || isChinese) {
      if (pendingDash && buffer.isNotEmpty) {
        buffer.write('-');
      }
      pendingDash = false;
      buffer.write(isAsciiLetter ? char.toLowerCase() : char);
    } else {
      pendingDash = buffer.isNotEmpty;
    }
  }
  final slug = buffer.toString();
  return slug.isEmpty ? 'launcher' : slug;
}
