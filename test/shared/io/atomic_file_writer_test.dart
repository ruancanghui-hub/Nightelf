import 'dart:io';

import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('writeString atomically replaces the target contents', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-atomic-');
    addTearDown(() => root.delete(recursive: true));
    final target = File('${root.path}/resource.md');
    await target.writeAsString('original');

    await AtomicFileWriter().writeString(target, 'replacement');

    expect(await target.readAsString(), 'replacement');
    expect(File('${target.path}.nightelf-tmp').existsSync(), isFalse);
  });

  test('write failure preserves the original target and is surfaced', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-atomic-');
    addTearDown(() => root.delete(recursive: true));
    final target = File('${root.path}/resource.md');
    await target.writeAsString('original');
    final failure = StateError('injected write failure');
    final writer = AtomicFileWriter(
      writeTemporaryFile: (temporary, contents) async {
        await temporary.writeAsString('partial replacement');
        throw failure;
      },
    );

    expect(
      () => writer.writeString(target, 'replacement'),
      throwsA(same(failure)),
    );
    expect(await target.readAsString(), 'original');
  });
}
