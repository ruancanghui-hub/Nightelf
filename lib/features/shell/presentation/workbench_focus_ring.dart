import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

/// Owns keyboard focus and paints an Apple-style accent ring around an action.
class WorkbenchFocusRing extends StatefulWidget {
  const WorkbenchFocusRing({
    required this.focusKey,
    required this.indicatorKey,
    required this.onActivate,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    super.key,
  });

  final Key focusKey;
  final Key indicatorKey;
  final VoidCallback onActivate;
  final Widget child;
  final BorderRadius borderRadius;

  @override
  State<WorkbenchFocusRing> createState() => _WorkbenchFocusRingState();
}

class _WorkbenchFocusRingState extends State<WorkbenchFocusRing> {
  late final FocusNode _focusNode = FocusNode(debugLabel: 'workbench-action');
  bool _hasFocus = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
            event.logicalKey == LogicalKeyboardKey.space)) {
      widget.onActivate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final focusColor = _hasFocus
        ? MacosTheme.of(context).primaryColor
        : const Color(0x00000000);

    return Focus(
      key: widget.focusKey,
      focusNode: _focusNode,
      onFocusChange: (hasFocus) => setState(() => _hasFocus = hasFocus),
      onKeyEvent: _handleKey,
      child: AnimatedContainer(
        key: widget.indicatorKey,
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          border: Border.all(color: focusColor, width: 2),
        ),
        child: widget.child,
      ),
    );
  }
}
