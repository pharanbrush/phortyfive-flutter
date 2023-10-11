import 'dart:async';

import 'package:pfs2/core/phtimer.dart';
import 'package:scoped_model/scoped_model.dart';

class PhtimerModel extends Model {
  static const bool startTimerOnInitialize = true;

  static ScopedModelDescendant<PhtimerModel> scope(
          ScopedModelDescendantBuilder<PhtimerModel> builder) =>
      ScopedModelDescendant<PhtimerModel>(builder: builder);

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

  void trySetDurationSecondsInput(String secondsString) {
    int? seconds = int.tryParse(secondsString);
    if (seconds != null) {
      setDurationSeconds(seconds);
    }
  }

  void setDurationSeconds(int seconds) {
    timer.setDuration(Duration(seconds: seconds));
    onDurationChangeSuccess?.call();
    restartTimer();
  }

  void restartTimer() {
    timer.restart();
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

    if (timer.onElapse == null) {
      timer.onElapse = () => handleElapsed();
      if (startTimerOnInitialize) {
        timer.setActive(true);
      }
    }
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
