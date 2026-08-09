import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_change_watcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

void main() {
  test('three writes inside 250 ms emit one path set', () async {
    final root = await Directory.systemTemp.createTemp('nightelf-watch-');
    addTearDown(() => root.delete(recursive: true));

    final eventsIn = StreamController<WatchEvent>();
    addTearDown(eventsIn.close);
    final watcher = VaultChangeWatcher(
      debounce: const Duration(milliseconds: 250),
      eventStreamFactory: (_) => eventsIn.stream,
    );
    final events = <Set<String>>[];
    final sub = watcher.watch(root).listen(events.add);
    addTearDown(sub.cancel);

    eventsIn
      ..add(WatchEvent(ChangeType.MODIFY, p.join(root.path, 'a.md')))
      ..add(WatchEvent(ChangeType.MODIFY, p.join(root.path, 'b.md')))
      ..add(WatchEvent(ChangeType.MODIFY, p.join(root.path, 'c.md')));
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect(events, hasLength(1));
    expect(events.single, containsAll(['a.md', 'b.md', 'c.md']));
  });

  test('ignores git, local cache, and temp files', () async {
    final root = await Directory.systemTemp.createTemp(
      'nightelf-watch-ignore-',
    );
    addTearDown(() => root.delete(recursive: true));

    final eventsIn = StreamController<WatchEvent>();
    addTearDown(eventsIn.close);
    final watcher = VaultChangeWatcher(
      debounce: const Duration(milliseconds: 200),
      eventStreamFactory: (_) => eventsIn.stream,
    );
    final events = <Set<String>>[];
    final sub = watcher.watch(root).listen(events.add);
    addTearDown(sub.cancel);

    eventsIn
      ..add(WatchEvent(ChangeType.MODIFY, p.join(root.path, '.git', 'HEAD')))
      ..add(
        WatchEvent(
          ChangeType.MODIFY,
          p.join(root.path, '.ai-workbench', 'local', 'index.sqlite'),
        ),
      )
      ..add(
        WatchEvent(
          ChangeType.MODIFY,
          p.join(root.path, '.ai-workbench', 'resources', 'metadata.json'),
        ),
      )
      ..add(
        WatchEvent(
          ChangeType.MODIFY,
          p.join(root.path, 'draft.md.nightelf-tmp'),
        ),
      )
      ..add(WatchEvent(ChangeType.MODIFY, p.join(root.path, 'keep.md')));
    await Future<void>.delayed(const Duration(milliseconds: 350));

    expect(events, hasLength(1));
    expect(events.single, equals({'keep.md'}));
  });
}
