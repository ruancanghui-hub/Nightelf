import 'package:ai_workbench/features/command_palette/application/command_palette_controller.dart';
import 'package:ai_workbench/features/command_palette/domain/workbench_command.dart';
import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

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

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Semantics(
        label: '命令面板',
        scopesRoute: true,
        explicitChildNodes: true,
        child: Container(
          color: const Color(0x66000000),
          alignment: const Alignment(0, -0.55),
          child: Container(
            width: 560,
            constraints: const BoxConstraints(maxHeight: 520),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: MacosTheme.of(context).canvasColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MacosTheme.of(context).dividerColor),
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
                        Text(
                          '命令面板',
                          style: MacosTheme.of(context).typography.title2,
                        ),
                        const Spacer(),
                        MacosIconButton(
                          icon: const Text('×'),
                          semanticLabel: '关闭命令面板',
                          onPressed: widget.onDismissed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Semantics(
                      label: '搜索所有资源',
                      textField: true,
                      child: MacosSearchField(
                        autofocus: true,
                        placeholder: '搜索所有资源',
                        onChanged: _controller.updateQuery,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (commands.isNotEmpty) ...[
                              Text(
                                '命令',
                                style: MacosTheme.of(
                                  context,
                                ).typography.headline,
                              ),
                              const SizedBox(height: 8),
                              for (final command in commands)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: PushButton(
                                    controlSize: ControlSize.large,
                                    semanticLabel: '执行命令：${command.label}',
                                    onPressed: command.execute == null
                                        ? null
                                        : () async {
                                            await command.execute!();
                                            widget.onDismissed();
                                          },
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        command.shortcutLabel == null
                                            ? command.label
                                            : '${command.label}  ·  ${command.shortcutLabel}',
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              Text(
                                '资源',
                                style: MacosTheme.of(
                                  context,
                                ).typography.headline,
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (results.isEmpty)
                              Text(
                                '未找到匹配资源',
                                style: MacosTheme.of(context).typography.body,
                              )
                            else
                              for (final resource in results)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: PushButton(
                                    controlSize: ControlSize.large,
                                    semanticLabel: '打开资源：${resource.title}',
                                    onPressed: () =>
                                        widget.onResourceSelected(resource),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(resource.title),
                                    ),
                                  ),
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
    );
  }
}
