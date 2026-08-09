import 'dart:io';

import 'package:ai_workbench/features/import/domain/import_name_allocator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('allocates a numbered name without overwriting', () async {
    final target = await Directory.systemTemp.createTemp('nightelf-name-');
    addTearDown(() => target.delete(recursive: true));
    await File(p.join(target.path, 'prompt.md')).writeAsString('old');

    final allocator = const ImportNameAllocator();
    expect(
      await allocator.nextAvailable(target.path, 'prompt.md'),
      'prompt 2.md',
    );
  });

  test('keeps the original name when free', () async {
    final target = await Directory.systemTemp.createTemp('nightelf-name-free-');
    addTearDown(() => target.delete(recursive: true));

    final allocator = const ImportNameAllocator();
    expect(
      await allocator.nextAvailable(target.path, 'prompt.md'),
      'prompt.md',
    );
  });

  test('increments past existing numbered copies', () async {
    final target = await Directory.systemTemp.createTemp('nightelf-name-n-');
    addTearDown(() => target.delete(recursive: true));
    await File(p.join(target.path, 'prompt.md')).writeAsString('1');
    await File(p.join(target.path, 'prompt 2.md')).writeAsString('2');

    final allocator = const ImportNameAllocator();
    expect(
      await allocator.nextAvailable(target.path, 'prompt.md'),
      'prompt 3.md',
    );
  });
}
