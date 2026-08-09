import 'package:ai_workbench/shared/ui/workbench_shad_scope.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// App-level card wrapper over [ShadCard], with selected / outline states.
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
    final card = ShadCard(
      padding: padding,
      backgroundColor: selected
          ? const Color(0xFF0C2B23)
          : WorkbenchUiTokens.canvas,
      border: ShadBorder.all(
        color: selected ? WorkbenchUiTokens.emerald : WorkbenchUiTokens.border,
        width: 1,
      ),
      radius: BorderRadius.circular(12),
      shadows: const [],
      rowMainAxisSize: MainAxisSize.max,
      rowMainAxisAlignment: MainAxisAlignment.spaceBetween,
      rowCrossAxisAlignment: CrossAxisAlignment.center,
      title: title == null
          ? null
          : DefaultTextStyle(
              style: theme.textTheme.small.copyWith(
                color: selected
                    ? WorkbenchUiTokens.foreground
                    : WorkbenchUiTokens.emerald,
                fontWeight: FontWeight.w600,
              ),
              child: title!,
            ),
      description: description == null
          ? null
          : DefaultTextStyle(
              style: theme.textTheme.muted.copyWith(
                color: WorkbenchUiTokens.muted,
                fontSize: 12,
              ),
              child: description!,
            ),
      trailing: trailing,
      child: child,
    );

    Widget result = card;
    if (onTap != null) {
      result = MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: card,
        ),
      );
    }
    if (semanticLabel == null) {
      return result;
    }
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: semanticLabel,
      container: true,
      child: result,
    );
  }
}
