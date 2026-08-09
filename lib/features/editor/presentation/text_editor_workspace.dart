import 'package:ai_workbench/features/editor/application/document_session.dart';
import 'package:ai_workbench/features/editor/domain/document_descriptor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:re_editor/re_editor.dart';

class TextEditorWorkspace extends StatefulWidget {
  const TextEditorWorkspace({
    super.key,
    required this.session,
    this.title = '源码',
  });

  final DocumentSession session;
  final String title;

  @override
  State<TextEditorWorkspace> createState() => _TextEditorWorkspaceState();
}

class _TextEditorWorkspaceState extends State<TextEditorWorkspace> {
  late final CodeLineEditingController _controller;
  bool _syncingFromSession = false;

  @override
  void initState() {
    super.initState();
    _controller = CodeLineEditingController();
    widget.session.addListener(_onSessionChanged);
    if (widget.session.state.isLoading) {
      widget.session.load();
    } else {
      _applySessionText(widget.session.text);
    }
  }

  @override
  void didUpdateWidget(covariant TextEditorWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSessionChanged);
      widget.session.addListener(_onSessionChanged);
      if (widget.session.state.isLoading) {
        widget.session.load();
      } else {
        _applySessionText(widget.session.text);
      }
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSessionChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (!mounted) {
      return;
    }
    final text = widget.session.text;
    if (_controller.text != text &&
        (widget.session.state.isClean ||
            widget.session.state.isLoading ||
            widget.session.state.hasConflict)) {
      _applySessionText(text);
    }
    setState(() {});
  }

  void _applySessionText(String text) {
    _syncingFromSession = true;
    _controller.text = text;
    _syncingFromSession = false;
  }

  String get _statusLabel {
    final state = widget.session.state;
    return switch (state.status) {
      DocumentSessionStatus.loading => '读取中…',
      DocumentSessionStatus.clean => '已保存',
      DocumentSessionStatus.dirty => '未保存的更改',
      DocumentSessionStatus.saving => '保存中…',
      DocumentSessionStatus.externalConflict => '外部冲突',
      DocumentSessionStatus.failure => state.errorMessage ?? '出错',
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = MacosTheme.of(context);
    final typography = theme.typography;
    final readOnly = widget.session.descriptor.readOnly;
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFF5F5F7)
        : const Color(0xFF1C1C1E);
    final gutterColor = isDark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6C6C70);
    final selectionColor = theme.primaryColor.withValues(alpha: 0.35);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): () {
          widget.session.saveNow();
        },
      },
      child: Focus(
        autofocus: true,
        child: Container(
          constraints: const BoxConstraints(minHeight: 380),
          decoration: BoxDecoration(
            color: theme.canvasColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    Text(widget.title, style: typography.headline),
                    const Spacer(),
                    Text(_statusLabel, style: typography.caption1),
                    const SizedBox(width: 12),
                    PushButton(
                      controlSize: ControlSize.small,
                      onPressed: readOnly || !widget.session.state.isDirty
                          ? null
                          : () => widget.session.saveNow(),
                      child: const Text('保存'),
                    ),
                  ],
                ),
              ),
              if (widget.session.state.hasConflict)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(child: Text('磁盘上的文件已变化，请选择保留哪一版。')),
                      PushButton(
                        controlSize: ControlSize.small,
                        onPressed: () => widget.session.keepLocalVersion(),
                        child: const Text('保留编辑器'),
                      ),
                      const SizedBox(width: 8),
                      PushButton(
                        controlSize: ControlSize.small,
                        secondary: true,
                        onPressed: () => widget.session.keepDiskVersion(),
                        child: const Text('加载磁盘版'),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: CodeEditor(
                    controller: _controller,
                    readOnly: readOnly,
                    wordWrap:
                        widget.session.descriptor.language ==
                        DocumentLanguage.markdown,
                    onChanged: (_) {
                      if (_syncingFromSession) {
                        return;
                      }
                      widget.session.updateText(_controller.text);
                    },
                    style: CodeEditorStyle(
                      fontSize: 13,
                      fontFamily: 'Menlo',
                      fontHeight: 1.55,
                      textColor: textColor,
                      backgroundColor: theme.canvasColor,
                      cursorColor: theme.primaryColor,
                      selectionColor: selectionColor,
                      cursorLineColor: theme.primaryColor.withValues(
                        alpha: 0.08,
                      ),
                    ),
                    indicatorBuilder:
                        (
                          context,
                          editingController,
                          chunkController,
                          notifier,
                        ) {
                          return DefaultCodeLineNumber(
                            controller: editingController,
                            notifier: notifier,
                            textStyle: TextStyle(
                              color: gutterColor,
                              fontSize: 12,
                              fontFamily: 'Menlo',
                            ),
                          );
                        },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
