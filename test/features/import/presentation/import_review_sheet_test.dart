import 'dart:io';

import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/import/presentation/import_review_sheet.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:ai_workbench/shared/ui/workbench_button.dart';
import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets(
    'wide review keeps source and editable configuration side by side',
    (tester) async {
      final fixture = _ReviewFixture.create(selectedType: ResourceType.mcp);
      addTearDown(fixture.dispose);
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await fixture.pump(tester);

      final source = find.byKey(const Key('import-source-pane'));
      final config = find.byKey(const Key('import-config-pane'));
      expect(find.byKey(const Key('import-review-dialog')), findsOneWidget);
      expect(source, findsOneWidget);
      expect(config, findsOneWidget);
      expect(
        tester.getTopLeft(source).dx,
        lessThan(tester.getTopLeft(config).dx),
      );
      expect(find.text('内容预览（前 20 行）'), findsOneWidget);
      expect(find.text('源文件不会被修改'), findsOneWidget);
      expect(find.text('高置信度'), findsOneWidget);

      final targetField = find.descendant(
        of: find.byKey(const Key('import-target-name')),
        matching: find.byType(EditableText),
      );
      expect(targetField, findsOneWidget);
      await tester.enterText(targetField, 'team-mcp.json');
      await tester.pump();
      expect(
        fixture.controller.plan.items.single.targetBasename,
        'team-mcp.json',
      );

      await tester.tap(find.bySemanticsLabel('资源类型：网站链接'));
      await tester.pump();
      expect(
        fixture.controller.plan.items.single.selectedType,
        ResourceType.link,
      );
    },
  );

  testWidgets('compact review stacks panes and preserves primary actions', (
    tester,
  ) async {
    final fixture = _ReviewFixture.create(selectedType: ResourceType.mcp);
    addTearDown(fixture.dispose);
    tester.view.physicalSize = const Size(720, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await fixture.pump(tester);

    final source = find.byKey(const Key('import-source-pane'));
    final config = find.byKey(const Key('import-config-pane'));
    expect(
      tester.getTopLeft(source).dy,
      lessThan(tester.getTopLeft(config).dy),
    );
    expect(find.bySemanticsLabel('关闭审核导入'), findsOneWidget);
    expect(find.bySemanticsLabel('取消导入'), findsOneWidget);
    expect(find.bySemanticsLabel('复制到 Vault'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('unknown input requires type selection before confirmation', (
    tester,
  ) async {
    final fixture = _ReviewFixture.create(selectedType: null);
    addTearDown(fixture.dispose);

    await fixture.pump(tester);

    expect(find.text('复制到 Vault'), findsOneWidget);
    expect(find.text('请为所有选中项选择资源类型后再导入'), findsOneWidget);
    expect(
      tester
          .widget<WorkbenchButton>(find.byKey(const Key('import-copy-button')))
          .onPressed,
      isNull,
    );
  });
}

class _ReviewFixture {
  _ReviewFixture({
    required this.controller,
    required this.vault,
    required this.root,
  });

  final ImportController controller;
  final VaultHandle vault;
  final Directory root;

  static _ReviewFixture create({required ResourceType? selectedType}) {
    final root = Directory.systemTemp.createTempSync('nightelf-review-');
    final source = File('${root.path}/mcp.json');
    source.writeAsStringSync('''{
  "mcpServers": {
    "example": {
      "command": "node",
      "args": ["dist/index.js"],
      "env": {"API_KEY": "\${API_KEY}"}
    }
  }
}
''');
    final controller = ImportController(repository: VaultImportRepository());
    controller.debugReplacePlan(
      ImportPlan([
        ImportPlanItem(
          candidate: ImportCandidate(
            sourcePath: source.path,
            isDirectory: false,
            suggestedType: ResourceType.mcp,
            reason: '按扩展名识别为 MCP 配置',
          ),
          selectedType: selectedType,
          title: 'mcp',
          targetBasename: 'mcp.json',
          isSelected: true,
        ),
      ]),
    );
    return _ReviewFixture(
      controller: controller,
      vault: VaultHandle(
        Directory('${root.path}/vault'),
        const VaultManifest(version: 1, id: 'v', name: 'Nightelf Vault'),
      ),
      root: root,
    );
  }

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MacosApp(
        home: WorkbenchShadScope(
          child: ImportReviewSheet(controller: controller, vault: vault),
        ),
      ),
    );
    await tester.pump();
  }

  void dispose() {
    controller.dispose();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }
}
