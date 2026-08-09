import 'dart:io';

typedef TemporaryFileWriter =
    Future<void> Function(File temporary, String contents);

/// Persists text by fully writing a sibling temporary file before replacing
/// the target.
class AtomicFileWriter {
  AtomicFileWriter({TemporaryFileWriter? writeTemporaryFile})
    : _writeTemporaryFile = writeTemporaryFile ?? _writeAndFlush;

  final TemporaryFileWriter _writeTemporaryFile;

  Future<void> writeString(File target, String contents) async {
    await target.parent.create(recursive: true);
    final temporary = File('${target.path}.nightelf-tmp');
    await _writeTemporaryFile(temporary, contents);
    try {
      // Parent can disappear if the Vault folder was deleted mid-write.
      await target.parent.create(recursive: true);
      await temporary.rename(target.path);
    } on PathNotFoundException {
      if (!await temporary.exists()) {
        rethrow;
      }
      await target.parent.create(recursive: true);
      await temporary.copy(target.path);
      await temporary.delete();
    } on FileSystemException {
      if (!await temporary.exists()) {
        rethrow;
      }
      await target.parent.create(recursive: true);
      await temporary.copy(target.path);
      try {
        await temporary.delete();
      } on FileSystemException {
        // Best-effort cleanup.
      }
    }
  }

  static Future<void> _writeAndFlush(File temporary, String contents) async {
    await temporary.writeAsString(contents, flush: true);
  }
}
