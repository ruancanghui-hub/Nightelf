import 'package:flutter/widgets.dart';

/// Shared emerald hover / press / pointer treatment used by sidebar rows and
/// overview resource lists.
class EmeraldInteractiveSurface extends StatefulWidget {
  const EmeraldInteractiveSurface({
    required this.child,
    this.onTap,
    this.selected = false,
    this.padding = EdgeInsets.zero,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.height,
    this.showSelectedBorder = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double? height;
  final bool showSelectedBorder;

  static const accent = Color(0xFF5DE7A7);
  static const selectedFill = Color(0xFF0C2B23);

  @override
  State<EmeraldInteractiveSurface> createState() =>
      _EmeraldInteractiveSurfaceState();
}

class _EmeraldInteractiveSurfaceState extends State<EmeraldInteractiveSurface> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final background = selected
        ? EmeraldInteractiveSurface.selectedFill
        : _pressed
        ? EmeraldInteractiveSurface.accent.withValues(alpha: 0.16)
        : _hovered
        ? EmeraldInteractiveSurface.accent.withValues(alpha: 0.10)
        : const Color(0x00000000);
    final borderColor = selected && widget.showSelectedBorder
        ? EmeraldInteractiveSurface.accent
        : _pressed
        ? EmeraldInteractiveSurface.accent.withValues(alpha: 0.55)
        : const Color(0x00000000);

    return MouseRegion(
      cursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          height: widget.height,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: widget.borderRadius,
            border: Border.all(color: borderColor),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
