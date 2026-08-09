import 'dart:io';

import 'package:ai_workbench/features/import/application/import_controller.dart';
import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/import/presentation/import_review_sheet.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/features/vault/domain/vault_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('unknown input requires type selection before confirmation', (
    tester,
  ) async {
    final controller = ImportController(repository: VaultImportRepository());
    addTearDown(controller.dispose);
    controller.debugReplacePlan(
      const ImportPlan([
        ImportPlanItem(
          candidate: ImportCandidate(
            sourcePath: '/tmp/diagram.bin',
            isDirectory: false,
            suggestedType: null,
            reason: '无法自动识别类型',
          ),
          selectedType: null,
          title: 'diagram',
          targetBasename: 'diagram.bin',
          isSelected: true,
        ),
      ]),
    );

    await tester.pumpWidget(
      MacosApp(
        home: ImportReviewSheet(
          controller: controller,
          vault: VaultHandle(
            Directory.systemTemp,
            const VaultManifest(version: 1, id: 'v', name: 't'),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('复制到 Vault'), findsOneWidget);
    final button = tester.widget<PushButton>(
      find.ancestor(
        of: find.text('复制到 Vault'),
        matching: find.byType(PushButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.text('请为所有选中项选择资源类型后再导入'), findsOneWidget);
  });
}
