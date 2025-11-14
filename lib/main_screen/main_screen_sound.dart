// import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

mixin MainScreenSound {
  // final Random _soundRandom = Random();
  final _player = AudioPlayer();
  final _clickSound = AssetSource('sounds/clack.wav');

  bool get isSoundsEnabled;
  bool get isTimerRunning;

  void playClickSound({bool playWhilePaused = false}) {
    if (!isSoundsEnabled) return;
    if (!isTimerRunning && !playWhilePaused) return;
    _playSound();
  }

  // double _getRandomPitch() {
  //   const min = 0.95;
  //   const max = 1.1;
  //   return _soundRandom.nextDouble() * (max - min) + min;
  // }

  void _playSound() async {
    _player.play(_clickSound);
    //await _player.setPlaybackRate(_getRandomPitch());
  }
}
