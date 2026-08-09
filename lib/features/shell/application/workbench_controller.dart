import 'package:ai_workbench/features/metadata/domain/resource_metadata.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/foundation.dart';

/// Keeps the shell navigation deterministic for mock or Vault-backed records.
class WorkbenchController extends ChangeNotifier {
  WorkbenchController({List<WorkbenchResource>? resources})
    : _resources = List<WorkbenchResource>.from(resources ?? _mockResources) {
    _selectedDestination = _resources.isEmpty
        ? ResourceType.aiPrompt
        : _resources.first.type;
    _selectedResource = _resources.isEmpty ? null : _resources.first;
  }

  static const Map<ResourceType, String> _destinationLabels = {
    ResourceType.aiPrompt: 'AI 提示词',
    ResourceType.skillFolder: 'SKILL 文件夹',
    ResourceType.mcpConfiguration: 'MCP 配置',
    ResourceType.websiteLink: '网站链接',
    ResourceType.workflowFile: 'Workflow 文件',
  };

  static const List<WorkbenchResource> _mockResources = [
    WorkbenchResource(
      id: 'prompt-release-notes',
      type: ResourceType.aiPrompt,
      title: '发布说明助手',
      subtitle: '将变更整理为清晰的发布说明',
      isFavorite: true,
    ),
    WorkbenchResource(
      id: 'prompt-ux-review',
      type: ResourceType.aiPrompt,
      title: 'UX 评审',
      subtitle: '检查产品体验与可访问性',
      isFavorite: false,
    ),
    WorkbenchResource(
      id: 'skill-product-copy',
      type: ResourceType.skillFolder,
      title: '产品文案',
      subtitle: '适用于产品界面的写作技能',
      isFavorite: true,
    ),
    WorkbenchResource(
      id: 'mcp-local-docs',
      type: ResourceType.mcpConfiguration,
      title: '本地文档 MCP',
      subtitle: '为文档检索预留的配置',
      isFavorite: false,
    ),
    WorkbenchResource(
      id: 'link-apple-hig',
      type: ResourceType.websiteLink,
      title: 'Apple 人机界面指南',
      subtitle: '设计系统参考链接',
      isFavorite: true,
    ),
    WorkbenchResource(
      id: 'workflow-release',
      type: ResourceType.workflowFile,
      title: '发布前检查',
      subtitle: '发布流程的视觉占位项',
      isFavorite: false,
    ),
    WorkbenchResource(
      id: 'prompt-social-copy',
      type: ResourceType.aiPrompt,
      title: '小红书爆款写作合集',
      subtitle: '社交内容的标题与正文灵感',
      isFavorite: false,
    ),
    WorkbenchResource(
      id: 'skill-productivity',
      type: ResourceType.skillFolder,
      title: '研发提效工具包',
      subtitle: '常用研发任务的工作技能集合',
      isFavorite: false,
    ),
  ];

  final List<WorkbenchResource> _resources;
  late ResourceType _selectedDestination;
  WorkbenchResource? _selectedResource;
  String? _selectedCollectionId;
  List<RecentResourceEntry> _recentEntries = const [];
  Set<String>? _collectionMemberIds;

  List<String> get destinationLabels =>
      ResourceType.values.map((type) => _destinationLabels[type]!).toList();

  ResourceType get selectedDestination => _selectedDestination;

  String? get selectedCollectionId => _selectedCollectionId;

  WorkbenchResource get selectedResource =>
      _selectedResource ??
      WorkbenchResource(
        id: 'empty',
        type: _selectedDestination,
        title: '暂无资源',
        subtitle: '拖入文件或新建资源后会出现在这里',
        isFavorite: false,
      );

  List<WorkbenchResource> get allResources => List.unmodifiable(_resources);

  List<WorkbenchResource> get selectedResources {
    final byType = _resources.where(
      (resource) => resource.type == _selectedDestination,
    );
    final members = _collectionMemberIds;
    if (_selectedCollectionId == null || members == null) {
      return byType.toList();
    }
    return byType.where((resource) => members.contains(resource.id)).toList();
  }

  List<WorkbenchResource> get favoriteResources =>
      _resources.where((resource) => resource.isFavorite).toList();

  List<WorkbenchResource> get recentResources {
    if (_recentEntries.isEmpty) {
      return const [];
    }
    final resolved = <WorkbenchResource>[];
    for (final entry in _recentEntries) {
      final resource = resourceById(entry.resourceId);
      if (resource != null) {
        resolved.add(resource);
      }
    }
    return resolved;
  }

  DateTime? recentOpenedAt(String resourceId) {
    for (final entry in _recentEntries) {
      if (entry.resourceId == resourceId) {
        return entry.openedAt;
      }
    }
    return null;
  }

  String labelFor(ResourceType type) => _destinationLabels[type]!;

  WorkbenchResource? resourceById(String id) {
    for (final resource in _resources) {
      if (resource.id == id) {
        return resource;
      }
    }
    return null;
  }

  void selectDestination(ResourceType type) {
    _selectedDestination = type;
    _selectedCollectionId = null;
    _collectionMemberIds = null;
    final matching = selectedResources;
    _selectedResource = matching.isEmpty ? null : matching.first;
    notifyListeners();
  }

  void selectCollection({
    required String? collectionId,
    required Set<String>? memberIds,
  }) {
    _selectedCollectionId = collectionId;
    _collectionMemberIds = memberIds == null
        ? null
        : Set<String>.from(memberIds);
    final matching = selectedResources;
    if (_selectedResource == null ||
        matching.every((resource) => resource.id != _selectedResource!.id)) {
      _selectedResource = matching.isEmpty ? null : matching.first;
    }
    notifyListeners();
  }

  void applyRecentResourceIds(List<String> recentResourceIds) {
    applyRecentEntries([
      for (final id in recentResourceIds) RecentResourceEntry(resourceId: id),
    ]);
  }

  void applyRecentEntries(List<RecentResourceEntry> recentEntries) {
    _recentEntries = List<RecentResourceEntry>.from(recentEntries);
    notifyListeners();
  }

  void selectResource(WorkbenchResource resource) {
    _selectedDestination = resource.type;
    _selectedResource = resource;
    notifyListeners();
  }

  void replaceResources(List<WorkbenchResource> resources) {
    final previousDestination = _selectedDestination;
    final previousSelectedId = _selectedResource?.id;
    _resources
      ..clear()
      ..addAll(resources);
    _selectedDestination = previousDestination;
    _selectedResource = previousSelectedId == null
        ? null
        : resourceById(previousSelectedId);
    if (_selectedResource == null) {
      final matching = selectedResources;
      _selectedResource = matching.isEmpty ? null : matching.first;
    }
    notifyListeners();
  }

  void applyFavoriteIds(Set<String> favoriteIds) {
    for (var index = 0; index < _resources.length; index += 1) {
      final resource = _resources[index];
      final nextFavorite = favoriteIds.contains(resource.id);
      if (resource.isFavorite != nextFavorite) {
        _resources[index] = resource.copyWith(isFavorite: nextFavorite);
      }
    }
    if (_selectedResource != null) {
      _selectedResource = resourceById(_selectedResource!.id);
    }
    notifyListeners();
  }

  /// Toggles favorite for [id] and returns the updated favorite ID set.
  Set<String> toggleFavorite(String id) {
    final index = _resources.indexWhere((resource) => resource.id == id);
    if (index < 0) {
      return favoriteResources.map((resource) => resource.id).toSet();
    }
    final current = _resources[index];
    _resources[index] = current.copyWith(isFavorite: !current.isFavorite);
    if (_selectedResource?.id == id) {
      _selectedResource = _resources[index];
    }
    notifyListeners();
    return favoriteResources.map((resource) => resource.id).toSet();
  }
}
