import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/main_args.dart' as main_args;
import 'package:pfs2/main_screen/annotations_tool.dart';
import 'package:pfs2/main_screen/macos/macos_window_events.dart'
    as macos_window;
import 'package:pfs2/main_window_wrapper.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/main_screen/main_screen.dart';
import 'package:pfs2/phlutter/escape_route.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/remember_window_size.dart'
    as remember_window_size;
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/models/pfs_preferences.dart' as pfs_preferences;
import 'package:window_manager/window_manager.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  if (Platform.isMacOS) {
    await macos_window.bindWindowDelegate();
  }

  if (args.isNotEmpty) {
    main_args.appFileToLoadFromMainArgs = args.first;
  }

  final initialTheme = await pfs_preferences.themePreference
      .getValue(defaultValue: PfsTheme.defaultTheme);

  remember_window_size.appRememberWindowSizeNotifier.value =
      await remember_window_size.getRememberWindowSizePreference();

  final Size windowSize;
  const defaultWindowSize = Size(720, 860);
  if (remember_window_size.appRememberWindowSizeNotifier.value) {
    windowSize = await remember_window_size.getWindowSizePreference(
        defaultSize: defaultWindowSize);
  } else {
    windowSize = defaultWindowSize;
  }

  runApp(MyApp(
    appModel: PfsAppModel(),
    initialTheme: initialTheme,
  ));

  doWhenWindowReady(() {
    appWindow
      ..minSize = const Size(460, 320)
      ..title = PfsLocalization.appTitle
      ..size = windowSize;

    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  final Circulator circulator = Circulator();
  final PfsAppModel appModel;
  final ValueNotifier<String> theme;
  final annotationsModel = AnnotationsModel();
  final PfsWindowState windowState = PfsWindowState();

  MyApp({
    super.key,
    required this.appModel,
    String initialTheme = PfsTheme.defaultTheme,
  }) : theme = ValueNotifier<String>(initialTheme);

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    final mainTree = ValueListenableBuilder(
      valueListenable: theme,
      builder: (_, __, ___) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: PfsLocalization.appTitle,
          theme: PfsTheme.getTheme(theme.value),
          home: Scaffold(
            body: WindowWrapper(
              windowState: windowState,
              child: MainScreen(
                model: appModel,
                theme: theme,
                windowState: windowState,
              ),
            ),
          ),
        );
      },
    );

    return ModelScope<PfsAppModel>(
      model: appModel,
      child: ModelScope<AnnotationsModel>(
        model: annotationsModel,
        child: ModelScope<PhtimerModel>(
          model: appModel.timerModel,
          child: EscapeNavigator(
            child: mainTree,
          ),
        ),
      ),
    );
  }
}
