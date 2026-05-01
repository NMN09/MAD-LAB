import 'package:flutter/material.dart';

/// Lightweight hover: just color shift + subtle lift. No scale (avoids lag).
class HoverScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale; // kept for API compat, ignored

  const HoverScale({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 1.0});

  @override
  State<HoverScale> createState() => _HoverScaleState();
}

class _HoverScaleState extends State<HoverScale> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final interactive = widget.onTap != null || widget.onLongPress != null;
    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      transform: _hovering ? (Matrix4.identity()..translate(0.0, -1.5)) : Matrix4.identity(),
      child: widget.child,
    );

    if (interactive) {
      content = GestureDetector(onTap: widget.onTap, onLongPress: widget.onLongPress, child: content);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: interactive ? SystemMouseCursors.click : MouseCursor.defer,
      child: content,
    );
  }
}

/// Color-change hover button with subtle lift
class HoverColorButton extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color hoverColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const HoverColorButton({
    super.key, required this.child, required this.baseColor, required this.hoverColor,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
    this.onTap,
  });

  @override
  State<HoverColorButton> createState() => _HoverColorButtonState();
}

class _HoverColorButtonState extends State<HoverColorButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: widget.padding,
          transform: _hovering ? (Matrix4.identity()..translate(0.0, -1.5)) : Matrix4.identity(),
          decoration: BoxDecoration(
            color: _hovering ? widget.hoverColor : widget.baseColor,
            borderRadius: widget.borderRadius,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
