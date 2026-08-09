import 'dart:convert';
import 'dart:io';

import 'package:ai_workbench/features/mcp/data/mcp_repository.dart';
import 'package:ai_workbench/features/mcp/domain/mcp_document.dart';
import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Persists MCP JSON files under `mcp/` and metadata under
/// `.ai-workbench/resources/mcp-metadata.json` (not inside the config JSON).
class FileMcpRepository implements McpRepository {
  FileMcpRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now,
       _metadataFile = File(
         p.join(
           vaultRoot.path,
           VaultPaths.resourceMetadata,
           'mcp-metadata.json',
         ),
       );

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final String Function() _idFactory;
  final DateTime Function() _clock;
  final File _metadataFile;

  Directory get _mcpDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.mcp)),
  );

  @override
  Future<McpDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String jsonText = '{\n  "mcpServers": {}\n}\n',
  }) async {
    await _mcpDir.create(recursive: true);
    final relativePath = await _allocateRelativePath(title);
    final document = McpDocument(
      id: _idFactory(),
      title: title,
      description: description,
      tags: tags,
      jsonText: jsonText,
      relativePath: relativePath,
    );
    return save(document);
  }

  @override
  Future<McpDocument> read(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    final jsonText = await file.readAsString();
    final meta = await _readMetadataEntry(relativePath);
    return McpDocument(
      id: meta?['id'] as String? ?? relativePath,
      title:
          meta?['title'] as String? ?? p.basenameWithoutExtension(relativePath),
      description: meta?['description'] as String? ?? '',
      tags: _stringList(meta?['tags']),
      jsonText: jsonText,
      relativePath: relativePath,
    );
  }

  @override
  Future<McpDocument> save(McpDocument document) async {
    final file = File(p.join(_vaultRoot.path, document.relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, document.jsonText);
    await _writeMetadataEntry(document);
    return document;
  }

  @override
  Future<McpDocument> duplicate(String relativePath) async {
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
      throw StateError('MCP 配置不存在：$relativePath');
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
    final base = slugifyMcpTitle(title);
    var candidate = 'mcp/$base.json';
    var index = 2;
    while (await File(p.join(_vaultRoot.path, candidate)).exists()) {
      candidate = 'mcp/$base-$index.json';
      index += 1;
    }
    return candidate;
  }

  Future<Map<String, Object?>?> _readMetadataEntry(String relativePath) async {
    final root = await _loadMetadataRoot();
    final documents = root['documents'];
    if (documents is! Map<String, Object?>) {
      return null;
    }
    final byPath = documents[relativePath];
    if (byPath is Map<String, Object?>) {
      return byPath;
    }
    if (byPath is Map) {
      return byPath.map((key, value) => MapEntry('$key', value));
    }
    return null;
  }

  Future<void> _writeMetadataEntry(McpDocument document) async {
    final root = await _loadMetadataRoot();
    final documents = Map<String, Object?>.from(
      (root['documents'] as Map<String, Object?>?) ?? const {},
    );
    documents[document.relativePath] = {
      'id': document.id,
      'title': document.title,
      'description': document.description,
      'tags': document.tags,
    };
    root['documents'] = documents;
    root['version'] = 1;
    await _metadataFile.parent.create(recursive: true);
    await _writer.writeString(
      _metadataFile,
      '${const JsonEncoder.withIndent('  ').convert(root)}\n',
    );
  }

  Future<Map<String, Object?>> _loadMetadataRoot() async {
    if (!await _metadataFile.exists()) {
      return <String, Object?>{'version': 1, 'documents': <String, Object?>{}};
    }
    try {
      final decoded = jsonDecode(await _metadataFile.readAsString());
      if (decoded is Map<String, Object?>) {
        return Map<String, Object?>.from(decoded);
      }
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value));
      }
    } on FormatException {
      // Replace unreadable metadata with a fresh store.
    }
    return <String, Object?>{'version': 1, 'documents': <String, Object?>{}};
  }

  List<String> _stringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }
}

String slugifyMcpTitle(String title) {
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
  return slug.isEmpty ? 'mcp' : slug;
}
