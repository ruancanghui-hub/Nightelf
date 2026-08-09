import 'dart:io';

import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:path/path.dart' as p;

class ImportClassifier {
  const ImportClassifier();

  Future<ImportCandidate> classify(FileSystemEntity source) async {
    final path = source.path;
    if (await _isSymlink(source)) {
      return ImportCandidate(
        sourcePath: path,
        isDirectory:
            source is Directory || await FileSystemEntity.isDirectory(path),
        suggestedType: null,
        reason: '不支持导入符号链接',
      );
    }

    if (source is Directory || await FileSystemEntity.isDirectory(path)) {
      final skill = File(p.join(path, 'SKILL.md'));
      if (await skill.exists()) {
        return ImportCandidate(
          sourcePath: path,
          isDirectory: true,
          suggestedType: ResourceType.skill,
          reason: '检测到 SKILL.md',
        );
      }
      return ImportCandidate(
        sourcePath: path,
        isDirectory: true,
        suggestedType: null,
        reason: '无法自动识别类型',
      );
    }

    final extension = p.extension(path).toLowerCase();
    return switch (extension) {
      '.md' || '.txt' => ImportCandidate(
        sourcePath: path,
        isDirectory: false,
        suggestedType: ResourceType.prompt,
        reason: '按扩展名识别为提示词',
      ),
      '.json' => ImportCandidate(
        sourcePath: path,
        isDirectory: false,
        suggestedType: ResourceType.mcp,
        reason: '按扩展名识别为 MCP 配置',
      ),
      '.mmd' || '.yml' || '.yaml' => ImportCandidate(
        sourcePath: path,
        isDirectory: false,
        suggestedType: ResourceType.workflow,
        reason: '按扩展名识别为 Workflow',
      ),
      '.url' => ImportCandidate(
        sourcePath: path,
        isDirectory: false,
        suggestedType: ResourceType.link,
        reason: '按扩展名识别为网站链接',
      ),
      _ => ImportCandidate(
        sourcePath: path,
        isDirectory: false,
        suggestedType: null,
        reason: '无法自动识别类型',
      ),
    };
  }

  Future<bool> _isSymlink(FileSystemEntity source) async {
    if (source is Link) {
      return true;
    }
    final type = await FileSystemEntity.type(source.path, followLinks: false);
    return type == FileSystemEntityType.link;
  }
}
