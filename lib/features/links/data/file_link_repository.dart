import 'dart:io';

import 'package:ai_workbench/features/links/data/link_markdown_codec.dart';
import 'package:ai_workbench/features/links/data/link_repository.dart';
import 'package:ai_workbench/features/links/domain/link_document.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileLinkRepository implements LinkRepository {
  FileLinkRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    LinkMarkdownCodec? codec,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _codec = codec ?? const LinkMarkdownCodec(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final LinkMarkdownCodec _codec;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Directory get _linksDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.link)),
  );

  @override
  Future<LinkDocument> create({
    required String title,
    required Uri uri,
    String description = '',
    List<String> tags = const [],
    String notes = '',
  }) async {
    await _linksDir.create(recursive: true);
    final relativePath = await _allocateRelativePath(title);
    final document = LinkDocument(
      id: _idFactory(),
      title: title,
      uri: uri,
      description: description,
      tags: tags,
      notes: notes,
      relativePath: relativePath,
    );
    return save(document);
  }

  @override
  Future<LinkDocument> read(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    return _codec.decode(await file.readAsString(), relativePath);
  }

  @override
  Future<LinkDocument> save(LinkDocument document) async {
    final file = File(p.join(_vaultRoot.path, document.relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, _codec.encode(document));
    return document;
  }

  @override
  Future<LinkDocument> duplicate(String relativePath) async {
    final source = await read(relativePath);
    final title = '${source.title} 副本';
    final nextPath = await _allocateRelativePath(title);
    return save(
      source.copyWith(id: _idFactory(), title: title, relativePath: nextPath),
    );
  }

  @override
  Future<String> moveToTrash(String relativePath) async {
    final source = File(p.join(_vaultRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('链接不存在：$relativePath');
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
    final base = slugifyLinkTitle(title);
    var candidate = 'links/$base.md';
    var index = 2;
    while (await File(p.join(_vaultRoot.path, candidate)).exists()) {
      candidate = 'links/$base-$index.md';
      index += 1;
    }
    return candidate;
  }
}

String slugifyLinkTitle(String title) {
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
  return slug.isEmpty ? 'link' : slug;
}
