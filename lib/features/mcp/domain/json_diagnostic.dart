class JsonDiagnostic {
  const JsonDiagnostic({
    required this.line,
    required this.column,
    required this.message,
  });

  final int line;
  final int column;
  final String message;
}

class JsonValidationResult {
  const JsonValidationResult.valid(this.value)
    : isValid = true,
      diagnostic = null;

  const JsonValidationResult.invalid(this.diagnostic)
    : isValid = false,
      value = null;

  final bool isValid;
  final Object? value;
  final JsonDiagnostic? diagnostic;
}

class FullCopyUnavailable implements Exception {
  const FullCopyUnavailable([
    this.message = '完整配置复制需 Phase 5 SecretStore，当前不可用',
  ]);

  final String message;

  @override
  String toString() => 'FullCopyUnavailable: $message';
}
