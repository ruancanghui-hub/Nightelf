import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

class SkillFixture {
  SkillFixture(this.root, this.directory);

  final Directory root;
  final Directory directory;

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

/// Builds a temporary SKILL source folder.
///
/// [entries] keys are paths relative to the skill folder. String values write
/// UTF-8 text; `List<int>` values write raw bytes.
Future<SkillFixture> skillFixture(
  Map<String, Object> entries, {
  String name = 'apple-design',
}) async {
  final root = await Directory.systemTemp.createTemp('nightelf-skill-src-');
  final directory = Directory(p.join(root.path, name));
  await directory.create(recursive: true);

  for (final entry in entries.entries) {
    final target = File(p.join(directory.path, entry.key));
    await target.parent.create(recursive: true);
    final value = entry.value;
    if (value is String) {
      await target.writeAsString(value);
    } else if (value is List<int>) {
      await target.writeAsBytes(Uint8List.fromList(value));
    } else {
      throw ArgumentError('Unsupported fixture value for ${entry.key}: $value');
    }
  }

  return SkillFixture(root, directory);
}
