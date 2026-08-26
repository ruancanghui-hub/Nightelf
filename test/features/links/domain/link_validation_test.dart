import 'package:ai_workbench/features/links/domain/link_validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const validation = LinkValidation();

  test('normalizes a bare https host path and rejects unsafe schemes', () {
    expect(
      validation.validate('https://example.com/docs').uri,
      Uri.parse('https://example.com/docs'),
    );
    expect(
      validation.validate('javascript:alert(1)').error,
      '仅支持 http 或 https 链接',
    );
    expect(validation.validate('file:///tmp/secret').isValid, isFalse);
  });

  test('accepts bare hosts by adding https', () {
    final result = validation.validate('Example.COM/path');
    expect(result.isValid, isTrue);
    expect(result.uri.toString(), 'https://example.com/path');
  });

  test('classifies in-app and ignored WebView schemes', () {
    expect(
      validation.isInAppWebScheme(Uri.parse('https://example.com')),
      isTrue,
    );
    expect(
      validation.shouldIgnoreExternalOpen(Uri.parse('about:blank')),
      isTrue,
    );
    expect(validation.shouldIgnoreExternalOpen(Uri.parse('about:srcdoc')), isTrue);
    expect(
      validation.shouldIgnoreExternalOpen(Uri.parse('data:text/html,hi')),
      isTrue,
    );
    expect(
      validation.shouldIgnoreExternalOpen(Uri.parse('mailto:a@b.com')),
      isFalse,
    );
  });
}
