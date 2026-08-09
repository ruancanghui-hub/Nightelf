import 'dart:io';

import 'package:ai_workbench/features/prompts/data/prompt_markdown_codec.dart';
import 'package:ai_workbench/features/prompts/data/prompt_repository.dart';
import 'package:ai_workbench/features/prompts/domain/prompt_document.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FilePromptRepository implements PromptRepository {
  FilePromptRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    PromptMarkdownCodec? codec,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _codec = codec ?? const PromptMarkdownCodec(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final PromptMarkdownCodec _codec;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Directory get _promptsDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.prompt)),
  );

  @override
  Future<PromptDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String body = '',
  }) async {
    await _promptsDir.create(recursive: true);
    final relativePath = await _allocateRelativePath(title);
    final document = PromptDocument(
      id: _idFactory(),
      title: title,
      description: description,
      tags: tags,
      body: body,
      relativePath: relativePath,
    );
    return save(document);
  }

  @override
  Future<PromptDocument> read(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    final text = await file.readAsString();
    return _codec.decode(text, relativePath);
  }

  @override
  Future<PromptDocument> save(PromptDocument document) async {
    final file = File(p.join(_vaultRoot.path, document.relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, _codec.encode(document));
    return document;
  }

  @override
  Future<PromptDocument> duplicate(String relativePath) async {
    final source = await read(relativePath);
    final title = '${source.title} 副本';
    final nextPath = await _allocateRelativePath(title);
    final duplicate = source.copyWith(
      id: _idFactory(),
      title: title,
      relativePath: nextPath,
    );
    return save(duplicate);
  }

  @override
  Future<String> moveToTrash(String relativePath) async {
    final source = File(p.join(_vaultRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('提示词不存在：$relativePath');
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

  Future<String> _allocateRelativePath(String title) async {
    final base = slugifyPromptTitle(title);
    var candidate = 'prompts/$base.md';
    var index = 2;
    while (await File(p.join(_vaultRoot.path, candidate)).exists()) {
      candidate = 'prompts/$base-$index.md';
      index += 1;
    }
    return candidate;
  }
}

/// Lowercases ASCII letters, keeps Chinese characters, and collapses other
/// runs into `-`.
String slugifyPromptTitle(String title) {
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
  return slug.isEmpty ? 'prompt' : slug;
}
