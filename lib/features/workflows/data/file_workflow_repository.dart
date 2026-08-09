import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:ai_workbench/features/workflows/data/workflow_markdown_codec.dart';
import 'package:ai_workbench/features/workflows/data/workflow_repository.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_document.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

class FileWorkflowRepository implements WorkflowRepository {
  FileWorkflowRepository({
    required Directory vaultRoot,
    AtomicFileWriter? writer,
    WorkflowMarkdownCodec? codec,
    String Function()? idFactory,
    DateTime Function()? clock,
  }) : _vaultRoot = vaultRoot,
       _writer = writer ?? AtomicFileWriter(),
       _codec = codec ?? const WorkflowMarkdownCodec(),
       _idFactory = idFactory ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;

  final Directory _vaultRoot;
  final AtomicFileWriter _writer;
  final WorkflowMarkdownCodec _codec;
  final String Function() _idFactory;
  final DateTime Function() _clock;

  Directory get _workflowsDir => Directory(
    p.join(_vaultRoot.path, VaultPaths.directoryFor(ResourceType.workflow)),
  );

  static const defaultSource = '''flowchart TD
start[开始] --> end[结束]
''';

  @override
  Future<WorkflowDocument> create({
    required String title,
    String source = '',
    String extension = '.mmd',
    String description = '',
    List<String> tags = const [],
  }) async {
    await _workflowsDir.create(recursive: true);
    final normalizedExt = extension.startsWith('.')
        ? extension.toLowerCase()
        : '.$extension';
    final relativePath = await _allocateRelativePath(title, normalizedExt);
    final document = WorkflowDocument(
      id: _idFactory(),
      title: title,
      source: source.isEmpty ? defaultSource : source,
      extension: normalizedExt,
      relativePath: relativePath,
      description: description,
      tags: tags,
    );
    return save(document);
  }

  @override
  Future<WorkflowDocument> read(String relativePath) async {
    final file = File(p.join(_vaultRoot.path, relativePath));
    return _codec.decode(await file.readAsString(), relativePath);
  }

  @override
  Future<WorkflowDocument> save(WorkflowDocument document) async {
    final file = File(p.join(_vaultRoot.path, document.relativePath));
    await file.parent.create(recursive: true);
    await _writer.writeString(file, _codec.encode(document));
    return document;
  }

  @override
  Future<WorkflowDocument> duplicate(String relativePath) async {
    final source = await read(relativePath);
    final title = '${source.title} 副本';
    final nextPath = await _allocateRelativePath(title, source.extension);
    return save(
      source.copyWith(id: _idFactory(), title: title, relativePath: nextPath),
    );
  }

  @override
  Future<String> moveToTrash(String relativePath) async {
    final source = File(p.join(_vaultRoot.path, relativePath));
    if (!await source.exists()) {
      throw StateError('Workflow 不存在：$relativePath');
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

  @override
  Future<WorkflowDocument> importFile({
    required String absolutePath,
    String? title,
  }) async {
    final sourceFile = File(absolutePath);
    if (!await sourceFile.exists()) {
      throw StateError('文件不存在：$absolutePath');
    }
    final extension = p.extension(absolutePath).toLowerCase();
    final allowed = {'.mmd', '.md', '.yaml', '.yml', '.json'};
    if (!allowed.contains(extension)) {
      throw StateError('不支持的 Workflow 扩展名：$extension');
    }
    final basename = p.basenameWithoutExtension(absolutePath);
    final documentTitle = (title == null || title.trim().isEmpty)
        ? basename
        : title.trim();
    final text = await sourceFile.readAsString();
    final decoded = _codec.decode(text, 'workflows/import-temp$extension');
    return create(
      title: documentTitle,
      source: decoded.source.isEmpty ? text : decoded.source,
      extension: extension,
      description: decoded.description,
      tags: decoded.tags,
    );
  }

  Future<String> _allocateRelativePath(String title, String extension) async {
    final base = slugifyWorkflowTitle(title);
    var candidate = 'workflows/$base$extension';
    var index = 2;
    while (await File(p.join(_vaultRoot.path, candidate)).exists()) {
      candidate = 'workflows/$base-$index$extension';
      index += 1;
    }
    return candidate;
  }
}

String slugifyWorkflowTitle(String title) {
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
  return slug.isEmpty ? 'workflow' : slug;
}
