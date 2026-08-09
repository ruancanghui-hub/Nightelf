import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';

class ImportPlanItem {
  const ImportPlanItem({
    required this.candidate,
    required this.selectedType,
    required this.title,
    required this.targetBasename,
    required this.isSelected,
  });

  final ImportCandidate candidate;
  final ResourceType? selectedType;
  final String title;
  final String targetBasename;
  final bool isSelected;

  bool get canConfirm => isSelected && selectedType != null;

  ImportPlanItem copyWith({
    ResourceType? selectedType,
    bool clearSelectedType = false,
    String? title,
    String? targetBasename,
    bool? isSelected,
  }) {
    return ImportPlanItem(
      candidate: candidate,
      selectedType: clearSelectedType
          ? null
          : (selectedType ?? this.selectedType),
      title: title ?? this.title,
      targetBasename: targetBasename ?? this.targetBasename,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

class ImportPlan {
  const ImportPlan(this.items);

  final List<ImportPlanItem> items;

  bool get canConfirmAllSelected =>
      items.where((item) => item.isSelected).every((item) => item.canConfirm);
}
