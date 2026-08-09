import 'dart:io';

class ProcessResultData {
  const ProcessResultData({
    required this.exitCode,
    this.stdout = '',
    this.stderr = '',
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

abstract interface class ProcessRunner {
  Future<ProcessResultData> run(String executable, List<String> arguments);
}

class IoProcessRunner implements ProcessRunner {
  const IoProcessRunner();

  @override
  Future<ProcessResultData> run(
    String executable,
    List<String> arguments,
  ) async {
    final result = await Process.run(executable, arguments, runInShell: false);
    return ProcessResultData(
      exitCode: result.exitCode,
      stdout: '${result.stdout}',
      stderr: '${result.stderr}',
    );
  }
}
