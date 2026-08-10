import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// App-level card with optional title / description / trailing actions.
///
/// Title and description take remaining width with ellipsis; trailing stays
/// compact on the right so action icons do not crush long titles.
class WorkbenchCard extends StatelessWidget {
  const WorkbenchCard({
    this.title,
    this.description,
    this.trailing,
    this.child,
    this.onTap,
    this.selected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.semanticLabel,
    super.key,
  });

  final Widget? title;
  final Widget? description;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasHeader = title != null || description != null || trailing != null;

    Widget card = DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF0C2B23) : WorkbenchUiTokens.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? WorkbenchUiTokens.emerald : WorkbenchUiTokens.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasHeader)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (title != null || description != null)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (title != null)
                            DefaultTextStyle(
                              style: theme.textTheme.small.copyWith(
                                color: selected
                                    ? WorkbenchUiTokens.foreground
                                    : WorkbenchUiTokens.emerald,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: title!,
                            ),
                          if (title != null && description != null)
                            const SizedBox(height: 4),
                          if (description != null)
                            DefaultTextStyle(
                              style: theme.textTheme.muted.copyWith(
                                color: WorkbenchUiTokens.muted,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              child: description!,
                            ),
                        ],
                      ),
                    ),
                  if (trailing != null) ...[
                    if (title != null || description != null)
                      const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            if (hasHeader && child != null) const SizedBox(height: 10),
            ?child,
          ],
        ),
      ),
    );

    if (onTap != null) {
      card = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }
    if (semanticLabel == null) {
      return card;
    }
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      container: true,
      child: card,
    );
  }
}
