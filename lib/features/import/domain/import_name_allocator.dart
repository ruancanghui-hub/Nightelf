import 'dart:io';

import 'package:path/path.dart' as p;

class ImportNameAllocator {
  const ImportNameAllocator();

  Future<String> nextAvailable(String directory, String basename) async {
    final preferred = File(p.join(directory, basename));
    final preferredDir = Directory(p.join(directory, basename));
    if (!await preferred.exists() && !await preferredDir.exists()) {
      return basename;
    }

    final stem = p.basenameWithoutExtension(basename);
    final extension = p.extension(basename);
    var index = 2;
    while (true) {
      final candidate = '$stem $index$extension';
      final file = File(p.join(directory, candidate));
      final dir = Directory(p.join(directory, candidate));
      if (!await file.exists() && !await dir.exists()) {
        return candidate;
      }
      index += 1;
    }
  }
}
