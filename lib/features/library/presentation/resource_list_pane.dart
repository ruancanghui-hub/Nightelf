import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

/// Searchable resources for the currently selected library category.
class ResourceListPane extends StatefulWidget {
  const ResourceListPane({
    required this.controller,
    required this.onResourceSelected,
    this.onToggleFavorite,
    this.onDeleteResource,
    this.onCreatePrompt,
    this.onDuplicatePrompt,
    this.onImportSkill,
    this.onCreateMcp,
    this.onCreateLink,
    this.onPasteLink,
    this.onCreateWorkflow,
    this.onImportWorkflow,
    this.onCreateLauncher,
    this.title,
    this.resources,
    this.searchPlaceholder,
    this.emptyMessage,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<WorkbenchResource> onResourceSelected;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final Future<void> Function(WorkbenchResource resource)? onDeleteResource;
  final Future<void> Function()? onCreatePrompt;
  final Future<void> Function(WorkbenchResource resource)? onDuplicatePrompt;
  final Future<void> Function()? onImportSkill;
  final Future<void> Function()? onCreateMcp;
  final Future<void> Function()? onCreateLink;
  final Future<void> Function()? onPasteLink;
  final Future<void> Function()? onCreateWorkflow;
  final Future<void> Function()? onImportWorkflow;
  final Future<void> Function()? onCreateLauncher;
  final String? title;
  final List<WorkbenchResource>? resources;
  final String? searchPlaceholder;
  final String? emptyMessage;

  @override
  State<ResourceListPane> createState() => _ResourceListPaneState();
}

class _ResourceListPaneState extends State<ResourceListPane> {
  final FocusNode _searchFocusNode = FocusNode(debugLabel: 'resource-search');
  String _query = '';

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<WorkbenchResource> get _visibleResources {
    final normalizedQuery = _query.trim().toLowerCase();
    final source = widget.resources ?? widget.controller.selectedResources;
    if (normalizedQuery.isEmpty) {
      return source;
    }
    return source.where((resource) {
      return resource.title.toLowerCase().contains(normalizedQuery) ||
          resource.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Widget _actionButton({
    required String semanticLabel,
    required VoidCallback onPressed,
    required String label,
    WorkbenchButtonVariant variant = WorkbenchButtonVariant.primary,
  }) {
    return WorkbenchButton(
      size: WorkbenchButtonSize.lg,
      variant: variant,
      expands: true,
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      child: Align(alignment: Alignment.centerLeft, child: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resources = _visibleResources;
    final typography = MacosTheme.of(context).typography;

    return SizedBox(
      width: 320,
      child: ClipRect(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: Color(0xFF123127))),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.title ??
                      widget.controller.labelFor(
                        widget.controller.selectedDestination,
                      ),
                  style: typography.title2,
                ),
                if (widget.onCreatePrompt != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '新建提示词',
                    onPressed: () => widget.onCreatePrompt!(),
                    label: '新建提示词',
                  ),
                ],
                if (widget.onImportSkill != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '导入 SKILL 文件夹',
                    onPressed: () => widget.onImportSkill!(),
                    label: '导入 SKILL 文件夹',
                  ),
                ],
                if (widget.onCreateMcp != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '新建 MCP 配置',
                    onPressed: () => widget.onCreateMcp!(),
                    label: '新建 MCP 配置',
                  ),
                ],
                if (widget.onPasteLink != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '从剪贴板粘贴链接',
                    onPressed: () => widget.onPasteLink!(),
                    label: '从剪贴板粘贴链接',
                  ),
                ],
                if (widget.onCreateLink != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '新建空链接',
                    onPressed: () => widget.onCreateLink!(),
                    label: '新建空链接',
                    variant: WorkbenchButtonVariant.outline,
                  ),
                ],
                if (widget.onCreateWorkflow != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '新建 Workflow',
                    onPressed: () => widget.onCreateWorkflow!(),
                    label: '新建 Workflow',
                  ),
                ],
                if (widget.onImportWorkflow != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '导入 Workflow 文件',
                    onPressed: () => widget.onImportWorkflow!(),
                    label: '导入 Workflow 文件',
                    variant: WorkbenchButtonVariant.outline,
                  ),
                ],
                if (widget.onCreateLauncher != null) ...[
                  const SizedBox(height: 8),
                  _actionButton(
                    semanticLabel: '新建启动器',
                    onPressed: () => widget.onCreateLauncher!(),
                    label: '新建启动器',
                  ),
                ],
                const SizedBox(height: 12),
                WorkbenchInput(
                  key: const ValueKey('resource-search'),
                  focusNode: _searchFocusNode,
                  placeholder: widget.searchPlaceholder ?? '搜索当前分类',
                  semanticLabel: widget.searchPlaceholder ?? '搜索当前分类',
                  onChanged: (query) => setState(() => _query = query),
                ),
                const SizedBox(height: 14),
                if (resources.isEmpty)
                  Text(
                    widget.onCreatePrompt != null
                        ? '暂无提示词，点击上方「新建提示词」后可粘贴内容。'
                        : widget.onImportSkill != null
                        ? '暂无 SKILL，点击上方「导入 SKILL 文件夹」开始。'
                        : widget.onCreateMcp != null
                        ? '暂无 MCP 配置，点击上方「新建 MCP 配置」开始。'
                        : widget.onPasteLink != null
                        ? '暂无网站链接，先复制网址再点「从剪贴板粘贴链接」。'
                        : widget.onCreateWorkflow != null
                        ? '暂无 Workflow，点击上方「新建 Workflow」开始。'
                        : widget.emptyMessage ?? '未找到匹配资源',
                    style: typography.body,
                  )
                else
                  Expanded(
                    child: ListView(
                      children: [
                        for (final resource in resources)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: WorkbenchCard(
                              key: ValueKey(
                                'resource-list-item-${resource.id}',
                              ),
                              selected:
                                  widget.controller.selectedResource.id ==
                                  resource.id,
                              semanticLabel: '选择资源：${resource.title}',
                              onTap: () => widget.onResourceSelected(resource),
                              title: Text(
                                '${resource.isFavorite ? '★ ' : ''}${resource.title}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              description: Text(
                                resource.relativePath?.isNotEmpty == true
                                    ? resource.relativePath!
                                    : resource.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (widget.onDuplicatePrompt != null)
                                    WorkbenchIconButton(
                                      width: 28,
                                      height: 28,
                                      iconSize: 15,
                                      variant: WorkbenchButtonVariant.ghost,
                                      tooltip: '复制文件',
                                      semanticLabel: '复制文件：${resource.title}',
                                      onPressed: () =>
                                          widget.onDuplicatePrompt!(resource),
                                      icon: const Icon(LucideIcons.copy),
                                    ),
                                  if (widget.onToggleFavorite != null)
                                    WorkbenchIconButton(
                                      width: 28,
                                      height: 28,
                                      iconSize: 15,
                                      variant: WorkbenchButtonVariant.ghost,
                                      tooltip: resource.isFavorite
                                          ? '取消收藏'
                                          : '收藏',
                                      semanticLabel: resource.isFavorite
                                          ? '取消收藏：${resource.title}'
                                          : '收藏：${resource.title}',
                                      onPressed: () =>
                                          widget.onToggleFavorite!(resource.id),
                                      icon: Icon(
                                        resource.isFavorite
                                            ? LucideIcons.star
                                            : LucideIcons.starOff,
                                        color: WorkbenchUiTokens.emerald,
                                      ),
                                    ),
                                  if (widget.onDeleteResource != null)
                                    WorkbenchIconButton(
                                      width: 28,
                                      height: 28,
                                      iconSize: 15,
                                      variant: WorkbenchButtonVariant.ghost,
                                      tooltip: '删除',
                                      semanticLabel: '删除资源：${resource.title}',
                                      onPressed: () =>
                                          widget.onDeleteResource!(resource),
                                      icon: const Icon(
                                        LucideIcons.trash2,
                                        color: Color(0xFFE35D6A),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
