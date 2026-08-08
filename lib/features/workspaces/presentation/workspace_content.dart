import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/workspaces/presentation/mcp_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/prompt_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/skill_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/website_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/workflow_workspace.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Chooses a static workspace preview while preserving one shared hierarchy.
class WorkspaceContent extends StatelessWidget {
  const WorkspaceContent({required this.resource, super.key});

  final WorkbenchResource? resource;

  @override
  Widget build(BuildContext context) {
    final resource = this.resource;
    if (resource == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: MacosTheme.of(context).dividerColor),
          ),
        ),
        child: Center(
          child: Text(
            '选择资源以查看详细信息',
            style: MacosTheme.of(context).typography.title3,
          ),
        ),
      );
    }

    final presentation = _presentationFor(resource.type);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _WorkspaceHeader(resource: resource, presentation: presentation),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 680) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        presentation.surface,
                        const SizedBox(height: 16),
                        _WorkspaceInspector(
                          resource: resource,
                          presentation: presentation,
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: presentation.surface,
                      ),
                    ),
                    SizedBox(
                      width: 280,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                        child: _WorkspaceInspector(
                          resource: resource,
                          presentation: presentation,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _WorkspacePresentation _presentationFor(ResourceType type) => switch (type) {
    ResourceType.aiPrompt => const _WorkspacePresentation(
      typeLabel: 'AI 提示词',
      status: '模拟草稿 · 未写入磁盘',
      primaryAction: '保存模拟版本',
      secondaryAction: '预览模拟变更',
      surface: PromptWorkspace(),
    ),
    ResourceType.skillFolder => const _WorkspacePresentation(
      typeLabel: 'SKILL 文件夹',
      status: '只读模拟源码',
      primaryAction: '保存模拟版本',
      secondaryAction: '检查模拟结构',
      surface: SkillWorkspace(),
    ),
    ResourceType.mcpConfiguration => const _WorkspacePresentation(
      typeLabel: 'MCP 配置',
      status: '只读 · 未连接服务',
      primaryAction: '检查模拟语法',
      secondaryAction: '查看模拟详情',
      surface: McpWorkspace(),
    ),
    ResourceType.websiteLink => const _WorkspacePresentation(
      typeLabel: '网站链接',
      status: '静态预览 · 无网络',
      primaryAction: '保存模拟快照',
      secondaryAction: '查看模拟信息',
      surface: WebsiteWorkspace(),
    ),
    ResourceType.workflowFile => const _WorkspacePresentation(
      typeLabel: 'Workflow 文件',
      status: '未执行 · 视觉模拟',
      primaryAction: '保存模拟版本',
      secondaryAction: '检查模拟流程',
      surface: WorkflowWorkspace(),
    ),
  };
}

class _WorkspacePresentation {
  const _WorkspacePresentation({
    required this.typeLabel,
    required this.status,
    required this.primaryAction,
    required this.secondaryAction,
    required this.surface,
  });

  final String typeLabel;
  final String status;
  final String primaryAction;
  final String secondaryAction;
  final Widget surface;
}

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({required this.resource, required this.presentation});

  final WorkbenchResource resource;
  final _WorkspacePresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          bottom: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 10,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resource.title,
                style: MacosTheme.of(context).typography.title1,
              ),
              const SizedBox(height: 4),
              Text(
                resource.subtitle,
                style: MacosTheme.of(context).typography.caption1,
              ),
            ],
          ),
          _StatusPill(label: presentation.status),
        ],
      ),
    );
  }
}

class _WorkspaceInspector extends StatelessWidget {
  const _WorkspaceInspector({
    required this.resource,
    required this.presentation,
  });

  final WorkbenchResource resource;
  final _WorkspacePresentation presentation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('检查器', style: MacosTheme.of(context).typography.headline),
          const SizedBox(height: 16),
          Text('类型：${presentation.typeLabel}'),
          const SizedBox(height: 8),
          Text('资源 ID：${resource.id}'),
          const SizedBox(height: 8),
          const Text('数据源：模拟资源'),
          const SizedBox(height: 16),
          _StatusPill(label: presentation.status),
          const SizedBox(height: 20),
          _FocusableWorkspaceAction(
            focusKey: const ValueKey('workspace-primary-action-focus'),
            label: presentation.primaryAction,
          ),
          const SizedBox(height: 8),
          _FocusableWorkspaceAction(
            focusKey: const ValueKey('workspace-secondary-action-focus'),
            label: presentation.secondaryAction,
            secondary: true,
          ),
          const SizedBox(height: 12),
          Text(
            '所有操作均为视觉模拟，不会读写或执行资源。',
            style: MacosTheme.of(context).typography.caption1,
          ),
        ],
      ),
    );
  }
}

class _FocusableWorkspaceAction extends StatefulWidget {
  const _FocusableWorkspaceAction({
    required this.focusKey,
    required this.label,
    this.secondary = false,
  });

  final Key focusKey;
  final String label;
  final bool secondary;

  @override
  State<_FocusableWorkspaceAction> createState() =>
      _FocusableWorkspaceActionState();
}

class _FocusableWorkspaceActionState extends State<_FocusableWorkspaceAction> {
  late final FocusNode _focusNode = FocusNode(debugLabel: widget.label);

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      _runMockAction();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _runMockAction() {}

  @override
  Widget build(BuildContext context) {
    return Focus(
      key: widget.focusKey,
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: PushButton(
        controlSize: ControlSize.large,
        secondary: widget.secondary,
        semanticLabel: widget.label,
        onPressed: _runMockAction,
        child: Text(widget.label),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: MacosTheme.of(context).primaryColor.withValues(alpha: 0.28),
        ),
      ),
      child: Text(label, style: MacosTheme.of(context).typography.caption1),
    );
  }
}
