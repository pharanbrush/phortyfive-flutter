import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/phlutter/bitsdojo_phwindow.dart';
import 'package:pfs2/phlutter/escape_route.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/themes/window_button_colors.dart';
import 'package:pfs2/models/preferences.dart';
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
  final PfsWindowState windowState = PfsWindowState();

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
                body: WindowWrapper(
                  windowState: windowState,
                  child: EscapeNavigator(
                    child: MainScreen(
                      model: appModel,
                      theme: theme,
                      windowState: windowState,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class WindowWrapper extends StatelessWidget {
  const WindowWrapper({
    super.key,
    required this.child,
    required this.windowState,
  });

  final Widget child;
  final PfsWindowState windowState;

  @override
  Widget build(BuildContext context) {
    Widget titlebar() {
      final theme = Theme.of(context);
      final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;
      final Color titleBarColor =
          borderSide == null ? Colors.transparent : borderSide.color;

      return WindowTitleBarBox(
        child: Container(
          decoration: BoxDecoration(color: titleBarColor),
          child: RepaintBoundary(
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 8,
                        ),
                        child: Row(
                          children: [
                            Image.memory(
                              PfsTheme.pfsIconBytes,
                              filterQuality: FilterQuality.medium,
                              color: const Color(0x7EFFFFFF),
                              colorBlendMode: BlendMode.modulate,
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              pfsAppTitle,
                              style: TextStyle(
                                  color: Color(0x7E999999), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      MoveWindow(),
                    ],
                  ),
                ),
                KeepWindowOnTopButton(notifier: windowState.isAlwaysOnTop),
                const WindowButtons(),
              ],
            ),
          ),
        ),
      );
    }

    Widget windowBorderWrapper(BuildContext context, {required Widget child}) {
      final theme = Theme.of(context);
      final borderSide = theme.extension<PfsAppTheme>()?.appWindowBorderSide;
      final double borderSideWidth = borderSide?.width ?? 0;

      return Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(
              left: borderSideWidth,
              right: borderSideWidth,
              bottom: borderSideWidth,
            ),
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
              shape: Border(
                bottom: borderSide,
                left: borderSide,
                right: borderSide,
              ),
              child: const SizedBox.expand(),
            )
        ],
      );
    }

    return windowBorderWrapper(context, child: child);
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
