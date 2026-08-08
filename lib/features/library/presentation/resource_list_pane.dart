import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Searchable mock resources for the currently selected library category.
class ResourceListPane extends StatefulWidget {
  const ResourceListPane({
    required this.controller,
    required this.onResourceSelected,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<WorkbenchResource> onResourceSelected;

  @override
  State<ResourceListPane> createState() => _ResourceListPaneState();
}

class _ResourceListPaneState extends State<ResourceListPane> {
  String _query = '';

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

    return SizedBox(
      width: 320,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.controller.labelFor(widget.controller.selectedDestination),
              style: MacosTheme.of(context).typography.title2,
            ),
            const SizedBox(height: 12),
            Semantics(
              label: '搜索当前分类',
              textField: true,
              child: MacosSearchField(
                placeholder: '搜索当前分类',
                onChanged: (query) => setState(() => _query = query),
              ),
            ),
            const SizedBox(height: 14),
            if (resources.isEmpty)
              Text('未找到匹配资源', style: MacosTheme.of(context).typography.body)
            else
              for (final resource in resources)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PushButton(
                    controlSize: ControlSize.large,
                    semanticLabel: '选择资源：${resource.title}',
                    onPressed: () => widget.onResourceSelected(resource),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(resource.title),
                          const SizedBox(height: 2),
                          Text(
                            resource.subtitle,
                            style: MacosTheme.of(context).typography.caption1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
