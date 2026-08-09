import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Read-only MCP configuration preview with deliberately disabled future tools.
class McpWorkspace extends StatelessWidget {
  const McpWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '只读 JSON 预览',
                  style: MacosTheme.of(context).typography.headline,
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _DisabledFutureControl(
                      label: '复制配置',
                      tooltip: '视觉占位：尚未接入剪贴板',
                    ),
                    _DisabledFutureControl(
                      label: '在终端打开',
                      tooltip: '视觉占位：尚未接入终端',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(height: 1, color: MacosTheme.of(context).dividerColor),
          Padding(
            padding: const EdgeInsets.all(22),
            child: DefaultTextStyle(
              style: MacosTheme.of(
                context,
              ).typography.body.copyWith(height: 1.65, fontFamily: 'Menlo'),
              child: const Text(
                '{\n'
                '  "mcpServers": {\n'
                '    "filesystem": {\n'
                '      "command": "mock-server",\n'
                '      "args": ["/visual/preview/only"],\n'
                '      "disabled": true\n'
                '    }\n'
                '  }\n'
                '}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DisabledFutureControl extends StatelessWidget {
  const _DisabledFutureControl({required this.label, required this.tooltip});

  final String label;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
      message: tooltip,
      child: Semantics(
        label: '$label：$tooltip',
        button: true,
        enabled: false,
        child: PushButton(
          controlSize: ControlSize.regular,
          semanticLabel: label,
          onPressed: null,
          child: Text(label),
        ),
      ),
    );
  }
}
