import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    minimumSize: Size(460, 320),
    size: Size(720, 860),
    title: 'Phorty-Five Seconds',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp(
    appModel: PfsAppModel(),
  ));
}

class MyApp extends StatelessWidget {
  final Circulator circulator = Circulator();
  final PfsAppModel appModel;
  final ValueNotifier<String> theme =
      ValueNotifier<String>(PfsTheme.defaultTheme);

  MyApp({Key? key, required this.appModel}) : super(key: key);

  final navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PfsAppModel>(
      model: appModel,
      child: ScopedModel<PhtimerModel>(
        model: appModel.timerModel,
        child: ValueListenableBuilder(
          valueListenable: theme,
          builder: (context, value, child) {
            return MaterialApp(
              navigatorKey: navigatorKey,
              debugShowCheckedModeBanner: false,
              title: 'PhortyFive Seconds',
              theme: PfsTheme.getTheme(theme.value),
              home: Scaffold(
                body: MainScreen(
                  model: appModel,
                  theme: theme,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
