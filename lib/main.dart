import 'package:flutter/material.dart';
import 'package:pfs2/core/circulator.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/screens/main_screen.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    title: 'Phorty-Five Seconds',
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(MyApp(
    model: PfsAppModel(),
  ));
}

class MyApp extends StatelessWidget {
  final Circulator circulator = Circulator();
  final PfsAppModel model;

  MyApp({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModel<PfsAppModel>(
      model: model,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PhortyFive Seconds',
        theme: ThemeData(
          colorScheme: _appColorScheme(),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      ),
    );
  }

  ColorScheme _appColorScheme() {
    ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      background: Colors.white,
      primaryContainer: Colors.white,
      secondaryContainer: Colors.white,
    );
    return colorScheme;
  }
}
