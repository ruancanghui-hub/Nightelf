import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

enum WorkbenchButtonVariant {
  primary,
  secondary,
  outline,
  ghost,
  destructive,
}

enum WorkbenchButtonSize { regular, sm, lg }

/// App-level button wrapper over [ShadButton] variants.
class WorkbenchButton extends StatelessWidget {
  const WorkbenchButton({
    required this.child,
    this.onPressed,
    this.leading,
    this.trailing,
    this.variant = WorkbenchButtonVariant.primary,
    this.size = WorkbenchButtonSize.regular,
    this.semanticLabel,
    this.expands = false,
    this.enabled,
    super.key,
  });

  final Widget child;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onPressed;
  final WorkbenchButtonVariant variant;
  final WorkbenchButtonSize size;
  final String? semanticLabel;
  final bool expands;
  final bool? enabled;

  ShadButtonVariant get _shadVariant => switch (variant) {
    WorkbenchButtonVariant.primary => ShadButtonVariant.primary,
    WorkbenchButtonVariant.secondary => ShadButtonVariant.secondary,
    WorkbenchButtonVariant.outline => ShadButtonVariant.outline,
    WorkbenchButtonVariant.ghost => ShadButtonVariant.ghost,
    WorkbenchButtonVariant.destructive => ShadButtonVariant.destructive,
  };

  ShadButtonSize get _shadSize => switch (size) {
    WorkbenchButtonSize.regular => ShadButtonSize.regular,
    WorkbenchButtonSize.sm => ShadButtonSize.sm,
    WorkbenchButtonSize.lg => ShadButtonSize.lg,
  };

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled ?? onPressed != null;
    final button = ShadButton.raw(
      variant: _shadVariant,
      size: _shadSize,
      onPressed: onPressed,
      leading: leading,
      trailing: trailing,
      expands: expands,
      enabled: isEnabled,
      child: child,
    );
    if (semanticLabel == null) {
      return button;
    }
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      container: true,
      excludeSemantics: true,
      child: button,
    );
  }
}
