import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/themes/window_button_colors.dart';
import 'package:pfs2/utils/preferences.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:window_manager/window_manager.dart';

const pfsAppTitle = 'Phorty-Five Seconds';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  final initialTheme = await Preferences.getTheme();

  runApp(MyApp(
    appModel: PfsAppModel(),
    initialTheme: initialTheme,
  ));

  doWhenWindowReady(() {
    final win = appWindow;
    win.minSize = const Size(460, 320);
    win.size = const Size(720, 860);
    win.title = pfsAppTitle;
    win.show();
  });
}

class MyApp extends StatelessWidget {
  final Circulator circulator = Circulator();
  final PfsAppModel appModel;
  final ValueNotifier<String> theme;

  MyApp({
    super.key,
    required this.appModel,
    String initialTheme = PfsTheme.defaultTheme,
  }) : theme = ValueNotifier<String>(initialTheme);

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PfsAppModel>(
      model: appModel,
      child: ScopedModel<PhtimerModel>(
        model: appModel.timerModel,
        child: ValueListenableBuilder(
          valueListenable: theme,
          builder: (themeContext, __, ___) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: pfsAppTitle,
              theme: PfsTheme.getTheme(theme.value),
              home: Scaffold(
                body: windowWrapper(
                  themeContext,
                  child: MainScreen(
                    model: appModel,
                    theme: theme,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget windowWrapper(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;

    Widget titlebar() {
      return WindowTitleBarBox(
        child: Row(children: [
          Expanded(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 6,
                  ),
                  child: Opacity(
                    opacity: 0.35,
                    child: Image.memory(
                      PfsTheme.pfsIconBytes,
                      filterQuality: FilterQuality.medium,
                    ),
                  ),
                ),
                // const Padding(
                //   padding: EdgeInsets.symmetric(vertical: 8, horizontal: 32),
                //   child: Text(
                //     pfsAppTitle,
                //     style: TextStyle(
                //       color: Color(0xAA999999),
                //       fontSize: 12
                //     ),
                //   ),
                // ),

                MoveWindow(),
              ],
            ),
          ),
          const WindowButtons(),
        ]),
      );
    }

    Widget windowBorderWrapper({required Widget child}) {
      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(borderSide?.width ?? 0),
            child: child,
          ),
          Column(
            children: [
              titlebar(),
              Expanded(child: Container()),
            ],
          ),
          if (borderSide != null)
            Material(
              type: MaterialType.transparency,
              shape: Border.fromBorderSide(borderSide),
              child: const SizedBox.expand(),
            )
        ],
      );
    }

    return windowBorderWrapper(child: child);
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isLightTheme =
        Theme.of(context).colorScheme.brightness == Brightness.light;

    final buttonColors =
        isLightTheme ? buttonColorsOnLight : buttonColorsOnDark;

    final closeButtonColors =
        isLightTheme ? closeButtonColorsOnLight : closeButtonColorsOnDark;

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}
