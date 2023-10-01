class Phtimer {
  static const int defaultDuration = 45;
  static Duration tickInterval = const Duration(milliseconds: 100);

  Duration timeLeft = const Duration(seconds: defaultDuration);
  Duration duration = const Duration(seconds: defaultDuration);
  
  double get percentElapsed => 1.0 - (timeLeft.inMilliseconds.toDouble() / duration.inMilliseconds.toDouble());

  DateTime lastTime = DateTime.now();
  bool elapsedThisRound = false;

  bool _isActive = false;
  
  bool get isActive => _isActive;
  
  Function()? onElapse;
  
  void setActive(bool active) {
    _clearLastTime();
    _isActive = active;
  }
  
  void _clearLastTime() {
    lastTime = DateTime.now();
  }

  void setDuration(Duration newDuration) {
    duration = newDuration;
    elapsedThisRound = false;
  }

  void restart() {
    _clearLastTime();
    timeLeft = duration;
    elapsedThisRound = false;
  }

  void handleTick() {
    if (isActive) {
      _updateTimeLeft();      

      if (!elapsedThisRound && timeLeft.inMilliseconds < 0) {
        elapsedThisRound = true;
        onElapse!();       
      }
    }
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final deltaTime = now.difference(lastTime);

    timeLeft -= deltaTime;

    lastTime = now;
  }
}
