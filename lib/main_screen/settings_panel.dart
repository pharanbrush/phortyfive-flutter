import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/utils/preferences.dart';
import 'package:pfs2/widgets/modal_panel.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/phtext_widgets.dart';

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.windowState,
    required this.appModel,
    required this.themeNotifier,
    required this.aboutMenu,
  });

  final PfsWindowState windowState;
  final PfsAppModel appModel;
  final ValueNotifier<String> themeNotifier;
  final ModalPanel aboutMenu;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _panelContainer(
          context,
          child: _panelContent(context),
        ),
      ],
    );
  }

  Widget _panelContent(BuildContext context) {
    Widget themesWidgets(BuildContext context, {required Widget child}) {
      return DropdownMenuTheme(
        data: DropdownMenuThemeData(
            menuStyle: const MenuStyle(alignment: Alignment.center),
            textStyle: Theme.of(context).textTheme.labelLarge),
        child: child,
      );
    }

    const divider = Divider(height: 32, thickness: 0.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context),
        themesWidgets(
          context,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallHeading('Window'),
              NotifierSwitchItem(
                title: const Text('Sounds'),
                notifier: windowState.isSoundsEnabled,
              ),
              // NotifierSwitchItem(
              //   title: const Text(PfsLocalization.alwaysOnTop),
              //   notifier: windowState.isAlwaysOnTop,
              // ),
              divider,
              const SmallHeading('Appearance'),
              themeSetting(context),
              divider,
              TextButton(
                onPressed: () => aboutMenu.open(),
                child: const Text('About...'),
              ),
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
          child: Text(PfsTheme.themeNames[key] ?? key.capitalizeFirst ?? ''),
        ));
      }
    }

    return themeMenuItems;
  }

  Widget _panelContainer(BuildContext context, {required Widget child}) {
    const double panelFixedWidth = 380;
    //const double panelFixedHeight = 300;
    const double top = Phbuttons.windowTitleBarHeight + 25;
    const double side = 30;

    var material =
        Theme.of(context).extension<PfsAppTheme>()?.boxPanelMaterialBuilder ??
            PfsAppTheme.defaultBoxPanelMaterial;

    return Positioned(
      top: top,
      right: side,
      child: SizedBox(
        width: panelFixedWidth,
        child: material(
          child: Padding(
            padding: const EdgeInsets.only(
              left: 50,
              right: 50,
              top: 30,
              bottom: 30,
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

class NotifierSwitchItem extends StatelessWidget {
  const NotifierSwitchItem({
    super.key,
    required this.notifier,
    required this.title,
    this.onChanged,
  });

  final ValueNotifier<bool> notifier;
  final Widget title;
  final Function()? onChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: notifier,
      builder: (_, value, __) {
        return SwitchListTile(
          value: value,
          onChanged: (value) {
            notifier.value = value;
            onChanged?.call();
          },
          title: title,
          dense: true,
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
