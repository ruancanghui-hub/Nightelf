import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

class RecordingDocumentStorage implements DocumentStorage {
  RecordingDocumentStorage({required String initialText}) : _text = initialText;

  String _text;
  DateTime _modifiedAt = DateTime.utc(2026, 8, 9, 1);
  final List<String> writes = [];
  bool failNextWrite = false;

  @override
  Future<String> read(String absolutePath) async => _text;

  @override
  Future<void> writeAtomically(String absolutePath, String contents) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('disk full');
    }
    writes.add(contents);
    _text = contents;
    _modifiedAt = _modifiedAt.add(const Duration(seconds: 1));
  }

  @override
  Future<DateTime> modifiedAt(String absolutePath) async => _modifiedAt;

  void touchExternal(String contents) {
    _text = contents;
    _modifiedAt = _modifiedAt.add(const Duration(seconds: 1));
  }
}

void main() {
  const descriptor = DocumentDescriptor(
    resourceId: 'p1',
    absolutePath: '/tmp/prompt.md',
    language: DocumentLanguage.markdown,
  );

  test('autosaves after the configured delay', () {
    fakeAsync((async) {
      final storage = RecordingDocumentStorage(initialText: 'one');
      final session = DocumentSession(
        descriptor: descriptor,
        storage: storage,
        autosaveDelay: const Duration(milliseconds: 600),
      );
      addTearDown(session.dispose);

      session.updateText('two');
      async.elapse(const Duration(milliseconds: 599));
      expect(storage.writes, isEmpty);
      async.elapse(const Duration(milliseconds: 1));
      expect(storage.writes, ['two']);
      expect(session.state.isClean, isTrue);
    });
  });

  test('typing marks dirty and save failure retains the buffer', () async {
    final storage = RecordingDocumentStorage(initialText: 'one')
      ..failNextWrite = true;
    final session = DocumentSession(
      descriptor: descriptor,
      storage: storage,
      autosaveDelay: const Duration(days: 1),
    );
    addTearDown(session.dispose);
    await session.load();

    session.updateText('two');
    expect(session.state.isDirty, isTrue);

    await session.saveNow();
    expect(session.state.status, DocumentSessionStatus.failure);
    expect(session.state.text, 'two');
    expect(session.state.errorMessage, contains('保存失败'));
  });

  test(
    'dirty external change creates conflict; clean change reloads',
    () async {
      final storage = RecordingDocumentStorage(initialText: 'one');
      final session = DocumentSession(
        descriptor: descriptor,
        storage: storage,
        autosaveDelay: const Duration(days: 1),
      );
      addTearDown(session.dispose);
      await session.load();

      session.updateText('local');
      storage.touchExternal('disk');
      await session.handleExternalChange(
        await storage.modifiedAt('/tmp/prompt.md'),
      );
      expect(session.state.hasConflict, isTrue);
      expect(session.state.text, 'local');
      expect(session.state.diskText, 'disk');

      await session.keepDiskVersion();
      expect(session.state.isClean, isTrue);
      expect(session.state.text, 'disk');

      storage.touchExternal('reloaded');
      await session.handleExternalChange(
        await storage.modifiedAt('/tmp/prompt.md'),
      );
      expect(session.state.isClean, isTrue);
      expect(session.state.text, 'reloaded');
    },
  );
}
