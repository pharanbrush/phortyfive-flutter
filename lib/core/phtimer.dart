class Phtimer {
  static const int defaultDuration = 45;
  static Duration tickInterval = const Duration(milliseconds: 100);

  Duration _timeLeft = const Duration(seconds: defaultDuration);
  Duration _duration = const Duration(seconds: defaultDuration);
  DateTime _lastTime = DateTime.now();
  bool _elapsedThisRound = false;
  bool _isActive = false;
  
  Duration get duration => _duration;

  double get percentElapsed =>
      1.0 -
      (_timeLeft.inMilliseconds.toDouble() / _duration.inMilliseconds.toDouble());

  bool get isActive => _isActive;

  Function()? onElapse;

  void setActive(bool active) {
    _clearLastTime();
    _isActive = active;
  }

  void _clearLastTime() {
    _lastTime = DateTime.now();
  }

  void setDuration(Duration newDuration) {
    if (_duration < const Duration(seconds: 1)) return;
    
    _duration = newDuration;
    _elapsedThisRound = false;
  }

  void restart() {
    _clearLastTime();
    _timeLeft = _duration;
    _elapsedThisRound = false;
  }

  void handleTick() {
    if (isActive) {
      _updateTimeLeft();

      if (!_elapsedThisRound && _timeLeft.inMilliseconds < 0) {
        _elapsedThisRound = true;
        onElapse!();
      }
    }
  }

  void _updateTimeLeft() {
    final now = DateTime.now();
    final deltaTime = now.difference(_lastTime);

    _timeLeft -= deltaTime;
    _lastTime = now;
  }
}
