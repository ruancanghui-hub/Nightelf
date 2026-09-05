import 'package:ai_workbench/features/launchers/domain/launcher_script.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts absolute .sh and .command paths', () {
    expect(
      LauncherScript.validatePath('/tmp/launch_macos.sh'),
      isNull,
    );
    expect(
      LauncherScript.validatePath('/tmp/启动 Nightelf.command'),
      isNull,
    );
  });

  test('rejects empty relative and unsupported extensions', () {
    expect(LauncherScript.validatePath(''), '脚本路径不能为空');
    expect(LauncherScript.validatePath('script/launch.sh'), '脚本路径必须是绝对路径');
    expect(LauncherScript.validatePath('/tmp/run.py'), '仅支持 .sh 或 .command');
  });

  test('default title uses the file name without extension', () {
    expect(
      LauncherScript.defaultTitleFor('/tmp/script/launch_macos.sh'),
      'launch_macos',
    );
    expect(
      LauncherScript.defaultTitleFor('/tmp/启动 Nightelf.command'),
      '启动 Nightelf',
    );
  });
}
