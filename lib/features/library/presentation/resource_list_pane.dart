import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Searchable resources for the currently selected library category.
class ResourceListPane extends StatefulWidget {
  const ResourceListPane({
    required this.controller,
    required this.onResourceSelected,
    this.onToggleFavorite,
    this.onCreatePrompt,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<WorkbenchResource> onResourceSelected;
  final Future<void> Function(String resourceId)? onToggleFavorite;
  final Future<void> Function()? onCreatePrompt;

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
    if (normalizedQuery.isEmpty) {
      return widget.controller.selectedResources;
    }
    return widget.controller.selectedResources.where((resource) {
      return resource.title.toLowerCase().contains(normalizedQuery) ||
          resource.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final resources = _visibleResources;
    final typography = MacosTheme.of(context).typography;

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.controller.labelFor(widget.controller.selectedDestination),
              style: typography.title2,
            ),
            if (widget.onCreatePrompt != null) ...[
              const SizedBox(height: 8),
              PushButton(
                controlSize: ControlSize.large,
                semanticLabel: '新建提示词',
                onPressed: () => widget.onCreatePrompt!(),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('新建提示词'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Semantics(
              label: '搜索当前分类',
              textField: true,
              child: MacosSearchField(
                key: const ValueKey('resource-search'),
                focusNode: _searchFocusNode,
                placeholder: '搜索当前分类',
                onChanged: (query) => setState(() => _query = query),
              ),
            ),
            const SizedBox(height: 14),
            if (resources.isEmpty)
              Text('未找到匹配资源', style: typography.body)
            else
              for (final resource in resources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: PushButton(
                          controlSize: ControlSize.large,
                          semanticLabel: '选择资源：${resource.title}',
                          onPressed: () => widget.onResourceSelected(resource),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${resource.isFavorite ? '★ ' : ''}${resource.title}',
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  resource.subtitle,
                                  style: typography.caption1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (widget.onToggleFavorite != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: PushButton(
                            controlSize: ControlSize.small,
                            secondary: true,
                            semanticLabel: resource.isFavorite
                                ? '取消收藏：${resource.title}'
                                : '收藏：${resource.title}',
                            onPressed: () =>
                                widget.onToggleFavorite!(resource.id),
                            child: Text(resource.isFavorite ? '已收藏' : '收藏'),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
