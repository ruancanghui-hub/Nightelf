import 'package:ai_workbench/features/launchers/application/launcher_controller.dart';
import 'package:ai_workbench/shared/ui/workbench_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class LauncherWorkspace extends StatelessWidget {
  const LauncherWorkspace({
    super.key,
    this.controller,
    this.fallback,
    this.onRenamed,
  });

  final LauncherController? controller;
  final Widget? fallback;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return fallback ?? const _MockLauncherSurface();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.document == null) {
          return fallback ?? const _MockLauncherSurface();
        }
        return _LauncherEditor(
          controller: controller,
          onRenamed: onRenamed,
        );
      },
    );
  }
}

class _LauncherEditor extends StatefulWidget {
  const _LauncherEditor({required this.controller, this.onRenamed});

  final LauncherController controller;
  final Future<void> Function(String relativePath)? onRenamed;

  @override
  State<_LauncherEditor> createState() => _LauncherEditorState();
}

class _LauncherEditorState extends State<_LauncherEditor> {
  late final TextEditingController _titleController;
  String? _boundId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.controller.document?.title ?? '',
    );
    _boundId = widget.controller.document?.id;
  }

  @override
  void didUpdateWidget(covariant _LauncherEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    final document = widget.controller.document;
    if (document != null && document.id != _boundId) {
      _boundId = document.id;
      _titleController.text = document.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _saveTitle() async {
    final renamed = await widget.controller.rename(_titleController.text);
    await widget.onRenamed?.call(renamed.relativePath);
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final document = controller.document!;
    final missing = controller.isScriptMissing;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const WorkbenchFieldLabel('标题'),
          const SizedBox(height: 8),
          WorkbenchInput(
            key: const ValueKey('launcher-title-field'),
            controller: _titleController,
            placeholder: '启动器标题',
            semanticLabel: '启动器标题',
            onSubmitted: (_) => _saveTitle(),
            onEditingComplete: _saveTitle,
          ),
          const SizedBox(height: 20),
          const WorkbenchFieldLabel('脚本路径'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06100D),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF1B4D40)),
                  ),
                  child: Text(
                    document.scriptPath.isEmpty ? '尚未选择脚本' : document.scriptPath,
                    key: const ValueKey('launcher-script-path'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: missing
                          ? const Color(0xFFE35D6A)
                          : const Color(0xFFF2FFF8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              WorkbenchButton(
                semanticLabel: '选择文件',
                variant: WorkbenchButtonVariant.outline,
                onPressed: controller.pickScriptPath,
                child: const Text('选择文件'),
              ),
            ],
          ),
          if (missing) ...[
            const SizedBox(height: 8),
            const Text(
              '路径无效：找不到文件',
              key: ValueKey('launcher-missing-path'),
              style: TextStyle(color: Color(0xFFE35D6A), fontSize: 12),
            ),
          ],
          const SizedBox(height: 24),
          WorkbenchButton(
            semanticLabel: '启动',
            size: WorkbenchButtonSize.lg,
            enabled: controller.canLaunch,
            onPressed: controller.canLaunch ? controller.launch : null,
            leading: const Icon(LucideIcons.rocket, size: 16),
            child: const Text('启动'),
          ),
          if (controller.errorMessage != null && !missing) ...[
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: const TextStyle(color: Color(0xFFE35D6A), fontSize: 12),
            ),
          ],
          if (controller.statusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.statusMessage!,
              style: const TextStyle(color: Color(0xFF5DE7A7), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _MockLauncherSurface extends StatelessWidget {
  const _MockLauncherSurface();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '启动器',
            style: TextStyle(
              color: Color(0xFFF2FFF8),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '选择一条启动器后，可配置脚本路径并交给系统运行。',
            style: TextStyle(color: Color(0xFF9BB4AB), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
