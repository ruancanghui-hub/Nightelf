import 'dart:convert';

import 'package:ai_workbench/features/mcp/domain/json_diagnostic.dart';

class JsonValidationService {
  const JsonValidationService();

  JsonValidationResult validate(String source) {
    try {
      final value = jsonDecode(source);
      return JsonValidationResult.valid(value);
    } on FormatException catch (error) {
      final offset = error.offset ?? source.length;
      final position = _lineColumn(source, offset);
      return JsonValidationResult.invalid(
        JsonDiagnostic(
          line: position.line,
          column: position.column,
          message: error.message,
        ),
      );
    }
  }

  String format(String source) {
    final result = validate(source);
    if (!result.isValid) {
      throw FormatException(result.diagnostic?.message ?? '无法格式化无效 JSON');
    }
    const encoder = JsonEncoder.withIndent('  ');
    final encoded = encoder.convert(result.value);
    return encoded.endsWith('\n') ? encoded : '$encoded\n';
  }

  ({int line, int column}) _lineColumn(String source, int offset) {
    var line = 1;
    var column = 1;
    final end = offset.clamp(0, source.length);
    for (var i = 0; i < end; i++) {
      if (source.codeUnitAt(i) == 0x0A) {
        line += 1;
        column = 1;
      } else {
        column += 1;
      }
    }
    return (line: line, column: column);
  }
}
