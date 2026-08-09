import 'dart:io';

import 'package:path/path.dart' as p;

class ImportSourceFixture {
  ImportSourceFixture(this.root);

  final Directory root;

  static Future<ImportSourceFixture> create() async {
    final root = await Directory.systemTemp.createTemp('nightelf-import-src-');
    return ImportSourceFixture(root);
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }

  Future<File> file(String name, [String contents = 'content']) async {
    final file = File(p.join(root.path, name));
    await file.parent.create(recursive: true);
    await file.writeAsString(contents);
    return file;
  }

  Future<Directory> skillDirectory(String name) async {
    final dir = Directory(p.join(root.path, name));
    await dir.create(recursive: true);
    await File(p.join(dir.path, 'SKILL.md')).writeAsString('# $name\n');
    await File(p.join(dir.path, 'notes.txt')).writeAsString('nested');
    return dir;
  }

  Future<Link> fileSymlink(String name, File target) async {
    final link = Link(p.join(root.path, name));
    await link.create(target.path);
    return link;
  }

  Future<Link> directorySymlink(String name, Directory target) async {
    final link = Link(p.join(root.path, name));
    await link.create(target.path);
    return link;
  }
}
