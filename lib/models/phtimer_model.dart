import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pfs2/core/phtimer.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/simple_notifier.dart';

class PhtimerModel {
  PhtimerModel({
    required this.onElapse,
  });

  static PhtimerModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<PhtimerModel>>()!
        .model;
  }

  late final Phtimer timer = Phtimer(
    onElapse: handleElapsed,
  );
  Timer? ticker;

  bool get isRunning => timer.isActive;
  int get currentDurationSeconds => timer.duration.inSeconds;
  double get progressPercent => timer.percentElapsed;

  final Set<Object> _timerPausers = {};
  void registerPauser(Object o) => _timerPausers.add(o);
  void deregisterPauser(Object o) => _timerPausers.remove(o);

  final void Function()? onElapse;
  // void Function()? onReset;
  // void Function()? onPlayPause;
  void Function()? onDurationChangeSuccess;
  final m = ChangeNotifier();
  late final playPauseAndProgressNotifier = Listenable.merge([
    playPauseNotifier,
    resetNotifier,
    durationChangeNotifier,
    tickNotifier,
  ]);
  final playPauseNotifier = SimpleNotifier();
  final tickNotifier = SimpleNotifier();
  final resetNotifier = SimpleNotifier();
  final elapseNotifier = SimpleNotifier();
  final durationChangeNotifier = SimpleNotifier();

  void trySetDurationSecondsInput(String secondsString) {
    final int? seconds = int.tryParse(secondsString);
    if (seconds != null) {
      setDurationSeconds(seconds);
    }
  }

  void setDurationSeconds(int seconds) {
    if (seconds < 1) return;

    timer.setDuration(Duration(seconds: seconds));
    onDurationChangeSuccess?.call();
    durationChangeNotifier.notify();
    resetTimer();
  }

  void resetTimer() {
    timer.reset();
    resetNotifier.notify();
  }

  void playPauseToggleTimer() {
    setActive(!timer.isActive);
  }

  void setActive(bool active) {
    timer.setActive(active);
    playPauseNotifier.notify();
  }

  void tryInitialize() {
    ticker?.cancel();
    ticker = Timer.periodic(Phtimer.tickInterval, _handleTickerTick);
  }

  void handleElapsed() {
    onElapse?.call();
    elapseNotifier.notify();
  }

  void _handleTickerTick(Timer _) {
    if (!timer.isActive) return;
    if (_timerPausers.isNotEmpty) return;

    timer.update();
    tickNotifier.notify();
  }
}
