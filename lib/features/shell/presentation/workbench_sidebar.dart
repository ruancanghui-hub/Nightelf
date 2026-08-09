import 'package:ai_workbench/features/shell/application/workbench_controller.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/features/shell/presentation/emerald_interactive_surface.dart';
import 'package:ai_workbench/features/shell/presentation/workbench_focus_ring.dart';
import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';
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
  final bool compact;
  final FocusNode? focusNode;

  static const _destinationIcons = <ResourceType, IconData>{
    ResourceType.aiPrompt: LucideIcons.messageCircle,
    ResourceType.skillFolder: LucideIcons.folder,
    ResourceType.mcpConfiguration: LucideIcons.slidersHorizontal,
    ResourceType.websiteLink: LucideIcons.globe,
    ResourceType.workflowFile: LucideIcons.workflow,
  };

  static IconData iconFor(ResourceType type) =>
      _destinationIcons[type] ?? LucideIcons.file;

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
            child: EmeraldInteractiveSurface(
              onTap: onPressed,
              selected: selected,
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
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
        ],
      ),
    );
  }

  Future<void> _showSettingsDialog(BuildContext context) {
    return showMacosAlertDialog<void>(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: HugeIcon(
          icon: HugeIcons.strokeRoundedSettings01,
          color: const Color(0xFF5DE7A7),
          size: 48,
        ),
        title: const Text('设置'),
        message: const Text('应用偏好与 Vault 本地设置入口即将推出。当前资源仍保存在本机 Vault 中。'),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ),
    );
  }

  Future<void> _showHelpDialog(BuildContext context) {
    return showMacosAlertDialog<void>(
      context: context,
      builder: (context) => MacosAlertDialog(
        appIcon: HugeIcon(
          icon: HugeIcons.strokeRoundedHelpCircle,
          color: const Color(0xFF5DE7A7),
          size: 48,
        ),
        title: const Text('帮助'),
        message: const Text(
          '暗夜精灵是本地优先的 AI 资源工作台。用左侧栏目管理提示词、SKILL、MCP、网站链接与 Workflow；从「最近打开」可快速回到常用资源。',
        ),
        primaryButton: PushButton(
          controlSize: ControlSize.large,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('知道了'),
        ),
      ),
    );
  }

  Future<void> _showAllRecent(BuildContext context) {
    final resources = controller.recentResources;
    return showMacosAlertDialog<void>(
      context: context,
      builder: (dialogContext) {
        return MacosAlertDialog(
          appIcon: const Icon(
            LucideIcons.history,
            color: Color(0xFF5DE7A7),
            size: 40,
          ),
          title: const Text('全部最近打开'),
          message: SizedBox(
            width: 420,
            height: 280,
            child: resources.isEmpty
                ? const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('暂无最近打开'),
                  )
                : ListView.builder(
                    itemCount: resources.length,
                    itemBuilder: (context, index) {
                      final resource = resources[index];
                      return _SidebarRecentTile(
                        resource: resource,
                        relativeTime: formatRelativeOpenedAt(
                          controller.recentOpenedAt(resource.id),
                        ),
                        selected: resource.id == activeResourceId,
                        dense: true,
                        onTap: () {
                          Navigator.of(dialogContext).pop();
                          onResourceSelected?.call(resource);
                        },
                      );
                    },
                  ),
          ),
          primaryButton: PushButton(
            controlSize: ControlSize.large,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('关闭'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final recentPreview = controller.recentResources.take(5).toList();

    return Focus(
      focusNode: focusNode,
      child: Container(
        width: width ?? (compact ? 72 : 248),
        padding: EdgeInsets.fromLTRB(
          compact ? 8 : 16,
          compact ? 20 : 39,
          compact ? 8 : 16,
          12,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF030B09),
          border: Border(right: BorderSide(color: Color(0xFF1B4D40))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!compact) ...[
                      Row(
                        children: [
                          Image.asset(
                            'assets/nightelf-logo.png',
                            key: const ValueKey('nightelf-sidebar-logo'),
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                            semanticLabel: 'Nightelf Logo',
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              '暗夜精灵 · AI 工作台',
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
                              selected:
                                  !overviewSelected &&
                                  type == controller.selectedDestination,
                              compact: compact,
                              visual: compact
                                  ? Icon(iconFor(type))
                                  : Row(
                                      children: [
                                        Icon(iconFor(type)),
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
                    if (!compact) ...[
                      const SizedBox(height: 18),
                      const SizedBox(
                        height: 1,
                        child: ColoredBox(color: Color(0xFF123127)),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        '最近打开',
                        style: TextStyle(
                          color: Color(0xFF9BB4AB),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (recentPreview.isEmpty)
                        const Text(
                          '暂无最近打开',
                          style: TextStyle(
                            color: Color(0xFF7F9A90),
                            fontSize: 12,
                          ),
                        )
                      else
                        for (final resource in recentPreview)
                          _SidebarRecentTile(
                            key: ValueKey('recent-${resource.id}'),
                            resource: resource,
                            relativeTime: formatRelativeOpenedAt(
                              controller.recentOpenedAt(resource.id),
                            ),
                            selected: resource.id == activeResourceId,
                            onTap: onResourceSelected == null
                                ? null
                                : () => onResourceSelected!(resource),
                          ),
                      if (controller.recentResources.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _showAllRecent(context),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '查看全部最近打开',
                                    style: TextStyle(
                                      color: Color(0xFF9BB4AB),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  LucideIcons.chevronRight,
                                  size: 14,
                                  color: Color(0xFF9BB4AB),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 8),
              const SizedBox(
                height: 1,
                child: ColoredBox(color: Color(0xFF123127)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _SidebarUtilityButton(
                    key: const ValueKey('sidebar-settings'),
                    semanticLabel: '设置',
                    tooltip: '设置',
                    icon: HugeIcons.strokeRoundedSettings01,
                    onPressed: () => _showSettingsDialog(context),
                  ),
                  const SizedBox(width: 4),
                  _SidebarUtilityButton(
                    key: const ValueKey('sidebar-help'),
                    semanticLabel: '帮助',
                    tooltip: '帮助',
                    icon: HugeIcons.strokeRoundedHelpCircle,
                    onPressed: () => _showHelpDialog(context),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formats a recent-open timestamp into short Chinese relative text.
String formatRelativeOpenedAt(DateTime? openedAt, {DateTime? now}) {
  if (openedAt == null) {
    return '最近';
  }
  final current = now ?? DateTime.now();
  final local = openedAt.toLocal();
  final diff = current.difference(local);
  if (diff.inSeconds < 60) {
    return '刚刚';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} 分钟前';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours} 小时前';
  }
  final startOfToday = DateTime(current.year, current.month, current.day);
  final startOfOpened = DateTime(local.year, local.month, local.day);
  final dayDiff = startOfToday.difference(startOfOpened).inDays;
  if (dayDiff == 1) {
    return '昨天';
  }
  if (dayDiff < 7) {
    return '$dayDiff 天前';
  }
  return '${local.month}/${local.day}';
}

class _SidebarRecentTile extends StatelessWidget {
  const _SidebarRecentTile({
    required this.resource,
    required this.relativeTime,
    required this.selected,
    this.onTap,
    this.dense = false,
    super.key,
  });

  final WorkbenchResource resource;
  final String relativeTime;
  final bool selected;
  final VoidCallback? onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: dense ? 2 : 4),
      child: EmeraldInteractiveSurface(
        onTap: onTap,
        selected: selected,
        borderRadius: BorderRadius.circular(6),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 6 : 8,
          vertical: dense ? 6 : 7,
        ),
        child: Semantics(
          button: true,
          selected: selected,
          label: '最近打开：${resource.title}',
          child: Row(
            children: [
              Icon(
                WorkbenchSidebar.iconFor(resource.type),
                size: 15,
                color: const Color(0xFF9FC1B4),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resource.title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFE1F1EA),
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                relativeTime,
                style: const TextStyle(
                  color: Color(0xFF7F9A90),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SidebarUtilityButton extends StatelessWidget {
  const _SidebarUtilityButton({
    required this.semanticLabel,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    super.key,
  });

  final String semanticLabel;
  final String tooltip;
  final List<List<dynamic>> icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: semanticLabel,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: HugeIcon(
              icon: icon,
              color: const Color(0xFF9FC1B4),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
