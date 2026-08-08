import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/domain/workspace_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const releaseNotes = WorkspaceTab(
    resourceId: 'prompt-release-notes',
    title: '发布说明助手',
    type: ResourceType.aiPrompt,
  );
  const uxReview = WorkspaceTab(
    resourceId: 'prompt-ux-review',
    title: 'UX 评审',
    type: ResourceType.aiPrompt,
  );
  const productCopy = WorkspaceTab(
    resourceId: 'skill-product-copy',
    title: '产品文案',
    type: ResourceType.skillFolder,
  );

  test(
    'opening an existing resource activates without duplicating its tab',
    () {
      final controller = WorkspaceTabsController();

      controller
        ..openTab(releaseNotes)
        ..openTab(uxReview)
        ..openTab(releaseNotes);

      expect(controller.tabs.map((tab) => tab.resourceId), [
        'prompt-release-notes',
        'prompt-ux-review',
      ]);
      expect(controller.activeResourceId, 'prompt-release-notes');
    },
  );

  test('closing the active tab activates its immediate left neighbor', () {
    final controller = WorkspaceTabsController();

    controller
      ..openTab(releaseNotes)
      ..openTab(uxReview)
      ..openTab(productCopy)
      ..closeTab('skill-product-copy');

    expect(controller.activeResourceId, 'prompt-ux-review');
    expect(controller.tabs.map((tab) => tab.resourceId), [
      'prompt-release-notes',
      'prompt-ux-review',
    ]);
  });
}
