import 'package:ai_workbench/features/mcp/domain/mcp_document.dart';

abstract interface class McpRepository {
  Future<McpDocument> create({
    required String title,
    String description = '',
    List<String> tags = const [],
    String jsonText = '{\n  "mcpServers": {}\n}\n',
  });

  Future<McpDocument> read(String relativePath);

  Future<McpDocument> save(McpDocument document);

  Future<McpDocument> duplicate(String relativePath);

  Future<McpDocument> rename(
    String relativePath, {
    required String title,
    String? jsonText,
  });

  Future<String> moveToTrash(String relativePath);
}
