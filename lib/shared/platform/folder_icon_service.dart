import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Applies a Nightelf logo as the Finder custom icon for a folder.
abstract interface class FolderIconService {
  Future<void> setFolderIcon(String path);
}

class MethodChannelFolderIconService implements FolderIconService {
  MethodChannelFolderIconService({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('ai_workbench/folder_icon');

  final MethodChannel _channel;

  @override
  Future<void> setFolderIcon(String path) async {
    await _channel.invokeMethod<void>('setFolderIcon', {'path': path});
  }
}

class NoopFolderIconService implements FolderIconService {
  @override
  Future<void> setFolderIcon(String path) async {}
}

class RecordingFolderIconService implements FolderIconService {
  final List<String> paths = [];

  @override
  Future<void> setFolderIcon(String path) async {
    paths.add(path);
  }
}

FolderIconService defaultFolderIconService() {
  if (kIsWeb) {
    return NoopFolderIconService();
  }
  return MethodChannelFolderIconService();
}
