import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/data/file_document_storage.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:ai_workbench/features/editor/domain/document_path_resolver.dart';
import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/metadata/application/metadata_controller.dart';
import 'package:ai_workbench/features/metadata/presentation/metadata_inspector.dart';
import 'package:ai_workbench/features/prompts/application/prompt_controller.dart';
import 'package:ai_workbench/features/prompts/presentation/prompt_workspace.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/workspaces/presentation/mcp_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/skill_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/website_workspace.dart';
import 'package:ai_workbench/features/workspaces/presentation/workflow_workspace.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Chooses a live editor for Vault-backed resources, otherwise a mock surface.
class WorkspaceContent extends StatelessWidget {
  const WorkspaceContent({
    required this.resource,
    this.vaultRootPath,
    this.onToggleFavorite,
    this.metadataController,
    this.promptController,
    this.allResources = const [],
    this.onOpenRelated,
    this.showInspector = true,
    this.contentFocusNode,
    super.key,
  });

  final WorkbenchResource? resource;
  final String? vaultRootPath;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final MetadataController? metadataController;
  final PromptController? promptController;
  final List<WorkbenchResource> allResources;
  final ValueChanged<WorkbenchResource>? onOpenRelated;
  final bool showInspector;
  final FocusNode? contentFocusNode;

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

    final vaultRoot = vaultRootPath;
    final descriptor = vaultRoot == null
        ? null
        : documentDescriptorFor(resource: resource, vaultRootPath: vaultRoot);
    final presentation = _presentationFor(
      resource.type,
      hasLiveEditor: descriptor != null,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Focus(
        focusNode: contentFocusNode,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WorkspaceHeader(resource: resource, presentation: presentation),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final usePromptWorkspace =
                      resource.type == ResourceType.aiPrompt &&
                      promptController != null &&
                      vaultRoot != null &&
                      resource.relativePath != null;
                  final surface = usePromptWorkspace
                      ? PromptWorkspace(controller: promptController)
                      : descriptor == null
                      ? presentation.surface
                      : _LiveDocumentEditor(
                          key: ValueKey(
                            '${resource.id}:${descriptor.absolutePath}',
                          ),
                          descriptor: descriptor,
                          title: _editorTitleFor(resource.type),
                        );

                  final inspector = showInspector
                      ? _buildInspector(
                          resource: resource,
                          presentation: presentation,
                        )
                      : null;

                  if (!showInspector || constraints.maxWidth < 680) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (descriptor == null)
                            surface
                          else
                            SizedBox(height: 420, child: surface),
                          if (inspector != null) ...[
                            const SizedBox(height: 16),
                            inspector,
                          ],
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
                          child: surface,
                        ),
                      ),
                      SizedBox(
                        width: 280,
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
                          child: inspector,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspector({
    required WorkbenchResource resource,
    required _WorkspacePresentation presentation,
  }) {
    final metadata = metadataController;
    if (presentation.live && metadata != null) {
      return MetadataInspector(
        resource: resource,
        typeLabel: presentation.typeLabel,
        statusLabel: presentation.status,
        metadataController: metadata,
        allResources: allResources,
        onOpenRelated: onOpenRelated,
      );
    }
    return _WorkspaceInspector(
      resource: resource,
      presentation: presentation,
      onToggleFavorite: onToggleFavorite,
    );
  }

  String _editorTitleFor(ResourceType type) => switch (type) {
    ResourceType.aiPrompt => '提示词源码',
    ResourceType.skillFolder => 'SKILL.md',
    ResourceType.mcpConfiguration => 'MCP 配置',
    ResourceType.websiteLink => '链接内容',
    ResourceType.workflowFile => 'Workflow 源码',
  };

  _WorkspacePresentation _presentationFor(
    ResourceType type, {
    required bool hasLiveEditor,
  }) => switch (type) {
    ResourceType.aiPrompt => _WorkspacePresentation(
      typeLabel: 'AI 提示词',
      status: hasLiveEditor ? '可编辑 · 自动保存' : '模拟草稿 · 未写入磁盘',
      primaryAction: hasLiveEditor ? '保存' : '保存模拟版本',
      secondaryAction: '预览模拟变更',
      surface: const PromptWorkspace(),
      live: hasLiveEditor,
    ),
    ResourceType.skillFolder => _WorkspacePresentation(
      typeLabel: 'SKILL 文件夹',
      status: hasLiveEditor ? '编辑 SKILL.md · 自动保存' : '模拟草稿 · 未写入磁盘',
      primaryAction: hasLiveEditor ? '保存' : '保存模拟版本',
      secondaryAction: '检查模拟结构',
      surface: const SkillWorkspace(),
      live: hasLiveEditor,
    ),
    ResourceType.mcpConfiguration => _WorkspacePresentation(
      typeLabel: 'MCP 配置',
      status: hasLiveEditor ? '可编辑 · 自动保存' : '只读 · 未连接服务',
      primaryAction: hasLiveEditor ? '保存' : '检查模拟语法',
      secondaryAction: '查看模拟详情',
      surface: const McpWorkspace(),
      live: hasLiveEditor,
    ),
    ResourceType.websiteLink => _WorkspacePresentation(
      typeLabel: '网站链接',
      status: hasLiveEditor ? '可编辑 · 自动保存' : '静态预览 · 无网络',
      primaryAction: hasLiveEditor ? '保存' : '保存模拟快照',
      secondaryAction: '查看模拟信息',
      surface: const WebsiteWorkspace(),
      live: hasLiveEditor,
    ),
    ResourceType.workflowFile => _WorkspacePresentation(
      typeLabel: 'Workflow 文件',
      status: hasLiveEditor ? '可编辑 · 自动保存' : '未执行 · 视觉模拟',
      primaryAction: hasLiveEditor ? '保存' : '保存模拟版本',
      secondaryAction: '检查模拟流程',
      surface: const WorkflowWorkspace(),
      live: hasLiveEditor,
    ),
  };
}

class _LiveDocumentEditor extends StatefulWidget {
  const _LiveDocumentEditor({
    super.key,
    required this.descriptor,
    required this.title,
  });

  final DocumentDescriptor descriptor;
  final String title;

  @override
  State<_LiveDocumentEditor> createState() => _LiveDocumentEditorState();
}

class _LiveDocumentEditorState extends State<_LiveDocumentEditor> {
  late final DocumentSession _session;

  @override
  void initState() {
    super.initState();
    _session = DocumentSession(
      descriptor: widget.descriptor,
      storage: FileDocumentStorage(),
    )..load();
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextEditorWorkspace(session: _session, title: widget.title);
  }
}

class _WorkspacePresentation {
  const _WorkspacePresentation({
    required this.typeLabel,
    required this.status,
    required this.primaryAction,
    required this.secondaryAction,
    required this.surface,
    required this.live,
  });

  final String typeLabel;
  final String status;
  final String primaryAction;
  final String secondaryAction;
  final Widget surface;
  final bool live;
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
    this.onToggleFavorite,
  });

  final WorkbenchResource resource;
  final _WorkspacePresentation presentation;
  final Future<void> Function(String resourceId)? onToggleFavorite;

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
          Text(presentation.live ? '数据源：Vault 文件' : '数据源：模拟资源'),
          if (resource.relativePath != null) ...[
            const SizedBox(height: 8),
            Text('路径：${resource.relativePath}'),
          ],
          const SizedBox(height: 16),
          _StatusPill(label: presentation.status),
          const SizedBox(height: 20),
          if (presentation.live && onToggleFavorite != null) ...[
            PushButton(
              controlSize: ControlSize.large,
              semanticLabel: resource.isFavorite
                  ? '取消收藏：${resource.title}'
                  : '收藏：${resource.title}',
              onPressed: () => onToggleFavorite!(resource.id),
              child: Text(resource.isFavorite ? '取消收藏' : '加入收藏'),
            ),
            const SizedBox(height: 12),
            Text(
              '收藏保存在当前 Vault 内，换库不会共享。',
              style: MacosTheme.of(context).typography.caption1,
            ),
            const SizedBox(height: 12),
            Text(
              '编辑会在约 0.6 秒后自动保存，也可按 ⌘S。',
              style: MacosTheme.of(context).typography.caption1,
            ),
          ] else if (!presentation.live) ...[
            _DisabledWorkspaceAction(label: presentation.primaryAction),
            const SizedBox(height: 8),
            _DisabledWorkspaceAction(
              label: presentation.secondaryAction,
              secondary: true,
            ),
            const SizedBox(height: 12),
            Text(
              '所有操作均为视觉模拟，不会读写或执行资源。',
              style: MacosTheme.of(context).typography.caption1,
            ),
          ] else
            Text(
              '编辑会在约 0.6 秒后自动保存，也可按 ⌘S。',
              style: MacosTheme.of(context).typography.caption1,
            ),
        ],
      ),
    );
  }
}

class _DisabledWorkspaceAction extends StatelessWidget {
  const _DisabledWorkspaceAction({required this.label, this.secondary = false});

  final String label;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    const tooltip = '视觉占位：操作尚未接入';
    return MacosTooltip(
      message: tooltip,
      child: Semantics(
        label: '$label：$tooltip',
        button: true,
        enabled: false,
        child: PushButton(
          controlSize: ControlSize.large,
          secondary: secondary,
          semanticLabel: label,
          onPressed: null,
          child: Text(label),
        ),
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
