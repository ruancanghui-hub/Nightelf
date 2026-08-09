class WorkbenchCommand {
  const WorkbenchCommand({
    required this.id,
    required this.label,
    this.shortcutLabel,
    this.execute,
  });

  final String id;
  final String label;
  final String? shortcutLabel;
  final Future<void> Function()? execute;

  bool get isEnabled => execute != null;
}
