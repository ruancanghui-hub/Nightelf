import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class VaultDropTarget extends StatefulWidget {
  const VaultDropTarget({
    super.key,
    required this.child,
    required this.onPathsDropped,
    this.preferredType,
    this.enabled = true,
    this.onDisabledDrop,
  });

  final Widget child;
  final Future<void> Function(List<String> paths) onPathsDropped;
  final ResourceType? preferredType;
  final bool enabled;
  final VoidCallback? onDisabledDrop;

  @override
  State<VaultDropTarget> createState() => _VaultDropTargetState();
}

class _VaultDropTargetState extends State<VaultDropTarget> {
  bool _dragging = false;

  String get _overlayLabel {
    final type = widget.preferredType;
    if (type == null) {
      return '释放以导入到工作台';
    }
    return '释放以导入到 ${_labelFor(type)}';
  }

  String _labelFor(ResourceType type) => switch (type) {
    ResourceType.prompt => 'AI 提示词',
    ResourceType.skill => 'SKILL 文件夹',
    ResourceType.mcp => 'MCP 配置',
    ResourceType.link => '网站链接',
    ResourceType.workflow => 'Workflow 文件',
    ResourceType.launcher => '启动器',
  };

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragEntered: (_) {
        if (!widget.enabled) {
          return;
        }
        setState(() => _dragging = true);
      },
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: (details) async {
        setState(() => _dragging = false);
        if (!widget.enabled) {
          widget.onDisabledDrop?.call();
          return;
        }
        final paths = details.files
            .map((file) => file.path)
            .where((path) => path.isNotEmpty)
            .toList(growable: false);
        if (paths.isEmpty) {
          return;
        }
        await widget.onPathsDropped(paths);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          if (_dragging)
            ColoredBox(
              color: MacosColors.controlAccentColor.withValues(alpha: 0.18),
              child: Center(
                child: Text(
                  _overlayLabel,
                  style: MacosTheme.of(context).typography.title1,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
