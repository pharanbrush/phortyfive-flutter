import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/utils/preferences.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    this.onDismiss,
    required this.windowState,
    required this.appModel,
    required this.themeNotifier,
  });

  final VoidCallback? onDismiss;
  final PfsWindowState windowState;
  final PfsAppModel appModel;
  final ValueNotifier<String> themeNotifier;

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
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: smallHeadingStyle(context)),
    );
  }

  Widget _panelContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context),
        DropdownMenuTheme(
          data: DropdownMenuThemeData(
              menuStyle: const MenuStyle(alignment: Alignment.center),
              textStyle: Theme.of(context).textTheme.labelLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              smallHeading('Window', context),
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
              const Divider(height: 32, thickness: 1),
              smallHeading('Appearance', context),
              themeSetting(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget themeSetting(BuildContext context) {
    const double radius = 6;
    const double indent = 16;

    return Row(
      children: [
        const Padding(
          padding: EdgeInsets.only(left: indent),
          child: Text('Theme'),
        ),
        const Spacer(),
        ValueListenableBuilder(
          valueListenable: themeNotifier,
          builder: (context, value, child) {
            return DropdownButton(
              value: themeNotifier.value,
              items: getThemeMenuItems(),
              underline: const SizedBox.shrink(),
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
              borderRadius: const BorderRadius.all(Radius.circular(radius)),
              itemHeight: 48,
              style: Theme.of(context).textTheme.bodyMedium,
              focusColor: Theme.of(context).highlightColor,
              onChanged: (newTheme) {
                themeNotifier.value = newTheme ?? PfsTheme.defaultTheme;
                Preferences.setTheme(themeNotifier.value);
              },
            );
          },
        ),
      ],
    );
  }

  List<DropdownMenuItem<String>> getThemeMenuItems() {
    final themeMenuItems = <DropdownMenuItem<String>>[];

    if (themeMenuItems.isEmpty) {
      for (var key in PfsTheme.themeMap.keys) {
        themeMenuItems.add(DropdownMenuItem(
          value: key,
          child: Text(key.capitalizeFirst ?? ''),
        ));
      }
    }

    return themeMenuItems;
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
