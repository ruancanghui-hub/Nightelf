import 'dart:io';

import 'package:path/path.dart' as p;

class LauncherScript {
  const LauncherScript._();

  static const supportedExtensions = {'.sh', '.command'};

  static String extensionOf(String path) => p.extension(path).toLowerCase();

  static bool hasSupportedExtension(String path) =>
      supportedExtensions.contains(extensionOf(path));

  static String defaultTitleFor(String path) {
    final name = p.basenameWithoutExtension(path).trim();
    return name.isEmpty ? '未命名启动器' : name;
  }

  /// Returns an error message when [path] cannot be a launcher script path.
  static String? validatePath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) {
      return '脚本路径不能为空';
    }
    if (!p.isAbsolute(trimmed)) {
      return '脚本路径必须是绝对路径';
    }
    if (!hasSupportedExtension(trimmed)) {
      return '仅支持 .sh 或 .command';
    }
    return null;
  }

  static bool exists(String path) => File(path).existsSync();

  static bool canLaunch(String path) =>
      validatePath(path) == null && exists(path);
}
