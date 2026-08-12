import 'package:ai_workbench/features/overview/presentation/emerald_overview_dashboard.dart';
import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_shell.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';

void main() {
  testWidgets('matches the reference desktop region proportions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: const ProviderScope(
          child: WorkbenchShadScope(
            child: WorkbenchShell(vaultRootPath: '/reference-vault'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EmeraldOverviewDashboard), findsOneWidget);
    final sidebar = tester.widget<WorkbenchSidebar>(
      find.byType(WorkbenchSidebar),
    );
    expect(sidebar.width, closeTo(340, 8));
    expect(find.text('Nightelf 工作台'), findsOneWidget);
    final logo = tester.widget<Image>(
      find.byKey(const ValueKey('nightelf-sidebar-logo')),
    );
    expect((logo.image as AssetImage).assetName, 'assets/nightelf-logo.png');
    expect(logo.width, 34);
    expect(logo.height, 34);
    expect(logo.fit, BoxFit.contain);
    expect(find.text('最近使用的资源'), findsOneWidget);
    expect(find.text('同步状态'), findsOneWidget);
    expect(find.bySemanticsLabel('切换 Vault'), findsNothing);
  });

  testWidgets('shows switch vault action and invokes the callback', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var switched = false;

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: ProviderScope(
          child: WorkbenchShadScope(
            child: WorkbenchShell(
              vaultRootPath: '/reference-vault',
              onSwitchVault: () => switched = true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final switchButton = find.bySemanticsLabel('切换 Vault');
    expect(switchButton, findsOneWidget);
    await tester.tap(switchButton);
    await tester.pump();
    expect(switched, isTrue);
  });

  testWidgets('shows relative opened time for recent overview resources', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1672, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final shellKey = GlobalKey<WorkbenchShellState>();
    const resource = WorkbenchResource(
      id: 'prompt-old',
      type: ResourceType.aiPrompt,
      title: '旧提示词',
      subtitle: 'prompts/old.md',
      isFavorite: false,
      relativePath: 'prompts/old.md',
    );

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: ProviderScope(
          child: WorkbenchShadScope(
            child: WorkbenchShell(
              key: shellKey,
              vaultRootPath: '/reference-vault',
              resources: const [resource],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    shellKey.currentState!.applyRecentEntries([
      RecentResourceEntry(
        resourceId: resource.id,
        openedAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(EmeraldOverviewDashboard),
        matching: find.text(resource.title),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(EmeraldOverviewDashboard),
        matching: find.text('2 小时前'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('calculates today overview from resource data', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1672, 940));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final now = DateTime.now();
    final today = now.subtract(const Duration(hours: 1));
    final yesterday = now.subtract(const Duration(days: 1));
    final resources = [
      WorkbenchResource(
        id: 'prompt-today',
        type: ResourceType.aiPrompt,
        title: '今日提示词',
        subtitle: 'prompts/today.md',
        isFavorite: true,
        relativePath: 'prompts/today.md',
        modifiedAt: today,
      ),
      WorkbenchResource(
        id: 'link-yesterday',
        type: ResourceType.websiteLink,
        title: '昨日链接',
        subtitle: 'links/yesterday.md',
        isFavorite: true,
        relativePath: 'links/yesterday.md',
        modifiedAt: yesterday,
      ),
      const WorkbenchResource(
        id: 'workflow-untracked',
        type: ResourceType.workflowFile,
        title: '无时间流程',
        subtitle: 'workflows/untracked.mmd',
        isFavorite: false,
        relativePath: 'workflows/untracked.mmd',
      ),
    ];
    final openedAt = <String, DateTime>{
      'prompt-today': today,
      'link-yesterday': yesterday,
    };

    await tester.pumpWidget(
      MacosApp(
        theme: MacosThemeData.dark(),
        home: ProviderScope(
          child: WorkbenchShadScope(
            child: EmeraldOverviewDashboard(
              resources: resources,
              recentResources: resources.take(2).toList(),
              recentOpenedAt: (resourceId) => openedAt[resourceId],
              labelFor: (type) => switch (type) {
                ResourceType.aiPrompt => 'AI 提示词',
                ResourceType.skillFolder => 'SKILL 文件夹',
                ResourceType.mcpConfiguration => 'MCP 配置',
                ResourceType.websiteLink => '网站链接',
                ResourceType.workflowFile => 'Workflow 文件',
              },
              onTypeSelected: (_) {},
              onResourceSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expectStatValue(tester, '今日更新', '1');
    expectStatValue(tester, '今日打开', '1');
    expectStatValue(tester, '收藏资源', '2');
    expectStatValue(tester, '资源总数', '3');
  });

  testWidgets(
    'overview opens a favorites list filtered to favorite resources',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1672, 940));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const favoritePrompt = WorkbenchResource(
        id: 'prompt-favorite',
        type: ResourceType.aiPrompt,
        title: '收藏提示词',
        subtitle: 'prompts/favorite.md',
        isFavorite: true,
        relativePath: 'prompts/favorite.md',
      );
      const favoriteLink = WorkbenchResource(
        id: 'link-favorite',
        type: ResourceType.websiteLink,
        title: '收藏链接',
        subtitle: 'links/favorite.md',
        isFavorite: true,
        relativePath: 'links/favorite.md',
      );
      const regularPrompt = WorkbenchResource(
        id: 'prompt-regular',
        type: ResourceType.aiPrompt,
        title: '普通提示词',
        subtitle: 'prompts/regular.md',
        isFavorite: false,
        relativePath: 'prompts/regular.md',
      );

      await tester.pumpWidget(
        MacosApp(
          theme: MacosThemeData.dark(),
          home: const ProviderScope(
            child: WorkbenchShadScope(
              child: WorkbenchShell(
                vaultRootPath: '/reference-vault',
                resources: [favoritePrompt, favoriteLink, regularPrompt],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('打开收藏夹列表'));
      await tester.pumpAndSettle();

      expect(find.text('收藏夹'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('resource-list-item-prompt-favorite')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-list-item-link-favorite')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('resource-list-item-prompt-regular')),
        findsNothing,
      );
    },
  );
}

void expectStatValue(WidgetTester tester, String label, String value) {
  final row = find.byKey(ValueKey('stat-row-$label'));

  expect(find.descendant(of: row, matching: find.text(value)), findsOneWidget);
}
