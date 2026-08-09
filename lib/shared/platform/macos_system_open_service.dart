import 'package:ai_workbench/shared/platform/process_runner.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:path/path.dart' as p;

class MacosSystemOpenService implements SystemOpenService {
  MacosSystemOpenService([ProcessRunner? runner])
    : _runner = runner ?? const IoProcessRunner();

  static const _open = '/usr/bin/open';

  final ProcessRunner _runner;

  @override
  Future<void> revealInFinder(String path) async {
    final absolute = _requireAbsolute(path, 'revealInFinder');
    await _run('revealInFinder', [_open, '-R', absolute]);
  }

  @override
  Future<void> openTerminalAt(String directoryPath) async {
    final absolute = _requireAbsolute(directoryPath, 'openTerminalAt');
    await _run('openTerminalAt', [_open, '-a', 'Terminal', absolute]);
  }

  @override
  Future<void> openExternalUrl(Uri uri) async {
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw SystemOpenException(
        'openExternalUrl',
        '仅支持 http/https，收到：${uri.scheme}',
      );
    }
    await _run('openExternalUrl', [_open, uri.toString()]);
  }

  String _requireAbsolute(String path, String operation) {
    if (!p.isAbsolute(path)) {
      throw SystemOpenException(operation, '路径必须是绝对路径：$path');
    }
    return path;
  }

  Future<void> _run(String operation, List<String> command) async {
    final executable = command.first;
    final arguments = command.sublist(1);
    final result = await _runner.run(executable, arguments);
    if (result.exitCode != 0) {
      throw SystemOpenException(
        operation,
        result.stderr.trim().isEmpty
            ? 'exit ${result.exitCode}'
            : result.stderr.trim(),
      );
    }
  }
}
