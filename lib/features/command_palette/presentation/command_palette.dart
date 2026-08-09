import 'package:ai_workbench/features/shell/domain/workbench_resource.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// A visual-only command palette backed by the deterministic mock resources.
class CommandPalette extends StatefulWidget {
  const CommandPalette({
    required this.resources,
    required this.onResourceSelected,
    required this.onDismissed,
    super.key,
  });

  final List<WorkbenchResource> resources;
  final ValueChanged<WorkbenchResource> onResourceSelected;
  final VoidCallback onDismissed;

  @override
  State<CommandPalette> createState() => _CommandPaletteState();
}

class _CommandPaletteState extends State<CommandPalette> {
  String _query = '';

  List<WorkbenchResource> get _results {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return widget.resources;
    }
    return widget.resources.where((resource) {
      return resource.title.toLowerCase().contains(normalizedQuery) ||
          resource.subtitle.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

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
            child: Column(
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
                    onChanged: (query) => setState(() => _query = query),
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
            ),
          ),
        ),
      ),
    );
  }
}
