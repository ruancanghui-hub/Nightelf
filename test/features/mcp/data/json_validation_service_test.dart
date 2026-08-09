import 'package:ai_workbench/features/mcp/data/json_validation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = JsonValidationService();

  test('reports one-based line and column for malformed JSON', () {
    const source = '{\n  "mcpServers": {\n  }\n';
    final result = service.validate(source);
    expect(result.isValid, isFalse);
    expect(result.diagnostic!.line, 4);
    expect(result.diagnostic!.column, greaterThanOrEqualTo(1));
  });

  test('formats valid JSON with two-space indentation and final newline', () {
    expect(service.format('{"a":1}'), '{\n  "a": 1\n}\n');
  });

  test('accepts valid nested mcpServers', () {
    const source = '{\n  "mcpServers": {}\n}\n';
    final result = service.validate(source);
    expect(result.isValid, isTrue);
    expect(result.value, isA<Map>());
  });
}
