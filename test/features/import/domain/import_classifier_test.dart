import 'dart:io';

import 'package:ai_workbench/features/import/domain/import_classifier.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/import_source_fixture.dart';

void main() {
  late ImportSourceFixture fixture;
  late ImportClassifier classifier;

  setUp(() async {
    fixture = await ImportSourceFixture.create();
    classifier = const ImportClassifier();
  });

  tearDown(() => fixture.dispose());

  test('classifies a folder with root SKILL.md as a skill', () async {
    final source = await fixture.skillDirectory('apple-design');
    final candidate = await classifier.classify(source);
    expect(candidate.suggestedType, ResourceType.skill);
    expect(candidate.reason, '检测到 SKILL.md');
    expect(candidate.isDirectory, isTrue);
  });

  test('classifies a dropped SKILL.md file as its parent folder', () async {
    final source = await fixture.skillDirectory('apple-design');
    final entry = File('${source.path}/SKILL.md');
    final candidate = await classifier.classify(entry);
    expect(candidate.suggestedType, ResourceType.skill);
    expect(candidate.isDirectory, isTrue);
    expect(candidate.sourcePath, source.path);
    expect(candidate.reason, '检测到 SKILL.md，将导入所在文件夹');
  });

  test(
    'classifies a parent folder of skill packages as a skill bundle',
    () async {
      final first = await fixture.skillDirectory('alpha');
      final second = await fixture.skillDirectory('beta');
      expect(first.parent.path, second.parent.path);
      final candidate = await classifier.classify(first.parent);
      expect(candidate.suggestedType, ResourceType.skill);
      expect(candidate.reason, contains('2 个 SKILL 子包'));
    },
  );

  test('classifies known file extensions', () async {
    expect(
      (await classifier.classify(await fixture.file('a.md'))).suggestedType,
      ResourceType.prompt,
    );
    expect(
      (await classifier.classify(await fixture.file('b.txt'))).suggestedType,
      ResourceType.prompt,
    );
    expect(
      (await classifier.classify(await fixture.file('c.json'))).suggestedType,
      ResourceType.mcp,
    );
    expect(
      (await classifier.classify(await fixture.file('d.mmd'))).suggestedType,
      ResourceType.workflow,
    );
    expect(
      (await classifier.classify(await fixture.file('e.url'))).suggestedType,
      ResourceType.link,
    );
  });

  test('leaves an unknown extension unclassified', () async {
    final source = await fixture.file('diagram.bin');
    expect((await classifier.classify(source)).suggestedType, isNull);
    expect((await classifier.classify(source)).reason, '无法自动识别类型');
  });

  test('rejects file and directory symlinks', () async {
    final targetFile = await fixture.file('real.md', 'x');
    final targetDir = await fixture.skillDirectory('real-skill');
    final fileLink = await fixture.fileSymlink('link.md', targetFile);
    final dirLink = await fixture.directorySymlink('link-skill', targetDir);

    final fileCandidate = await classifier.classify(fileLink);
    final dirCandidate = await classifier.classify(dirLink);

    expect(fileCandidate.suggestedType, isNull);
    expect(fileCandidate.reason, '不支持导入符号链接');
    expect(dirCandidate.suggestedType, isNull);
    expect(dirCandidate.reason, '不支持导入符号链接');
  });
}
