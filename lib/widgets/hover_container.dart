import 'package:flutter/material.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';

class HoverContainer extends StatefulWidget {
  const HoverContainer({
    super.key,
    required this.hoverBackgroundColor,
    required this.child,
    this.duration = Phanimations.defaultDuration,
    this.borderRadius = const BorderRadius.all(Radius.circular(25)),
  });

  final Color hoverBackgroundColor;
  final Widget child;
  final Duration duration;
  final BorderRadius borderRadius;

  @override
  State<HoverContainer> createState() => _HoverContainerState();
}

class _HoverContainerState extends State<HoverContainer> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: (event) => setState(() => isHovering = true),
      onExit: (event) => setState(() => isHovering = false),
      child: AnimatedContainer(
        duration: widget.duration,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          color: isHovering
              ? widget.hoverBackgroundColor
              : widget.hoverBackgroundColor.withAlpha(0x00),
        ),
        child: widget.child,
      ),
    );
  }
}
