import 'dart:io';

import 'package:ai_workbench/features/launchers/application/launcher_controller.dart';
import 'package:ai_workbench/features/launchers/data/file_launcher_repository.dart';
import 'package:ai_workbench/features/launchers/presentation/launcher_workspace.dart';
import 'package:ai_workbench/shared/io/atomic_file_writer.dart';
import 'package:ai_workbench/shared/platform/script_picker_service.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

import '../../../shared/platform/recording_platform_adapters.dart';

class _Picker implements ScriptPickerService {
  _Picker(this.path);
  final String path;
  @override
  Future<String?> pickScript() async => path;
}

void main() {
  late Directory root;
  late Directory project;
  late File script;
  late RecordingSystemOpenService systemOpen;
  late LauncherController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('nightelf-launcher-ws-');
    project = await Directory.systemTemp.createTemp('nightelf-project-ws-');
    script = File('${project.path}/launch_macos.sh');
    await script.writeAsString('#!/bin/bash\n');
    systemOpen = RecordingSystemOpenService();
    controller = LauncherController(
      repository: FileLauncherRepository(
        vaultRoot: root,
        writer: AtomicFileWriter(),
        idFactory: () => 'launcher-id',
      ),
      systemOpen: systemOpen,
      scriptPicker: _Picker(script.path),
      vaultRootPath: root.path,
    );
    await controller.createFromPicker();
  });

  tearDown(() async {
    controller.dispose();
    await root.delete(recursive: true);
    await project.delete(recursive: true);
  });

  testWidgets('shows the script path and launches from the primary button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: WorkbenchShadScope(
          child: LauncherWorkspace(controller: controller),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(script.path), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('启动'));
    await tester.pump();

    expect(systemOpen.launchedScripts, [script.path]);
    expect(find.text('已启动'), findsOneWidget);
  });
}
