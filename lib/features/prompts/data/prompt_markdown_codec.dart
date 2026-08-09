import 'dart:convert';

import 'package:ai_workbench/features/prompts/domain/prompt_document.dart';
import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';

class PromptMarkdownCodec {
  const PromptMarkdownCodec();

  PromptDocument decode(String text, String relativePath) {
    final document = const FrontMatterReader().read(text);
    final metadata = document.metadata;
    final tags = metadata['tags'];
    return PromptDocument(
      id: metadata['id'] is String ? metadata['id'] as String : '',
      title: metadata['title'] is String ? metadata['title'] as String : '',
      description: metadata['description'] is String
          ? metadata['description'] as String
          : '',
      tags: tags is List
          ? tags.whereType<String>().toList(growable: false)
          : const [],
      body: document.body,
      relativePath: relativePath,
    );
  }

  String encode(PromptDocument document) {
    final tags = document.tags.map(jsonEncode).join(', ');
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${jsonEncode(document.id)}')
      ..writeln('title: ${jsonEncode(document.title)}')
      ..writeln('description: ${jsonEncode(document.description)}')
      ..writeln('tags: [$tags]')
      ..writeln('---')
      ..write(document.body);
    return buffer.toString();
  }
}
