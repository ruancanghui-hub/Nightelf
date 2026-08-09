import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';

/// Raycast-style command / resource row for the command palette.
class WorkbenchCommandTile extends StatefulWidget {
  const WorkbenchCommandTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool enabled;

  @override
  State<WorkbenchCommandTile> createState() => _WorkbenchCommandTileState();
}

class _WorkbenchCommandTileState extends State<WorkbenchCommandTile> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled && widget.onTap != null;
    final highlighted = _hovered && enabled;

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.title,
      container: true,
      excludeSemantics: true,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: highlighted
                  ? const Color(0xFF0C2B23)
                  : const Color(0x00000000),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                if (widget.leading != null) ...[
                  IconTheme(
                    data: const IconThemeData(
                      color: WorkbenchUiTokens.muted,
                      size: 18,
                    ),
                    child: widget.leading!,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: enabled
                              ? WorkbenchUiTokens.foreground
                              : WorkbenchUiTokens.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (widget.subtitle != null &&
                          widget.subtitle!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: WorkbenchUiTokens.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: 10),
                  DefaultTextStyle(
                    style: const TextStyle(
                      color: WorkbenchUiTokens.muted,
                      fontSize: 12,
                    ),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Muted section header used above command palette groups.
class WorkbenchCommandSectionLabel extends StatelessWidget {
  const WorkbenchCommandSectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: WorkbenchUiTokens.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
