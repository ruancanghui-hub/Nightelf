import 'package:flutter_test/flutter_test.dart';

import 'recording_platform_adapters.dart';

void main() {
  test('recording clipboard stores exact text', () async {
    final clipboard = RecordingClipboardService();
    await clipboard.writeText('hello\nworld');
    expect(clipboard.texts, ['hello\nworld']);
  });
}
