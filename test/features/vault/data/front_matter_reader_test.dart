import 'package:ai_workbench/features/vault/data/front_matter_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reads YAML front matter without removing body whitespace', () {
    const source = '---\nid: prompt-1\ntitle: 审查助手\ntags: [代码, 审查]\n---\n正文\n';

    final document = const FrontMatterReader().read(source);

    expect(document.metadata['id'], 'prompt-1');
    expect(document.metadata['tags'], ['代码', '审查']);
    expect(document.body, '正文\n');
  });

  test(
    'returns an ordinary document unchanged when front matter is absent',
    () {
      const source = '# Heading\n\nBody\n';

      final document = const FrontMatterReader().read(source);

      expect(document.metadata, isEmpty);
      expect(document.body, source);
    },
  );
}
