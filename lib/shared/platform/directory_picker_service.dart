import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Result of a native directory pick, optionally with a security-scoped bookmark.
class PickedDirectory {
  const PickedDirectory({required this.path, this.bookmarkBase64});

  final String path;
  final String? bookmarkBase64;
}

/// Picks a local directory with a reliable macOS open panel.
abstract interface class DirectoryPickerService {
  Future<PickedDirectory?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  });

  /// Resolves a persisted security-scoped bookmark and starts accessing it.
  Future<PickedDirectory?> resolveBookmark(String bookmarkBase64);

  /// Creates a security-scoped bookmark for a path that is currently accessible.
  Future<String?> createBookmark(String path);

  /// Stops security-scoped access for a previously resolved/picked path.
  Future<void> stopAccessing(String path);
}

class MethodChannelDirectoryPickerService implements DirectoryPickerService {
  MethodChannelDirectoryPickerService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ai_workbench/directory_picker');

  final MethodChannel _channel;

  @override
  Future<PickedDirectory?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async {
    final raw = await _channel.invokeMethod<Object?>('pickDirectory', {
      'dialogTitle': dialogTitle,
      'initialDirectory': initialDirectory,
      'allowCreate': allowCreate,
    });
    return _parsePicked(raw);
  }

  @override
  Future<PickedDirectory?> resolveBookmark(String bookmarkBase64) async {
    final raw = await _channel.invokeMethod<Object?>('resolveBookmark', {
      'bookmarkBase64': bookmarkBase64,
    });
    return _parsePicked(raw);
  }

  @override
  Future<String?> createBookmark(String path) async {
    final raw = await _channel.invokeMethod<String?>('createBookmark', {
      'path': path,
    });
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return raw;
  }

  @override
  Future<void> stopAccessing(String path) async {
    await _channel.invokeMethod<void>('stopAccessing', {'path': path});
  }

  PickedDirectory? _parsePicked(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is String) {
      final path = raw.trim();
      if (path.isEmpty) {
        return null;
      }
      return PickedDirectory(path: path);
    }
    if (raw is Map) {
      final path = raw['path']?.toString().trim() ?? '';
      if (path.isEmpty) {
        return null;
      }
      final bookmark = raw['bookmarkBase64']?.toString();
      return PickedDirectory(
        path: path,
        bookmarkBase64: (bookmark == null || bookmark.isEmpty) ? null : bookmark,
      );
    }
    return null;
  }
}

class NoopDirectoryPickerService implements DirectoryPickerService {
  @override
  Future<PickedDirectory?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async => null;

  @override
  Future<PickedDirectory?> resolveBookmark(String bookmarkBase64) async => null;

  @override
  Future<String?> createBookmark(String path) async => null;

  @override
  Future<void> stopAccessing(String path) async {}
}

class RecordingDirectoryPickerService implements DirectoryPickerService {
  PickedDirectory? nextPicked;
  PickedDirectory? nextResolved;
  String? nextCreatedBookmark;
  final List<String?> pickCalls = [];
  final List<String> resolveCalls = [];
  final List<String> stopCalls = [];

  @override
  Future<PickedDirectory?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async {
    pickCalls.add(dialogTitle);
    return nextPicked;
  }

  @override
  Future<PickedDirectory?> resolveBookmark(String bookmarkBase64) async {
    resolveCalls.add(bookmarkBase64);
    return nextResolved;
  }

  @override
  Future<String?> createBookmark(String path) async => nextCreatedBookmark;

  @override
  Future<void> stopAccessing(String path) async {
    stopCalls.add(path);
  }
}

DirectoryPickerService defaultDirectoryPickerService() {
  if (kIsWeb) {
    return NoopDirectoryPickerService();
  }
  return MethodChannelDirectoryPickerService();
}
