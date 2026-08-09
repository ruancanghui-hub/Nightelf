import 'package:flutter/widgets.dart';

class WorkbenchCommand {
  const WorkbenchCommand({
    required this.id,
    required this.label,
    this.shortcutLabel,
    this.subtitle,
    this.icon,
    this.execute,
  });

  final String id;
  final String label;
  final String? shortcutLabel;
  final String? subtitle;
  final IconData? icon;
  final Future<void> Function()? execute;

  bool get isEnabled => execute != null;
}
