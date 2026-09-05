import 'package:ai_workbench/features/command_palette/application/command_palette_controller.dart';
import 'package:ai_workbench/features/command_palette/domain/workbench_command.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Command palette listing workbench commands and searchable resources.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    required this.resources,
    required this.onResourceSelected,
    required this.onDismissed,
    this.commands = const [],
    this.controller,
    super.key,
  });

  final List<WorkbenchResource> resources;
  final List<WorkbenchCommand> commands;
  final ValueChanged<WorkbenchResource> onResourceSelected;
  final VoidCallback onDismissed;
  final CommandPaletteController? controller;

  static const _typeLabels = <ResourceType, String>{
    ResourceType.aiPrompt: 'AI 提示词',
    ResourceType.skillFolder: 'SKILL 文件夹',
    ResourceType.mcpConfiguration: 'MCP 配置',
    ResourceType.websiteLink: '网站链接',
    ResourceType.workflowFile: 'Workflow 文件',
    ResourceType.launcher: '启动器',
  };

  static IconData _iconForType(ResourceType type) => switch (type) {
    ResourceType.aiPrompt => LucideIcons.messageCircle,
    ResourceType.skillFolder => LucideIcons.folder,
    ResourceType.mcpConfiguration => LucideIcons.slidersHorizontal,
    ResourceType.websiteLink => LucideIcons.globe,
    ResourceType.workflowFile => LucideIcons.workflow,
    ResourceType.launcher => LucideIcons.rocket,
  };

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  late final CommandPaletteController _controller;
  var _ownsController = false;

  @override
  void initState() {
    super.initState();
    final external = widget.controller;
    if (external != null) {
      _controller = external;
    } else {
      _ownsController = true;
      _controller = CommandPaletteController(
        commands: widget.commands,
        resources: widget.resources,
      );
    }
    _controller
      ..replaceCommands(widget.commands)
      ..replaceResources(widget.resources);
  }

  @override
  void didUpdateWidget(covariant CommandPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.commands != widget.commands) {
      _controller.replaceCommands(widget.commands);
    }
    if (oldWidget.resources != widget.resources) {
      _controller.replaceResources(widget.resources);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  IconData _commandIcon(WorkbenchCommand command) {
    return command.icon ??
        switch (command.id) {
          'new-prompt' => LucideIcons.messageCircle,
          'import-skill' => LucideIcons.folder,
          'new-mcp' => LucideIcons.slidersHorizontal,
          'new-link' => LucideIcons.globe,
          'new-workflow' => LucideIcons.workflow,
          _ => LucideIcons.terminal,
        };
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: '命令面板',
        scopesRoute: true,
        explicitChildNodes: true,
        child: GestureDetector(
          onTap: widget.onDismissed,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: const Color(0x66000000),
            alignment: const Alignment(0, -0.55),
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 560,
                constraints: const BoxConstraints(maxHeight: 520),
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                decoration: BoxDecoration(
                  color: WorkbenchUiTokens.panel,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: WorkbenchUiTokens.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x55000000),
                      blurRadius: 30,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final commands = _controller.visibleCommands;
                    final results = _controller.visibleResources;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '命令面板',
                              style: TextStyle(
                                color: WorkbenchUiTokens.foreground,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            WorkbenchIconButton(
                              semanticLabel: '关闭命令面板',
                              tooltip: '关闭',
                              icon: const Icon(LucideIcons.x, size: 16),
                              onPressed: widget.onDismissed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        WorkbenchInput(
                          autofocus: true,
                          placeholder: '搜索所有资源',
                          semanticLabel: '搜索所有资源',
                          leading: const Icon(
                            LucideIcons.search,
                            size: 16,
                            color: WorkbenchUiTokens.muted,
                          ),
                          onChanged: _controller.updateQuery,
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (commands.isNotEmpty) ...[
                                  const WorkbenchCommandSectionLabel('命令'),
                                  for (final command in commands)
                                    WorkbenchCommandTile(
                                      title: command.label,
                                      subtitle: command.subtitle,
                                      leading: Icon(_commandIcon(command)),
                                      trailing: command.shortcutLabel == null
                                          ? null
                                          : Text(command.shortcutLabel!),
                                      semanticLabel:
                                          '执行命令：${command.label}',
                                      enabled: command.isEnabled,
                                      onTap: command.execute == null
                                          ? null
                                          : () async {
                                              await command.execute!();
                                              widget.onDismissed();
                                            },
                                    ),
                                  const SizedBox(height: 8),
                                  const WorkbenchCommandSectionLabel('资源'),
                                ],
                                if (results.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.fromLTRB(4, 8, 4, 8),
                                    child: Text(
                                      '未找到匹配资源',
                                      style: TextStyle(
                                        color: WorkbenchUiTokens.muted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  )
                                else
                                  for (final resource in results)
                                    WorkbenchCommandTile(
                                      title: resource.title,
                                      subtitle: resource.subtitle,
                                      leading: Icon(
                                        CommandPalette._iconForType(
                                          resource.type,
                                        ),
                                      ),
                                      trailing: Text(
                                        CommandPalette
                                            ._typeLabels[resource.type]!,
                                      ),
                                      semanticLabel:
                                          '打开资源：${resource.title}',
                                      onTap: () =>
                                          widget.onResourceSelected(resource),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
