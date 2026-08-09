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
    final temporary = File('${target.path}.nightelf-tmp');
    await _writeTemporaryFile(temporary, contents);
    await temporary.rename(target.path);
  }

  static Future<void> _writeAndFlush(File temporary, String contents) async {
    await temporary.writeAsString(contents, flush: true);
  }
}
