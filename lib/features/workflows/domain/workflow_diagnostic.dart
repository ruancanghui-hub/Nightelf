class WorkflowDiagnostic {
  const WorkflowDiagnostic({
    required this.line,
    required this.column,
    required this.message,
  });

  final int line;
  final int column;
  final String message;

  @override
  bool operator ==(Object other) {
    return other is WorkflowDiagnostic &&
        other.line == line &&
        other.column == column &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(line, column, message);

  @override
  String toString() => 'L$line:C$column $message';
}
