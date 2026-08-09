import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Picks a local directory with a reliable macOS open panel.
abstract interface class DirectoryPickerService {
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  });
}

class MethodChannelDirectoryPickerService implements DirectoryPickerService {
  MethodChannelDirectoryPickerService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ai_workbench/directory_picker');

  final MethodChannel _channel;

  @override
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async {
    final path = await _channel.invokeMethod<String>('pickDirectory', {
      'dialogTitle': dialogTitle,
      'initialDirectory': initialDirectory,
      'allowCreate': allowCreate,
    });
    if (path == null || path.trim().isEmpty) {
      return null;
    }
    return path;
  }
}

class NoopDirectoryPickerService implements DirectoryPickerService {
  @override
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async => null;
}

class RecordingDirectoryPickerService implements DirectoryPickerService {
  String? nextPath;
  final List<String?> calls = [];

  @override
  Future<String?> pickDirectory({
    String? dialogTitle,
    String? initialDirectory,
    bool allowCreate = true,
  }) async {
    calls.add(dialogTitle);
    return nextPath;
  }
}

DirectoryPickerService defaultDirectoryPickerService() {
  if (kIsWeb) {
    return NoopDirectoryPickerService();
  }
  return MethodChannelDirectoryPickerService();
}
