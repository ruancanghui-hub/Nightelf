import 'dart:io';

import 'package:ai_workbench/features/launchers/application/launcher_controller.dart';
import 'package:ai_workbench/features/launchers/data/file_launcher_repository.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:ai_workbench/shared/platform/script_picker_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

class RecordingScriptPicker implements ScriptPickerService {
  RecordingScriptPicker(this.nextPath);

  String? nextPath;

  @override
  Future<String?> pickScript() async => nextPath;
}

void main() {
  late Directory root;
  late Directory project;
  late File script;
  late RecordingSystemOpenService systemOpen;
  late RecordingScriptPicker picker;
  late LauncherController controller;
  var nextId = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-launcher-ctrl-');
    project = await Directory.systemTemp.createTemp('nightelf-project-');
    script = File('${project.path}/launch_macos.sh');
    await script.writeAsString('#!/bin/bash\necho hi\n');
    systemOpen = RecordingSystemOpenService();
    picker = RecordingScriptPicker(script.path);
    nextId = 0;
    controller = LauncherController(
      repository: FileLauncherRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'id-${++nextId}',
      ),
      systemOpen: systemOpen,
      scriptPicker: picker,
      vaultRootPath: root.path,
    );
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
    await project.delete(recursive: true);
  });

  test('create from picker then launch hands the script to the system', () async {
    final created = await controller.createFromPicker();
    expect(created?.title, 'launch_macos');
    expect(created?.scriptPath, script.path);
    expect(controller.canLaunch, isTrue);

    await controller.launch();
    expect(systemOpen.launchedScripts, [script.path]);
    expect(controller.statusMessage, '已启动');
  });

  test('missing script disables launch and reports 找不到文件', () async {
    await controller.createFromPicker();
    await script.delete();
    await controller.open(controller.document!.relativePath);

    expect(controller.canLaunch, isFalse);
    expect(controller.isScriptMissing, isTrue);
    expect(controller.errorMessage, '找不到文件');

    await controller.launch();
    expect(systemOpen.launchedScripts, isEmpty);
    expect(controller.errorMessage, '找不到文件');
  });

  test('cancelled picker does not create a launcher', () async {
    picker.nextPath = null;
    expect(await controller.createFromPicker(), isNull);
    expect(controller.document, isNull);
  });

  test('re-pick updates the script path', () async {
    await controller.createFromPicker();
    final other = File('${project.path}/启动.command');
    await other.writeAsString('#!/bin/bash\n');
    picker.nextPath = other.path;

    await controller.pickScriptPath();
    expect(controller.document?.scriptPath, other.path);
    expect(controller.statusMessage, '已更新脚本路径');
  });
}
