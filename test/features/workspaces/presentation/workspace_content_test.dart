import 'dart:ui' show Tristate;

import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/workspaces/presentation/skill_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/workflow_workspace.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  Future<void> pumpShell(
    WidgetTester tester, {
    Size size = const Size(1440, 1024),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(theme: MacosThemeData.dark(), home: const WorkbenchShell()),
    );
    await tester.pumpAndSettle();
  }

  Finder navigationButton(String label) => find.byWidgetPredicate(
    (widget) => widget is PushButton && widget.semanticLabel == '导航：$label',
  );

  Future<void> openWorkspace(WidgetTester tester, String label) async {
    await tester.tap(navigationButton(label));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));
  }

  Future<void> pumpUnboundedSurface(
    WidgetTester tester, {
    required double width,
    required Widget child,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: SingleChildScrollView(
          child: Center(
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prompt workspace shows a source surface and mock save state', (
    tester,
  ) async {
    await pumpShell(tester);

    expect(find.text('提示词源码'), findsOneWidget);
    expect(find.text('模拟草稿 · 未写入磁盘'), findsWidgets);
    expect(find.text('保存模拟版本'), findsOneWidget);
  });

  testWidgets('SKILL workspace shows its folder and source previews', (
    tester,
  ) async {
    await pumpShell(tester);
    await openWorkspace(tester, 'SKILL 文件夹');

    expect(find.text('目录预览'), findsOneWidget);
    expect(find.text('SKILL.md'), findsWidgets);
    expect(find.text('只读模拟源码'), findsWidgets);
  });

  testWidgets(
    'MCP workspace keeps future controls disabled with explanations',
    (tester) async {
      await pumpShell(tester);
      await openWorkspace(tester, 'MCP 配置');

      expect(find.text('只读 JSON 预览'), findsOneWidget);
      expect(find.textContaining('filesystem'), findsOneWidget);

      for (final label in const ['复制配置', '在终端打开']) {
        final control = find.byWidgetPredicate(
          (widget) => widget is PushButton && widget.semanticLabel == label,
        );
        expect(control, findsOneWidget);
        expect(tester.widget<PushButton>(control).onPressed, isNull);
      }

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosTooltip && widget.message == '视觉占位：尚未接入剪贴板',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget is MacosTooltip && widget.message == '视觉占位：尚未接入终端',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets('website workspace is visibly static and non-navigating', (
    tester,
  ) async {
    await pumpShell(tester);
    await openWorkspace(tester, '网站链接');

    expect(find.text('内部浏览器 · 静态预览'), findsOneWidget);
    expect(find.text('不会发起网络请求'), findsOneWidget);
    expect(find.text('https://developer.apple.com/design/'), findsOneWidget);
    expect(find.text('此页面不可导航'), findsOneWidget);
  });

  testWidgets('workflow workspace pairs Mermaid source with a static canvas', (
    tester,
  ) async {
    await pumpShell(tester);
    await openWorkspace(tester, 'Workflow 文件');

    expect(find.text('Mermaid 源码'), findsOneWidget);
    expect(find.text('静态画布 · 不可互动'), findsOneWidget);
    expect(find.text('读取变更'), findsOneWidget);
    expect(find.text('生成说明'), findsOneWidget);
    expect(find.text('人工确认'), findsOneWidget);
    expect(find.text('未执行 · 视觉模拟'), findsWidgets);
  });

  testWidgets('all workspaces render without overflow at compact width', (
    tester,
  ) async {
    await pumpShell(tester, size: const Size(960, 720));

    for (final type in ResourceType.values) {
      const labels = {
        ResourceType.aiPrompt: 'AI 提示词',
        ResourceType.skillFolder: 'SKILL 文件夹',
        ResourceType.mcpConfiguration: 'MCP 配置',
        ResourceType.websiteLink: '网站链接',
        ResourceType.workflowFile: 'Workflow 文件',
      };
      await openWorkspace(tester, labels[type]!);
      expect(tester.takeException(), isNull, reason: labels[type]);
    }
  });

  testWidgets('SKILL stacks at an unbounded 620 pixel effective width', (
    tester,
  ) async {
    await pumpUnboundedSurface(
      tester,
      width: 620,
      child: const SkillWorkspace(),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('Workflow stacks at an unbounded 670 pixel effective width', (
    tester,
  ) async {
    await pumpUnboundedSurface(
      tester,
      width: 670,
      child: const WorkflowWorkspace(),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('intermediate window widths keep compact workspaces bounded', (
    tester,
  ) async {
    for (final testCase in const [
      (windowWidth: 1188.0, destination: 'SKILL 文件夹'),
      (windowWidth: 1238.0, destination: 'Workflow 文件'),
    ]) {
      await tester.binding.setSurfaceSize(Size(testCase.windowWidth, 720));
      await tester.pumpWidget(
        MacosApp(theme: MacosThemeData.dark(), home: const WorkbenchShell()),
      );
      await tester.pumpAndSettle();
      await openWorkspace(tester, testCase.destination);
      expect(
        tester.takeException(),
        isNull,
        reason: '${testCase.destination} at ${testCase.windowWidth}',
      );
    }
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  testWidgets(
    'keyboard focus reaches sidebar search tabs and inspector actions',
    (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await pumpShell(tester);

        for (final key in const [
          ValueKey('sidebar-focus-aiPrompt'),
          ValueKey('tab-focus-prompt-release-notes'),
          ValueKey('workspace-primary-action-focus'),
          ValueKey('workspace-secondary-action-focus'),
        ]) {
          final focus = find.byKey(key);
          expect(focus, findsOneWidget);
          final focusWidget = tester.widget<Focus>(focus);
          expect(focusWidget.focusNode, isNotNull);
          focusWidget.focusNode!.requestFocus();
          await tester.pumpAndSettle();
          expect(
            focusWidget.focusNode!.hasFocus,
            isTrue,
            reason: key.toString(),
          );

          final indicator = find.byKey(ValueKey('${key.value}-indicator'));
          expect(indicator, findsOneWidget);
          final decoration =
              tester.widget<AnimatedContainer>(indicator).decoration
                  as BoxDecoration;
          final focusedBorder = decoration.border! as Border;
          expect(
            focusedBorder.top.color,
            MacosTheme.of(tester.element(indicator)).primaryColor,
            reason: 'visible focus ring for ${key.value}',
          );
          expect(
            tester.getSemantics(indicator).flagsCollection.isFocused,
            Tristate.isTrue,
            reason: 'focused semantics for ${key.value}',
          );
        }

        final search = tester.widget<MacosSearchField>(
          find.byKey(const ValueKey('resource-search')),
        );
        expect(search.focusNode, isNotNull);
        search.focusNode!.requestFocus();
        await tester.pump();
        expect(search.focusNode!.hasFocus, isTrue);
      } finally {
        semantics.dispose();
      }
    },
  );
}
