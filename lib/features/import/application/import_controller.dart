import 'dart:io';

import 'package:ai_workbench/features/import/data/vault_import_repository.dart';
import 'package:ai_workbench/features/import/domain/import_candidate.dart';
import 'package:ai_workbench/features/import/domain/import_classifier.dart';
import 'package:ai_workbench/features/import/domain/import_plan.dart';
import 'package:ai_workbench/features/import/domain/import_result.dart';
import 'package:ai_workbench/features/vault/domain/vault_handle.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef ImportRefresh = Future<void> Function(Set<String> relativePaths);

class ImportController extends ChangeNotifier {
  ImportController({
    required VaultImportRepository repository,
    ImportClassifier? classifier,
    this.onImported,
  }) : _repository = repository,
       _classifier = classifier ?? const ImportClassifier();

  final VaultImportRepository _repository;
  final ImportClassifier _classifier;
  final ImportRefresh? onImported;

  ImportPlan _plan = const ImportPlan([]);
  bool _isImporting = false;
  List<ImportResult> _results = const [];
  String? _statusMessage;

  ImportPlan get plan => _plan;
  bool get isImporting => _isImporting;
  List<ImportResult> get results => List.unmodifiable(_results);
  String? get statusMessage => _statusMessage;
  bool get canConfirm =>
      !_isImporting &&
      _plan.items.any((item) => item.isSelected) &&
      _plan.canConfirmAllSelected;

  @visibleForTesting
  void debugReplacePlan(ImportPlan plan) {
    _plan = plan;
    _results = const [];
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> prepare(
    List<String> sourcePaths, {
    ResourceType? preferredType,
  }) async {
    final items = <ImportPlanItem>[];
    for (final path in sourcePaths) {
      final entity = await _entityFor(path);
      final candidate = await _classifier.classify(entity);
      final selectedType = candidate.suggestedType ?? preferredType;

      if (candidate.isDirectory &&
          selectedType == ResourceType.skill &&
          !await File(p.join(candidate.sourcePath, 'SKILL.md')).exists()) {
        final packages = await findImmediateSkillPackages(
          Directory(candidate.sourcePath),
        );
        if (packages.isNotEmpty) {
          for (final package in packages) {
            final name = p.basename(package.path);
            items.add(
              ImportPlanItem(
                candidate: ImportCandidate(
                  sourcePath: package.path,
                  isDirectory: true,
                  suggestedType: ResourceType.skill,
                  reason: '来自 SKILL 集合：${p.basename(candidate.sourcePath)}',
                ),
                selectedType: ResourceType.skill,
                title: name,
                targetBasename: name,
                isSelected: true,
              ),
            );
          }
          continue;
        }
      }

      final title = p.basenameWithoutExtension(
        candidate.isDirectory ? candidate.sourcePath : path,
      );
      final basename = selectedType == null
          ? p.basename(candidate.sourcePath)
          : defaultBasenameFor(
              ImportPlanItem(
                candidate: candidate,
                selectedType: selectedType,
                title: title,
                targetBasename: p.basename(candidate.sourcePath),
                isSelected: true,
              ),
              selectedType,
            );
      items.add(
        ImportPlanItem(
          candidate: candidate,
          selectedType: selectedType,
          title: title.isEmpty ? p.basename(candidate.sourcePath) : title,
          targetBasename: basename,
          isSelected: true,
        ),
      );
    }
    _plan = ImportPlan(items);
    _results = const [];
    _statusMessage = null;
    notifyListeners();
  }

  Future<void> setType(int index, ResourceType type) async {
    if (index < 0 || index >= _plan.items.length) {
      return;
    }
    final item = _plan.items[index];
    if (type == ResourceType.skill && item.candidate.isDirectory) {
      final hasRootSkill = await File(
        p.join(item.candidate.sourcePath, 'SKILL.md'),
      ).exists();
      if (!hasRootSkill) {
        final packages = await findImmediateSkillPackages(
          Directory(item.candidate.sourcePath),
        );
        if (packages.isNotEmpty) {
          final items = [..._plan.items]..removeAt(index);
          final expanded = [
            for (final package in packages)
              ImportPlanItem(
                candidate: ImportCandidate(
                  sourcePath: package.path,
                  isDirectory: true,
                  suggestedType: ResourceType.skill,
                  reason:
                      '来自 SKILL 集合：${p.basename(item.candidate.sourcePath)}',
                ),
                selectedType: ResourceType.skill,
                title: p.basename(package.path),
                targetBasename: p.basename(package.path),
                isSelected: true,
              ),
          ];
          items.insertAll(index, expanded);
          _plan = ImportPlan(items);
          notifyListeners();
          return;
        }
      }
    }
    _updateItem(index, (current) {
      final next = current.copyWith(selectedType: type);
      return next.copyWith(targetBasename: defaultBasenameFor(next, type));
    });
  }

  void rename(int index, {String? title, String? targetBasename}) {
    _updateItem(
      index,
      (item) => item.copyWith(title: title, targetBasename: targetBasename),
    );
  }

  void remove(int index) {
    if (index < 0 || index >= _plan.items.length) {
      return;
    }
    final items = [..._plan.items]..removeAt(index);
    _plan = ImportPlan(items);
    notifyListeners();
  }

  void cancel() {
    _plan = const ImportPlan([]);
    _results = const [];
    _statusMessage = '已取消导入';
    _isImporting = false;
    notifyListeners();
  }

  Future<List<ImportResult>> confirm(VaultHandle vault) async {
    if (!canConfirm) {
      _statusMessage = '请为所有选中项选择资源类型后再导入';
      notifyListeners();
      return const [];
    }

    _isImporting = true;
    _statusMessage = '正在复制到 Vault…';
    notifyListeners();

    final results = <ImportResult>[];
    final importedPaths = <String>{};
    for (final item in _plan.items.where((item) => item.isSelected)) {
      final result = await _repository.importItem(vault, item);
      results.add(result);
      if (result.succeeded && result.resourcePath != null) {
        importedPaths.add(
          p.relative(result.resourcePath!, from: vault.root.path),
        );
      }
    }

    _results = results;
    _isImporting = false;
    final successCount = results.where((result) => result.succeeded).length;
    final failureCount = results.length - successCount;
    _statusMessage = '导入完成：成功 $successCount 项，失败 $failureCount 项';

    if (importedPaths.isNotEmpty) {
      await onImported?.call(importedPaths);
    }

    if (failureCount == 0) {
      _plan = const ImportPlan([]);
    }
    notifyListeners();
    return results;
  }

  Future<ImportResult> retry(VaultHandle vault, int resultIndex) async {
    if (resultIndex < 0 || resultIndex >= _results.length) {
      throw RangeError.index(resultIndex, _results);
    }
    final previous = _results[resultIndex];
    final result = await _repository.importItem(vault, previous.item);
    final next = [..._results];
    next[resultIndex] = result;
    _results = next;
    if (result.succeeded && result.resourcePath != null) {
      await onImported?.call({
        p.relative(result.resourcePath!, from: vault.root.path),
      });
    }
    notifyListeners();
    return result;
  }

  void _updateItem(
    int index,
    ImportPlanItem Function(ImportPlanItem item) transform,
  ) {
    if (index < 0 || index >= _plan.items.length) {
      return;
    }
    final items = [..._plan.items];
    items[index] = transform(items[index]);
    _plan = ImportPlan(items);
    notifyListeners();
  }

  Future<FileSystemEntity> _entityFor(String path) async {
    final type = await FileSystemEntity.type(path, followLinks: false);
    return switch (type) {
      FileSystemEntityType.directory => Directory(path),
      FileSystemEntityType.link => Link(path),
      _ => File(path),
    };
  }
}
