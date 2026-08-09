import 'dart:convert';

import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';
import 'package:ai_workbench/features/workflows/domain/workflow_document.dart';
import 'package:path/path.dart' as p;

class WorkflowMarkdownCodec {
  const WorkflowMarkdownCodec();

  String encode(WorkflowDocument document) {
    final ext = document.extension.toLowerCase();
    if (ext == '.json' || ext == '.yaml' || ext == '.yml') {
      return document.source.endsWith('\n')
          ? document.source
          : '${document.source}\n';
    }
    final tags = document.tags.map(jsonEncode).join(', ');
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${jsonEncode(document.id)}')
      ..writeln('title: ${jsonEncode(document.title)}')
      ..writeln('description: ${jsonEncode(document.description)}')
      ..writeln('tags: [$tags]')
      ..writeln('---')
      ..write(document.source);
    if (!document.source.endsWith('\n')) {
      buffer.writeln();
    }
    return buffer.toString();
  }

  WorkflowDocument decode(String text, String relativePath) {
    final extension = p.extension(relativePath).toLowerCase();
    if (extension == '.json' || extension == '.yaml' || extension == '.yml') {
      return WorkflowDocument(
        id: _fallbackId(relativePath),
        title: _titleFromPath(relativePath),
        source: text,
        extension: extension,
        relativePath: relativePath,
      );
    }

    final parsed = const FrontMatterReader().read(text);
    final metadata = parsed.metadata;
    final tags = metadata['tags'];
    final id = metadata['id'] is String && (metadata['id'] as String).isNotEmpty
        ? metadata['id'] as String
        : _fallbackId(relativePath);
    final title =
        metadata['title'] is String && (metadata['title'] as String).isNotEmpty
        ? metadata['title'] as String
        : _titleFromPath(relativePath);
    return WorkflowDocument(
      id: id,
      title: title,
      description: metadata['description'] is String
          ? metadata['description'] as String
          : '',
      tags: tags is List
          ? tags.whereType<String>().toList(growable: false)
          : const [],
      source: parsed.body,
      extension: extension.isEmpty ? '.mmd' : extension,
      relativePath: relativePath,
    );
  }

  String _titleFromPath(String relativePath) {
    return p.basenameWithoutExtension(relativePath);
  }

  String _fallbackId(String relativePath) =>
      relativePath.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '-');
}
