import 'package:ai_workbench/features/launchers/data/launcher_markdown_codec.dart';
import 'package:ai_workbench/features/launchers/domain/launcher_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('launcher Markdown round-trips title and script path', () {
    const document = LauncherDocument(
      id: 'l1',
      title: 'Nightelf',
      scriptPath: '/Users/me/work/21_暗夜精灵/script/launch_macos.sh',
      relativePath: 'launchers/nightelf.md',
    );
    expect(
      const LauncherMarkdownCodec().decode(
        const LauncherMarkdownCodec().encode(document),
        document.relativePath,
      ),
      document,
    );
  });
}
