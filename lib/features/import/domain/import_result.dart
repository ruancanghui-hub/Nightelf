import 'package:ai_workbench/features/import/domain/import_plan.dart';

class ImportResult {
  const ImportResult({
    required this.item,
    required this.succeeded,
    this.resourcePath,
    this.failureReason,
  });

  final ImportPlanItem item;
  final String? resourcePath;
  final bool succeeded;
  final String? failureReason;
}
