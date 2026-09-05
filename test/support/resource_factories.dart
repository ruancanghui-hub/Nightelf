import 'package:ai_workbench/features/vault/domain/resource_record.dart';
import 'package:ai_workbench/shared/domain/resource_type.dart';

ResourceRecord promptRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'prompt-1',
  type: type ?? ResourceType.prompt,
  relativePath: relativePath ?? 'prompts/prompt-1.md',
  title: title ?? 'Prompt 1',
  description: description ?? 'Prompt resource',
  tags: tags ?? const ['prompt'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'Prompt 1 Prompt resource prompt',
);

ResourceRecord skillRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'skill-1',
  type: type ?? ResourceType.skill,
  relativePath: relativePath ?? 'skills/skill-1',
  title: title ?? 'Skill 1',
  description: description ?? 'Skill resource',
  tags: tags ?? const ['skill'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'Skill 1 Skill resource skill',
);

ResourceRecord mcpRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'mcp-1',
  type: type ?? ResourceType.mcp,
  relativePath: relativePath ?? 'mcp/mcp-1.json',
  title: title ?? 'MCP 1',
  description: description ?? 'MCP resource',
  tags: tags ?? const ['mcp'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'MCP 1 MCP resource mcp',
);

ResourceRecord linkRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'link-1',
  type: type ?? ResourceType.link,
  relativePath: relativePath ?? 'links/link-1.url',
  title: title ?? 'Link 1',
  description: description ?? 'Link resource',
  tags: tags ?? const ['link'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'Link 1 Link resource link',
);

ResourceRecord workflowRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'workflow-1',
  type: type ?? ResourceType.workflow,
  relativePath: relativePath ?? 'workflows/workflow-1.json',
  title: title ?? 'Workflow 1',
  description: description ?? 'Workflow resource',
  tags: tags ?? const ['workflow'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'Workflow 1 Workflow resource workflow',
);

ResourceRecord launcherRecord({
  String? id,
  ResourceType? type,
  String? relativePath,
  String? title,
  String? description,
  List<String>? tags,
  DateTime? modifiedAt,
  String? searchableText,
}) => _record(
  id: id ?? 'launcher-1',
  type: type ?? ResourceType.launcher,
  relativePath: relativePath ?? 'launchers/launcher-1.md',
  title: title ?? 'Launcher 1',
  description: description ?? '/tmp/launch.sh',
  tags: tags ?? const ['launcher'],
  modifiedAt: modifiedAt ?? _defaultModifiedAt,
  searchableText: searchableText ?? 'Launcher 1 /tmp/launch.sh launcher',
);

final _defaultModifiedAt = DateTime.utc(2026, 8, 8);

ResourceRecord _record({
  required String id,
  required ResourceType type,
  required String relativePath,
  required String title,
  required String description,
  required List<String> tags,
  required DateTime modifiedAt,
  required String searchableText,
}) => ResourceRecord(
  id: id,
  type: type,
  relativePath: relativePath,
  title: title,
  description: description,
  tags: tags,
  modifiedAt: modifiedAt,
  searchableText: searchableText,
);
