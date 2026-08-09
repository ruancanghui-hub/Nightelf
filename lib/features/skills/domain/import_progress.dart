import 'package:ai_workbench/features/skills/domain/skill_resource.dart';

class ImportProgress {
  const ImportProgress({
    required this.copiedFiles,
    required this.copiedBytes,
    required this.currentRelativePath,
    this.skill,
  });

  final int copiedFiles;
  final int copiedBytes;
  final String currentRelativePath;
  final SkillResource? skill;
}
