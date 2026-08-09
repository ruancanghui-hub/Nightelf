import 'package:ai_workbench/features/links/data/link_markdown_codec.dart';
import 'package:ai_workbench/features/links/domain/link_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('link Markdown round-trips URL and notes', () {
    final document = LinkDocument(
      id: 'l1',
      title: 'MDN 文档',
      uri: Uri.parse('https://developer.mozilla.org/'),
      description: 'Web 参考',
      tags: const ['文档'],
      notes: '常用查询入口',
      relativePath: 'links/mdn.md',
    );
    expect(
      const LinkMarkdownCodec().decode(
        const LinkMarkdownCodec().encode(document),
        document.relativePath,
      ),
      document,
    );
  });
}
