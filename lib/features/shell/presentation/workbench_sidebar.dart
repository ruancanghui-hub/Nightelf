import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_focus_ring.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Navigation and deterministic quick-access sections for the shell.
class WorkbenchSidebar extends StatelessWidget {
  const WorkbenchSidebar({
    required this.controller,
    required this.onDestinationSelected,
    this.onResourceSelected,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<ResourceType> onDestinationSelected;
  final ValueChanged<WorkbenchResource>? onResourceSelected;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Container(
      width: 248,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        border: Border(
          right: BorderSide(color: MacosTheme.of(context).dividerColor),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('资源库', style: typography.headline),
          const SizedBox(height: 12),
          for (final type in ResourceType.values)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: WorkbenchFocusRing(
                focusKey: ValueKey('sidebar-focus-${type.name}'),
                indicatorKey: ValueKey('sidebar-focus-${type.name}-indicator'),
                onActivate: () => onDestinationSelected(type),
                child: PushButton(
                  controlSize: ControlSize.large,
                  color: type == controller.selectedDestination
                      ? MacosTheme.of(context).primaryColor
                      : null,
                  semanticLabel: '导航：${controller.labelFor(type)}',
                  onPressed: () => onDestinationSelected(type),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(controller.labelFor(type)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          Text('收藏', style: typography.subheadline),
          const SizedBox(height: 6),
          if (controller.favoriteResources.isEmpty)
            Text('暂无收藏', style: typography.caption1)
          else
            for (final resource in controller.favoriteResources.take(8))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: GestureDetector(
                  onTap: onResourceSelected == null
                      ? null
                      : () => onResourceSelected!(resource),
                  child: Text(
                    '★ ${resource.title}',
                    overflow: TextOverflow.ellipsis,
                    style: typography.body,
                  ),
                ),
              ),
          const SizedBox(height: 18),
          Text('最近使用', style: typography.subheadline),
          const SizedBox(height: 6),
          for (final resource in controller.recentResources.take(2))
            Text(resource.title, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
