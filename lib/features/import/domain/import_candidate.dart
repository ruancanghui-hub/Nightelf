import 'package:ai_workbench/shared/domain/resource_type.dart';

class ImportCandidate {
  const ImportCandidate({
    required this.sourcePath,
    required this.isDirectory,
    required this.suggestedType,
    required this.reason,
  });

  final String sourcePath;
  final bool isDirectory;
  final ResourceType? suggestedType;
  final String reason;
}
