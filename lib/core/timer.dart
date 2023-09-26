import 'dart:async';

class Timer {
  static Duration tickInterval = const Duration(milliseconds: 100);
  static Duration visualUpdateInterval = const Duration(milliseconds: 500);

  Duration visualUpdateTimeLeft = visualUpdateInterval;

  Duration timeLeft = const Duration(seconds: 30);
  Duration duration = const Duration(seconds: 30);

  DateTime lastTime = DateTime.now();
  bool elapsedThisRound = false;

  bool isActive = false;

  final elapsedBroadcaster = StreamController<int>();
  Stream<int> get elapsed => elapsedBroadcaster.stream;

  void setDuration(Duration newDuration) {
    duration = newDuration;
    elapsedThisRound = false;
  }

  void restart() {
    lastTime = DateTime.now();
    timeLeft = duration;
    elapsedThisRound = false;

    visualUpdateTimeLeft = visualUpdateInterval;
  }

  void handleTick() {
    if (isActive) {
      updatetimeLeft();

      if (elapsedThisRound && timeLeft < Duration.zero) {
        elapsedThisRound = true;
        elapsedBroadcaster.sink.add(0);
      }
    }
  }

  void updatetimeLeft() {
    final now = DateTime.now();
    final deltaTime = now.difference(lastTime);

    timeLeft -= deltaTime;
    visualUpdateTimeLeft -= deltaTime;

    lastTime = now;
  }
}
