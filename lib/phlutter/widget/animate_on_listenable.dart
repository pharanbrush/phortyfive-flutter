import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimateOnListenable extends StatefulWidget {
  const AnimateOnListenable({
    super.key,
    required this.listenable,
    required this.effects,
    required this.child,
  });

  final Listenable listenable;
  final List<Effect> effects;
  final Widget child;

  @override
  State<AnimateOnListenable> createState() => _AnimateOnListenableState();
}

class _AnimateOnListenableState extends State<AnimateOnListenable> {
  final keyRng = math.Random();
  late String prefix = keyRng.nextInt(100).toString();
  late Key animateKey = Key("{prefix}${keyRng.nextInt(1000)}");
  bool animate = false;

  @override
  void initState() {
    super.initState();
    widget.listenable.addListener(handleChange);
  }

  @override
  void dispose() {
    widget.listenable.removeListener(handleChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: animateKey,
      effects: animate ? widget.effects : null,
      child: widget.child,
    );
  }

  void handleChange() {
    animate = true;
    setState(() => animateKey = Key("{prefix}${keyRng.nextInt(1000)}"));
  }
}
