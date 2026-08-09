import 'dart:io';

import 'package:ai_workbench/features/editor/data/document_storage.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';

class FileDocumentStorage implements DocumentStorage {
  FileDocumentStorage({AtomicFileWriter? writer})
    : _writer = writer ?? AtomicFileWriter();

  final AtomicFileWriter _writer;

  @override
  Future<String> read(String absolutePath) => File(absolutePath).readAsString();

  @override
  Future<void> writeAtomically(String absolutePath, String contents) =>
      _writer.writeString(File(absolutePath), contents);

  @override
  Future<DateTime> modifiedAt(String absolutePath) async {
    final stat = await File(absolutePath).stat();
    return stat.modified.toUtc();
  }
}
