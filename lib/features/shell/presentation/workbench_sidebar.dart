import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/metadata/presentation/collection_sidebar_section.dart';
import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_focus_ring.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:macos_ui/macos_ui.dart';

/// Navigation and deterministic quick-access sections for the shell.
class WorkbenchSidebar extends StatelessWidget {
  const WorkbenchSidebar({
    required this.controller,
    required this.onDestinationSelected,
    this.width,
    this.overviewSelected = false,
    this.onOverviewSelected,
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
  final double? width;
  final bool overviewSelected;
  final VoidCallback? onOverviewSelected;
  final ValueChanged<WorkbenchResource>? onResourceSelected;
  final String? activeResourceId;
  final List<CollectionRecord> collections;
  final ValueChanged<CollectionRecord?>? onCollectionSelected;
  final VoidCallback? onCreateCollection;
  final ValueChanged<CollectionRecord>? onEditCollection;
  final bool compact;
  final FocusNode? focusNode;

  static const _destinationIcons = <ResourceType, IconData>{
    ResourceType.aiPrompt: LucideIcons.messageCircle,
    ResourceType.skillFolder: LucideIcons.folder,
    ResourceType.mcpConfiguration: LucideIcons.slidersHorizontal,
    ResourceType.websiteLink: LucideIcons.globe,
    ResourceType.workflowFile: LucideIcons.workflow,
  };

  /// Keeps a real PushButton in the tree for keyboard/accessibility contracts,
  /// while painting the reference's flat emerald navigation treatment above
  /// the native macOS button chrome.
  Widget _flatNavigationButton({
    required String semanticLabel,
    required Widget visual,
    required VoidCallback? onPressed,
    required bool selected,
    required bool compact,
  }) {
    const accent = Color(0xFF5DE7A7);
    return SizedBox(
      height: 36,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0,
            child: PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              semanticLabel: semanticLabel,
              onPressed: onPressed,
              child: const SizedBox.shrink(),
            ),
          ),
          Semantics(
            button: true,
            enabled: onPressed != null,
            label: semanticLabel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onPressed,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFF0C2B23)
                      : const Color(0x00000000),
                  border: Border.all(
                    color: selected ? accent : const Color(0x00000000),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DefaultTextStyle(
                    style: const TextStyle(
                      color: Color(0xFFE1F1EA),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    child: IconTheme(
                      data: const IconThemeData(
                        color: Color(0xFF9FC1B4),
                        size: 17,
                      ),
                      child: visual,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    const accent = Color(0xFF5DE7A7);

    return Focus(
      focusNode: focusNode,
      child: Container(
        width: width ?? (compact ? 72 : 248),
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 16,
          compact ? 20 : 39,
          compact ? 8 : 16,
          16,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF030B09),
          border: Border(right: const BorderSide(color: Color(0xFF1B4D40))),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!compact) ...[
                const Row(
                  children: [
                    Icon(LucideIcons.leafyGreen, color: accent, size: 34),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Nightelf · AI 工作台',
                        style: TextStyle(
                          color: Color(0xFFF2FFF8),
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
              ],
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: WorkbenchFocusRing(
                  focusKey: const ValueKey('sidebar-focus-overview'),
                  indicatorKey: const ValueKey(
                    'sidebar-focus-overview-indicator',
                  ),
                  onActivate: onOverviewSelected ?? () {},
                  child: MacosTooltip(
                    message: '概览',
                    child: _flatNavigationButton(
                      semanticLabel: '导航：概览',
                      onPressed: onOverviewSelected,
                      selected: overviewSelected,
                      compact: compact,
                      visual: compact
                          ? const Icon(LucideIcons.house)
                          : const Row(
                              children: [
                                Icon(LucideIcons.house),
                                SizedBox(width: 10),
                                Text('概览'),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
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
                      child: _flatNavigationButton(
                        semanticLabel: '导航：${controller.labelFor(type)}',
                        onPressed: () => onDestinationSelected(type),
                        selected: false,
                        compact: compact,
                        visual: compact
                            ? Icon(_destinationIcons[type])
                            : Row(
                                children: [
                                  Icon(_destinationIcons[type]),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      controller.labelFor(type),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
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
                const SizedBox(
                  height: 1,
                  child: ColoredBox(color: Color(0xFF123127)),
                ),
                const SizedBox(height: 10),
                Text(
                  '最近打开',
                  style: typography.subheadline.copyWith(
                    color: const Color(0xFF9BB4AB),
                  ),
                ),
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
