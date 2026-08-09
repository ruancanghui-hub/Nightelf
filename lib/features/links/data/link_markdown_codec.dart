import 'dart:convert';

import 'package:ai_workbench/features/links/domain/link_document.dart';
import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';

class LinkMarkdownCodec {
  const LinkMarkdownCodec();

  LinkDocument decode(String text, String relativePath) {
    final document = const FrontMatterReader().read(text);
    final metadata = document.metadata;
    final tags = metadata['tags'];
    final url = metadata['url'];
    return LinkDocument(
      id: metadata['id'] is String ? metadata['id'] as String : '',
      title: metadata['title'] is String ? metadata['title'] as String : '',
      uri: Uri.parse(url is String ? url : ''),
      description: metadata['description'] is String
          ? metadata['description'] as String
          : '',
      tags: tags is List
          ? tags.whereType<String>().toList(growable: false)
          : const [],
      notes: document.body,
      relativePath: relativePath,
      floatingBubble: metadata['floatingBubble'] == true,
    );
  }

  String encode(LinkDocument document) {
    final tags = document.tags.map(jsonEncode).join(', ');
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${jsonEncode(document.id)}')
      ..writeln('title: ${jsonEncode(document.title)}')
      ..writeln('url: ${jsonEncode(document.uri.toString())}')
      ..writeln('description: ${jsonEncode(document.description)}')
      ..writeln('tags: [$tags]')
      ..writeln('floatingBubble: ${document.floatingBubble}')
      ..writeln('---')
      ..write(document.notes);
    return buffer.toString();
  }
}
