import 'package:ai_workbench/features/command_palette/presentation/command_palette.dart';
import 'package:ai_workbench/features/library/presentation/resource_list_pane.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/application/workspace_tabs_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/domain/workspace_tab.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_sidebar.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_toolbar.dart';
import 'package:ai_workbench/features/shell/presentation/workspace_tab_strip.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A dark/light Apple-style three-region shell backed only by mock records.
class WorkbenchShell extends StatefulWidget {
  const WorkbenchShell({super.key});

  @override
  State<WorkbenchShell> createState() => _WorkbenchShellState();
}

class _WorkbenchShellState extends State<WorkbenchShell> {
  late final WorkbenchController _controller;
  late final WorkspaceTabsController _tabsController;
  bool _isPaletteOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = WorkbenchController()..addListener(_refresh);
    _tabsController = WorkspaceTabsController()
      ..openTab(_tabFor(_controller.selectedResource))
      ..addListener(_refresh);
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    _tabsController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  WorkspaceTab _tabFor(WorkbenchResource resource) => WorkspaceTab(
    resourceId: resource.id,
    title: resource.title,
    type: resource.type,
  );

  WorkbenchResource? get _activeResource {
    final activeId = _tabsController.activeResourceId;
    return activeId == null ? null : _controller.resourceById(activeId);
  }

  void _selectDestination(ResourceType type) {
    _controller.selectDestination(type);
    _tabsController.openTab(_tabFor(_controller.selectedResource));
  }

  void _openResource(WorkbenchResource resource) {
    _controller.selectResource(resource);
    _tabsController.openTab(_tabFor(resource));
    if (_isPaletteOpen) {
      setState(() => _isPaletteOpen = false);
    }
  }

  void _activateTab(String resourceId) {
    final resource = _controller.resourceById(resourceId);
    if (resource == null) {
      return;
    }
    _tabsController.activateTab(resourceId);
    _controller.selectResource(resource);
  }

  void _closeTab(String resourceId) {
    _tabsController.closeTab(resourceId);
    final activeId = _tabsController.activeResourceId;
    final resource = activeId == null
        ? null
        : _controller.resourceById(activeId);
    if (resource != null) {
      _controller.selectResource(resource);
    }
  }

  void _openPalette() => setState(() => _isPaletteOpen = true);

  void _closePalette() => setState(() => _isPaletteOpen = false);

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openPalette,
        const SingleActivator(LogicalKeyboardKey.escape): _closePalette,
      },
      child: Focus(
        autofocus: true,
        child: MacosWindow(
          child: Stack(
            children: [
              MacosScaffold(
                children: [
                  ContentArea(
                    builder: (context, scrollController) => Column(
                      children: [
                        WorkbenchToolbar(onGlobalSearch: _openPalette),
                        Expanded(
                          child: Row(
                            children: [
                              WorkbenchSidebar(
                                controller: _controller,
                                onDestinationSelected: _selectDestination,
                              ),
                              ResourceListPane(
                                controller: _controller,
                                onResourceSelected: _openResource,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    WorkspaceTabStrip(
                                      controller: _tabsController,
                                      onTabActivated: _activateTab,
                                      onTabClosed: _closeTab,
                                    ),
                                    Expanded(
                                      child: _InspectorPane(
                                        resource: _activeResource,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_isPaletteOpen)
                CommandPalette(
                  resources: _controller.allResources,
                  onResourceSelected: _openResource,
                  onDismissed: _closePalette,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InspectorPane extends StatelessWidget {
  const _InspectorPane({required this.resource});

  final WorkbenchResource? resource;

  String _typeLabel(WorkbenchResource resource) => switch (resource.type) {
    ResourceType.aiPrompt => 'AI 提示词',
    ResourceType.skillFolder => 'SKILL 文件夹',
    ResourceType.mcpConfiguration => 'MCP 配置',
    ResourceType.websiteLink => '网站链接',
    ResourceType.workflowFile => 'Workflow 文件',
  };

  @override
  Widget build(BuildContext context) {
    final resource = this.resource;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: resource == null
          ? Center(
              child: Text(
                '选择资源以查看详细信息',
                style: MacosTheme.of(context).typography.title3,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resource.title,
                  style: MacosTheme.of(context).typography.largeTitle,
                ),
                const SizedBox(height: 12),
                Text(
                  resource.subtitle,
                  style: MacosTheme.of(context).typography.title3,
                ),
                const SizedBox(height: 32),
                Container(
                  width: 360,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: MacosTheme.of(context).canvasColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: MacosTheme.of(context).dividerColor,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '资源信息',
                        style: MacosTheme.of(context).typography.headline,
                      ),
                      const SizedBox(height: 12),
                      Text('类型：${_typeLabel(resource)}'),
                      const SizedBox(height: 8),
                      Text('资源 ID：${resource.id}'),
                      const SizedBox(height: 8),
                      const Text('数据源：模拟资源'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
