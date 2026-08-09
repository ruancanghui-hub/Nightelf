import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/metadata/presentation/collection_sidebar_section.dart';
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
    this.activeResourceId,
    this.collections = const [],
    this.onCollectionSelected,
    this.onCreateCollection,
    this.onEditCollection,
    this.compact = false,
    this.focusNode,
    super.key,
  });

  final WorkbenchController controller;
  final ValueChanged<ResourceType> onDestinationSelected;
  final ValueChanged<WorkbenchResource>? onResourceSelected;
  final String? activeResourceId;
  final List<CollectionRecord> collections;
  final ValueChanged<CollectionRecord?>? onCollectionSelected;
  final VoidCallback? onCreateCollection;
  final ValueChanged<CollectionRecord>? onEditCollection;
  final bool compact;
  final FocusNode? focusNode;

  static const _destinationGlyphs = <ResourceType, String>{
    ResourceType.aiPrompt: '提',
    ResourceType.skillFolder: '技',
    ResourceType.mcpConfiguration: '配',
    ResourceType.websiteLink: '链',
    ResourceType.workflowFile: '流',
  };

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;

    return Focus(
      focusNode: focusNode,
      child: Container(
        width: compact ? 72 : 248,
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 16,
          20,
          compact ? 8 : 16,
          16,
        ),
        decoration: BoxDecoration(
          color: MacosTheme.of(context).canvasColor,
          border: Border(
            right: BorderSide(color: MacosTheme.of(context).dividerColor),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!compact) Text('资源库', style: typography.headline),
            if (!compact) const SizedBox(height: 12),
            for (final type in ResourceType.values)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: WorkbenchFocusRing(
                  focusKey: ValueKey('sidebar-focus-${type.name}'),
                  indicatorKey: ValueKey(
                    'sidebar-focus-${type.name}-indicator',
                  ),
                  onActivate: () => onDestinationSelected(type),
                  child: MacosTooltip(
                    message: controller.labelFor(type),
                    child: PushButton(
                      controlSize: ControlSize.large,
                      color: type == controller.selectedDestination
                          ? MacosTheme.of(context).primaryColor
                          : null,
                      semanticLabel: '导航：${controller.labelFor(type)}',
                      onPressed: () => onDestinationSelected(type),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          compact
                              ? _destinationGlyphs[type]!
                              : controller.labelFor(type),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (!compact &&
                onCollectionSelected != null &&
                onCreateCollection != null &&
                onEditCollection != null) ...[
              const SizedBox(height: 18),
              CollectionSidebarSection(
                collections: collections,
                selectedCollectionId: controller.selectedCollectionId,
                onCollectionSelected: onCollectionSelected!,
                onCreateCollection: onCreateCollection!,
                onEditCollection: onEditCollection!,
              ),
            ],
            if (!compact) ...[
              const SizedBox(height: 18),
              Text('收藏', style: typography.subheadline),
              const SizedBox(height: 6),
              if (controller.favoriteResources.isEmpty)
                Text('暂无收藏', style: typography.caption1)
              else
                for (final resource in controller.favoriteResources.take(8))
                  _SidebarQuickAccessTile(
                    key: ValueKey('favorite-${resource.id}'),
                    label: '★ ${resource.title}',
                    semanticLabel: '收藏：${resource.title}',
                    selected: resource.id == activeResourceId,
                    onTap: onResourceSelected == null
                        ? null
                        : () => onResourceSelected!(resource),
                  ),
              const SizedBox(height: 18),
              Text('最近使用', style: typography.subheadline),
              const SizedBox(height: 6),
              if (controller.recentResources.isEmpty)
                Text('暂无最近使用', style: typography.caption1)
              else
                for (final resource in controller.recentResources.take(5))
                  _SidebarQuickAccessTile(
                    key: ValueKey('recent-${resource.id}'),
                    label: resource.title,
                    semanticLabel: '最近使用：${resource.title}',
                    selected: resource.id == activeResourceId,
                    onTap: onResourceSelected == null
                        ? null
                        : () => onResourceSelected!(resource),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clickable quick-access row with hover / pressed / selected feedback.
class _SidebarQuickAccessTile extends StatefulWidget {
  const _SidebarQuickAccessTile({
    required this.label,
    required this.semanticLabel,
    required this.selected,
    this.onTap,
    super.key,
  });

  final String label;
  final String semanticLabel;
  final bool selected;
  final VoidCallback? onTap;

  @override
  State<_SidebarQuickAccessTile> createState() =>
      _SidebarQuickAccessTileState();
}

class _SidebarQuickAccessTileState extends State<_SidebarQuickAccessTile> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final typography = theme.typography;
    final accent = theme.primaryColor;
    final selected = widget.selected;
    final highlight = _pressed || selected || _hovered;
    final background = selected
        ? accent.withValues(alpha: 0.22)
        : _pressed
        ? accent.withValues(alpha: 0.16)
        : _hovered
        ? accent.withValues(alpha: 0.10)
        : const Color(0x00000000);
    final borderColor = selected || _pressed
        ? accent.withValues(alpha: 0.55)
        : const Color(0x00000000);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        cursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() {
          _hovered = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.onTap == null
              ? null
              : (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor),
            ),
            child: Semantics(
              button: true,
              selected: selected,
              label: widget.semanticLabel,
              child: Text(
                widget.label,
                overflow: TextOverflow.ellipsis,
                style: typography.body.copyWith(
                  fontWeight: selected || _pressed
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: highlight ? accent : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
