import 'package:ai_workbench/features/prompts/data/prompt_markdown_codec.dart';
import 'package:ai_workbench/features/prompts/domain/prompt_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prompt codec emits deterministic front matter', () {
    const document = PromptDocument(
      id: 'p1',
      title: '代码审查助手',
      description: '检查安全与性能',
      tags: ['代码', '审查'],
      body: '# 角色\n你是审查员。\n',
      relativePath: 'prompts/code-review.md',
    );
    expect(const PromptMarkdownCodec().encode(document), '''---
id: "p1"
title: "代码审查助手"
description: "检查安全与性能"
tags: ["代码", "审查"]
---
# 角色
你是审查员。
''');
  });

  test('prompt codec round-trips body and metadata', () {
    const codec = PromptMarkdownCodec();
    const original = PromptDocument(
      id: 'p2',
      title: '发布说明',
      description: 'desc',
      tags: ['发布'],
      body: 'hello\n',
      relativePath: 'prompts/release.md',
    );
    final decoded = codec.decode(codec.encode(original), original.relativePath);
    expect(decoded.id, original.id);
    expect(decoded.title, original.title);
    expect(decoded.description, original.description);
    expect(decoded.tags, original.tags);
    expect(decoded.body, original.body);
  });
}
