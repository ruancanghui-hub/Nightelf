import 'dart:async';
import 'dart:io';

import 'package:ai_workbench/features/vault/data/vault_paths.dart';
import 'package:path/path.dart' as p;
import 'package:watcher/watcher.dart';

typedef WatchEventStreamFactory = Stream<WatchEvent> Function(String path);

class VaultChangeWatcher {
  VaultChangeWatcher({
    this.debounce = const Duration(milliseconds: 250),
    WatchEventStreamFactory? eventStreamFactory,
  }) : _eventStreamFactory =
           eventStreamFactory ?? ((path) => DirectoryWatcher(path).events);

  final Duration debounce;
  final WatchEventStreamFactory _eventStreamFactory;

  Stream<Set<String>> watch(Directory root) {
    final controller = StreamController<Set<String>>();
    final pending = <String>{};
    Timer? timer;
    StreamSubscription<WatchEvent>? subscription;

    void flush() {
      if (pending.isEmpty) {
        return;
      }
      final batch = Set<String>.from(pending);
      pending.clear();
      controller.add(batch);
    }

    void schedule() {
      timer?.cancel();
      timer = Timer(debounce, flush);
    }

    subscription = _eventStreamFactory(root.path).listen(
      (event) {
        final absolute = event.path;
        final relative = p.isAbsolute(absolute)
            ? p.relative(absolute, from: root.path)
            : absolute;
        if (_shouldIgnore(relative)) {
          return;
        }
        pending.add(relative);
        schedule();
      },
      onError: controller.addError,
      onDone: () async {
        timer?.cancel();
        flush();
        await controller.close();
      },
    );

    controller.onCancel = () async {
      timer?.cancel();
      await subscription?.cancel();
    };

    return controller.stream;
  }

  bool _shouldIgnore(String relativePath) {
    final normalized = p.normalize(relativePath);
    if (normalized == '.' || normalized.isEmpty) {
      return true;
    }
    final parts = p.split(normalized);
    if (parts.contains('.git')) {
      return true;
    }
    if (normalized == VaultPaths.localRoot ||
        normalized.startsWith('${VaultPaths.localRoot}/')) {
      return true;
    }
    if (normalized.endsWith('.nightelf-tmp')) {
      return true;
    }
    if (normalized.endsWith('.sqlite') ||
        normalized.endsWith('.sqlite-wal') ||
        normalized.endsWith('.sqlite-shm')) {
      return true;
    }
    return false;
  }
}
