import 'package:ai_workbench/shared/platform/clipboard_service.dart';
import 'package:ai_workbench/shared/platform/process_runner.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';

class ProcessCall {
  const ProcessCall({required this.executable, required this.arguments});

  final String executable;
  final List<String> arguments;
}

class RecordingProcessRunner implements ProcessRunner {
  final List<ProcessCall> calls = [];
  int exitCode = 0;
  String stderr = '';

  @override
  Future<ProcessResultData> run(
    String executable,
    List<String> arguments,
  ) async {
    calls.add(ProcessCall(executable: executable, arguments: arguments));
    return ProcessResultData(exitCode: exitCode, stderr: stderr);
  }
}

class RecordingSystemOpenService implements SystemOpenService {
  final List<String> revealedPaths = [];
  final List<String> terminalPaths = [];
  final List<Uri> openedUrls = [];
  final List<String> openedPaths = [];

  @override
  Future<void> revealInFinder(String path) async {
    revealedPaths.add(path);
  }

  @override
  Future<void> openTerminalAt(String directoryPath) async {
    terminalPaths.add(directoryPath);
  }

  @override
  Future<void> openExternalUrl(Uri uri) async {
    openedUrls.add(uri);
  }

  @override
  Future<void> openPath(String path) async {
    openedPaths.add(path);
  }
}

class RecordingClipboardService implements ClipboardService {
  final List<String> texts = [];

  @override
  Future<void> writeText(String text) async {
    texts.add(text);
  }
}
