import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'package:ai_workbench/shared/ui/workbench_button.dart';

/// Icon-only button wrapper over [ShadIconButton].
class WorkbenchIconButton extends StatelessWidget {
  const WorkbenchIconButton({
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.variant = WorkbenchButtonVariant.ghost,
    this.iconSize,
    this.width,
    this.height,
    super.key,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final WorkbenchButtonVariant variant;
  final double? iconSize;
  final double? width;
  final double? height;

  ShadButtonVariant get _shadVariant => switch (variant) {
    WorkbenchButtonVariant.primary => ShadButtonVariant.primary,
    WorkbenchButtonVariant.secondary => ShadButtonVariant.secondary,
    WorkbenchButtonVariant.outline => ShadButtonVariant.outline,
    WorkbenchButtonVariant.ghost => ShadButtonVariant.ghost,
    WorkbenchButtonVariant.destructive => ShadButtonVariant.destructive,
  };

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null;
    final label = semanticLabel ?? tooltip;
    Widget button = ShadIconButton.raw(
      variant: _shadVariant,
      icon: icon,
      iconSize: iconSize,
      width: width,
      height: height,
      onPressed: onPressed,
      enabled: isEnabled,
    );
    if (tooltip != null && tooltip!.isNotEmpty) {
      button = MacosTooltip(message: tooltip!, child: button);
    }
    if (label == null) {
      return button;
    }
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: label,
      container: true,
      excludeSemantics: true,
      child: button,
    );
  }
}
