import 'dart:convert';

import 'package:ai_workbench/features/launchers/domain/launcher_document.dart';
import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';

class LauncherMarkdownCodec {
  const LauncherMarkdownCodec();

  LauncherDocument decode(String text, String relativePath) {
    final document = const FrontMatterReader().read(text);
    final metadata = document.metadata;
    return LauncherDocument(
      id: metadata['id'] is String ? metadata['id'] as String : '',
      title: metadata['title'] is String ? metadata['title'] as String : '',
      scriptPath: metadata['scriptPath'] is String
          ? metadata['scriptPath'] as String
          : '',
      relativePath: relativePath,
    );
  }

  String encode(LauncherDocument document) {
    final buffer = StringBuffer()
      ..writeln('---')
      ..writeln('id: ${jsonEncode(document.id)}')
      ..writeln('title: ${jsonEncode(document.title)}')
      ..writeln('scriptPath: ${jsonEncode(document.scriptPath)}')
      ..writeln('---');
    return buffer.toString();
  }
}
