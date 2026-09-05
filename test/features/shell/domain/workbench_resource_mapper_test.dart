import 'dart:io';

import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/resource_factories.dart';

void main() {
  test('launcher subtitle is 路径无效 when the script is missing', () {
    final resource = workbenchResourceFromRecord(
      launcherRecord(description: '/tmp/nightelf-missing-launch.sh'),
    );
    expect(resource.type, ResourceType.launcher);
    expect(resource.subtitle, '路径无效');
  });

  test('launcher subtitle is the script path when the file exists', () async {
    final script = File(
      '${Directory.systemTemp.path}/nightelf-mapper-launch.sh',
    );
    await script.writeAsString('#!/bin/bash\n');
    addTearDown(() async {
      if (await script.exists()) {
        await script.delete();
      }
    });

    final resource = workbenchResourceFromRecord(
      launcherRecord(description: script.path),
    );
    expect(resource.subtitle, script.path);
  });
}
