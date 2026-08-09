import 'dart:io';

import 'package:ai_workbench/features/skills/domain/import_progress.dart';
import 'package:ai_workbench/features/skills/domain/skill_resource.dart';
import 'package:ai_workbench/features/skills/domain/skill_tree_node.dart';

typedef ConfirmLargeFile =
    Future<bool> Function(String absolutePath, int byteLength);

abstract interface class SkillRepository {
  Stream<ImportProgress> importDirectory(
    Directory source, {
    ConfirmLargeFile? confirmLargeFile,
  });

  Future<SkillResource> read(String relativeDirectory);

  Future<List<SkillTreeNode>> listChildren(String relativeDirectory);

  Future<String> readTextFile(String relativePath);

  Future<void> writeTextFile(String relativePath, String contents);

  Future<SkillResource> duplicate(String relativeDirectory);

  Future<String> moveToTrash(String relativeDirectory);
}
