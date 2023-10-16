import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, this.onDismiss, required this.windowState});

  final VoidCallback? onDismiss;
  final PfsWindowState windowState;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalUnderlay(onDismiss: onDismiss),
        _panelContainer(
          context,
          child: _panelContent(context),
        ).animate(effects: [
          Phanimations.fadeInEffect,
          Phanimations.largeRightPanelSlideInEffect
        ]),
      ],
    );
  }

  static TextStyle? smallHeadingStyle(BuildContext context) {
    return Theme.of(context).textTheme.titleSmall;
  }

  Widget smallHeading(String text, BuildContext context) {
    return Text(text, style: smallHeadingStyle(context));
  }

  Widget _panelContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Slider(value: 0.5, onChanged: (x) {}),
            smallHeading('Stuff', context),
            //CheckboxListTile.adaptive(value: true, onChanged: (x) {}),

            SwitchListTile(
              value: windowState.isSoundsEnabled.boolValue,
              onChanged: (newValue) =>
                  windowState.isSoundsEnabled.set(newValue),
              title: const Text('Sounds'),
              dense: true,
              visualDensity: VisualDensity.compact,
            ),
            SwitchListTile(
              value: windowState.isAlwaysOnTop.boolValue,
              onChanged: (newValue) =>
                  windowState.isAlwaysOnTop.set(newValue),
              title: const Text(PfsLocalization.alwaysOnTop),
              dense: true,
              visualDensity: VisualDensity.compact,
            ),

            const Divider(height: 1),
            //const AboutListTile(),
          ],
        ),
      ],
    );
  }

  Widget _panelContainer(BuildContext context, {required Widget child}) {
    const double panelFixedWidth = 400;

    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: panelFixedWidth,
        child: Material(
          type: MaterialType.canvas,
          elevation: 10,
          color: Theme.of(context).colorScheme.surface,
          //shape: RoundedRectangleBorder(borderRadius: bord),
          //
          child: Padding(
            padding: const EdgeInsets.only(
              left: 50,
              right: 50,
              top: 30,
              bottom: 20,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        'Settings',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
