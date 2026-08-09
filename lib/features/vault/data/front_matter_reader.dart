import 'dart:collection';

import 'package:yaml/yaml.dart';

class FrontMatterDocument {
  FrontMatterDocument({
    required Map<String, Object?> metadata,
    required this.body,
  }) : metadata = UnmodifiableMapView(metadata);

  final Map<String, Object?> metadata;
  final String body;
}

class FrontMatterReader {
  const FrontMatterReader();

  static final _frontMatter = RegExp(
    r'^---[ \t]*\r?\n([\s\S]*?)^---[ \t]*(?:\r?\n|$)',
    multiLine: true,
  );

  FrontMatterDocument read(String text) {
    final match = _frontMatter.firstMatch(text);
    if (match == null) {
      return FrontMatterDocument(metadata: const {}, body: text);
    }

    final yaml = loadYaml(match.group(1)!);
    return FrontMatterDocument(
      metadata: yaml is YamlMap ? _stringKeyedMap(yaml) : const {},
      body: text.substring(match.end),
    );
  }
}

Map<String, Object?> _stringKeyedMap(YamlMap source) {
  final result = <String, Object?>{};
  for (final entry in source.entries) {
    if (entry.key is String) {
      result[entry.key as String] = _plainValue(entry.value);
    }
  }
  return result;
}

Object? _plainValue(Object? value) => switch (value) {
  YamlMap() => _stringKeyedMap(value),
  YamlList() => List<Object?>.unmodifiable(value.map(_plainValue)),
  _ => value,
};
