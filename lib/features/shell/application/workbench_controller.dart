import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/foundation.dart';

/// Keeps the shell navigation deterministic until it is backed by a Vault.
class WorkbenchController extends ChangeNotifier {
  WorkbenchController();

  static const Map<ResourceType, String> _destinationLabels = {
    ResourceType.aiPrompt: 'AI 提示词',
    ResourceType.skillFolder: 'SKILL 文件夹',
    ResourceType.mcpConfiguration: 'MCP 配置',
    ResourceType.websiteLink: '网站链接',
    ResourceType.workflowFile: 'Workflow 文件',
  };

  static const List<WorkbenchResource> _resources = [
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
  ];

  ResourceType _selectedDestination = ResourceType.aiPrompt;
  late WorkbenchResource _selectedResource = _resources.first;

  List<String> get destinationLabels =>
      ResourceType.values.map((type) => _destinationLabels[type]!).toList();

  ResourceType get selectedDestination => _selectedDestination;

  WorkbenchResource get selectedResource => _selectedResource;

  List<WorkbenchResource> get selectedResources => _resources
      .where((resource) => resource.type == _selectedDestination)
      .toList();

  List<WorkbenchResource> get favoriteResources =>
      _resources.where((resource) => resource.isFavorite).toList();

  List<WorkbenchResource> get recentResources => _resources.take(3).toList();

  String labelFor(ResourceType type) => _destinationLabels[type]!;

  void selectDestination(ResourceType type) {
    _selectedDestination = type;
    _selectedResource = selectedResources.first;
    notifyListeners();
  }

  void selectResource(WorkbenchResource resource) {
    _selectedDestination = resource.type;
    _selectedResource = resource;
    notifyListeners();
  }
}
