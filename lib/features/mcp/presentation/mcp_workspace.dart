import 'package:ai_workbench/features/editor/presentation/text_editor_workspace.dart';
import 'package:ai_workbench/features/mcp/application/mcp_controller.dart';
import 'package:ai_workbench/features/mcp/domain/json_diagnostic.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

class McpWorkspace extends StatelessWidget {
  const McpWorkspace({super.key, this.controller, this.fallback});

  final McpController? controller;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockMcpSurface();
    }

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final session = controller.session;
        if (session == null) {
          return fallback ?? const _MockMcpSurface();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _McpActionsBar(controller: controller),
            if (controller.diagnostic != null)
              _DiagnosticBanner(diagnostic: controller.diagnostic!),
            Expanded(
              child: TextEditorWorkspace(session: session, title: 'MCP JSON'),
            ),
          ],
        );
      },
    );
  }
}

class _McpActionsBar extends StatelessWidget {
  const _McpActionsBar({required this.controller});

  final McpController controller;

  @override
  Widget build(BuildContext context) {
    final typography = MacosTheme.of(context).typography;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          PushButton(
            controlSize: ControlSize.small,
            semanticLabel: '格式化',
            onPressed: () => controller.format(),
            child: const Text('格式化'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '复制安全模板',
            onPressed: () => controller.copySafeTemplate(),
            child: const Text('复制安全模板'),
          ),
          MacosTooltip(
            message: '完整配置复制需 Phase 5 SecretStore',
            child: PushButton(
              controlSize: ControlSize.small,
              secondary: true,
              semanticLabel: '复制完整配置',
              onPressed: null,
              child: const Text('复制完整配置'),
            ),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '在终端打开',
            onPressed: () => controller.openTerminal(),
            child: const Text('在终端打开'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '创建副本',
            onPressed: () => controller.duplicate(),
            child: const Text('创建副本'),
          ),
          PushButton(
            controlSize: ControlSize.small,
            secondary: true,
            semanticLabel: '移到回收站',
            onPressed: () => controller.moveToTrash(),
            child: const Text('移到回收站'),
          ),
          if (controller.lastTrashPath != null)
            PushButton(
              controlSize: ControlSize.small,
              semanticLabel: '撤销回收',
              onPressed: () => controller.undoTrash(),
              child: const Text('撤销回收'),
            ),
          if (controller.statusMessage != null)
            Text(controller.statusMessage!, style: typography.caption1),
        ],
      ),
    );
  }
}

class _DiagnosticBanner extends StatelessWidget {
  const _DiagnosticBanner({required this.diagnostic});

  final JsonDiagnostic diagnostic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'JSON 错误 · 第 ${diagnostic.line} 行第 ${diagnostic.column} 列：${diagnostic.message}',
        style: MacosTheme.of(
          context,
        ).typography.caption1.copyWith(color: MacosColors.systemRedColor),
      ),
    );
  }
}

class _MockMcpSurface extends StatelessWidget {
  const _MockMcpSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 420),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: MacosTheme.of(context).canvasColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MacosTheme.of(context).dividerColor),
      ),
      child: Text(
        '打开 Vault 中的 MCP 配置以编辑 JSON。',
        style: MacosTheme.of(context).typography.body,
      ),
    );
  }
}
