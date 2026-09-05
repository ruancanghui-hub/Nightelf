import 'package:ai_workbench/shared/platform/macos_system_open_service.dart';
import 'package:ai_workbench/shared/platform/system_open_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recording_platform_adapters.dart';

void main() {
  test('Finder reveal passes the path as one argument', () async {
    final runner = RecordingProcessRunner();
    final service = MacosSystemOpenService(runner);
    await service.revealInFinder('/tmp/a folder/\$(unsafe)');
    expect(runner.calls.single.executable, '/usr/bin/open');
    expect(runner.calls.single.arguments, ['-R', '/tmp/a folder/\$(unsafe)']);
  });

  test('terminal opens the containing directory', () async {
    final runner = RecordingProcessRunner();
    await MacosSystemOpenService(
      runner,
    ).openTerminalAt('/tmp/vault/skills/apple-design');
    expect(runner.calls.single.arguments, [
      '-a',
      'Terminal',
      '/tmp/vault/skills/apple-design',
    ]);
  });

  test('rejects relative paths', () async {
    final service = MacosSystemOpenService(RecordingProcessRunner());
    expect(
      () => service.revealInFinder('relative/path'),
      throwsA(isA<SystemOpenException>()),
    );
  });

  test('rejects non-http URL schemes', () async {
    final service = MacosSystemOpenService(RecordingProcessRunner());
    expect(
      () => service.openExternalUrl(Uri.parse('javascript:alert(1)')),
      throwsA(isA<SystemOpenException>()),
    );
    expect(
      () => service.openExternalUrl(Uri.parse('file:///tmp/x')),
      throwsA(isA<SystemOpenException>()),
    );
  });

  test('surfaces non-zero process results without retry', () async {
    final runner = RecordingProcessRunner()
      ..exitCode = 1
      ..stderr = 'open failed';
    final service = MacosSystemOpenService(runner);
    expect(
      () => service.openExternalUrl(Uri.parse('https://example.com')),
      throwsA(
        isA<SystemOpenException>().having(
          (error) => error.stderr,
          'stderr',
          'open failed',
        ),
      ),
    );
    expect(runner.calls, hasLength(1));
  });

  test('opens https URLs with open', () async {
    final runner = RecordingProcessRunner();
    await MacosSystemOpenService(
      runner,
    ).openExternalUrl(Uri.parse('https://example.com/a b'));
    expect(runner.calls.single.executable, '/usr/bin/open');
    expect(runner.calls.single.arguments, ['https://example.com/a%20b']);
  });

  test('opens .command with open and .sh in Terminal', () async {
    final runner = RecordingProcessRunner();
    final service = MacosSystemOpenService(runner);
    await service.launchScript('/tmp/启动 Nightelf.command');
    expect(runner.calls.single.executable, '/usr/bin/open');
    expect(runner.calls.single.arguments, ['/tmp/启动 Nightelf.command']);

    runner.calls.clear();
    await service.launchScript('/tmp/project/script/launch_macos.sh');
    expect(runner.calls.single.executable, '/usr/bin/osascript');
    expect(runner.calls.single.arguments.first, '-e');
    expect(
      runner.calls.single.arguments.last,
      contains(
        "cd '/tmp/project/script' && exec bash '/tmp/project/script/launch_macos.sh'",
      ),
    );
  });

  test('rejects unsupported launcher extensions', () async {
    final service = MacosSystemOpenService(RecordingProcessRunner());
    expect(
      () => service.launchScript('/tmp/run.py'),
      throwsA(isA<SystemOpenException>()),
    );
  });
}
