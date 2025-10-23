import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';

class FirstActionSheet extends StatelessWidget {
  const FirstActionSheet({super.key});

  static const _windowAlignmentMargin = EdgeInsets.fromLTRB(0, 0, 25, 45);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        margin: _windowAlignmentMargin,
        child: Animate(
          effects: const [
            Phanimations.slideUpEffect,
            Phanimations.growBottomEffect
          ],
          child: _box(context),
        ),
      ),
    );
  }

  Widget _box(BuildContext context) {
    final theme = Theme.of(context);

    final TextStyle? titleStyle = theme.textTheme.titleMedium;
    final Color downArrowColor = theme.colorScheme.onSurfaceVariant;

    const double firstActionIconSize = 100;

    Icon firstActionIcon = Icon(
      Icons.image,
      size: firstActionIconSize,
      color: titleStyle?.color ?? downArrowColor,
    );
    
    final panelMaterial = PfsAppTheme.boxPanelFrom(Theme.of(context));

    return SizedBox(
      width: 350,
      height: 250,
      child: panelMaterial(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Stack(children: [
            DefaultTextStyle(
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  firstActionIcon,
                  const SizedBox(height: 8),
                  Text(
                    'Get started by loading images!',
                    style: titleStyle,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'You can also drag & drop images into the window.',
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(flex: 5),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(
                  PfsTheme.downIcon,
                  color: downArrowColor,
                ).animate(
                  effects: const [Phanimations.slideUpEffect],
                  onPlay: (controller) => controller.repeat(reverse: true),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
