import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pfs2/core/phtimer.dart';
import 'package:pfs2/phlutter/model_scope.dart';
import 'package:pfs2/phlutter/simple_notifier.dart';
import 'package:scoped_model/scoped_model.dart';

class PhtimerModel extends Model {
  static ScopedModelDescendant<PhtimerModel> scope(
          ScopedModelDescendantBuilder<PhtimerModel> builder) =>
      ScopedModelDescendant<PhtimerModel>(builder: builder);

  static PhtimerModel of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ModelScope<PhtimerModel>>()!
        .model;
  }

  final Phtimer timer = Phtimer();
  Timer? ticker;

  bool get isRunning => timer.isActive;
  int get currentDurationSeconds => timer.duration.inSeconds;
  double get progressPercent => timer.percentElapsed;

  final Set<Object> _timerPausers = {};
  void registerPauser(Object o) => _timerPausers.add(o);
  void deregisterPauser(Object o) => _timerPausers.remove(o);

  void Function()? onElapse;
  void Function()? onReset;
  void Function()? onPlayPause;
  void Function()? onDurationChangeSuccess;
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
    onReset?.call();
    notifyListeners();
  }

  void playPauseToggleTimer() {
    setActive(!timer.isActive);
  }

  void setActive(bool active) {
    timer.setActive(active);
    onPlayPause?.call();
    notifyListeners();
  }

  void tryInitialize() {
    ticker = Timer.periodic(Phtimer.tickInterval, _handleTick);
    timer.onElapse ??= () => handleElapsed();
  }

  void handleElapsed() {
    onElapse?.call();
    notifyListeners();
  }

  void _handleTick(Timer _) {
    if (timer.isActive) {
      if (_timerPausers.isEmpty) {
        timer.handleTick();
      }

      //log('tick');
      notifyListeners();
    }
  }
}
