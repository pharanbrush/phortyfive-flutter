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
    // Probably don't await or try to do anything with the Future this returns
    // To prevent timing problems and crashing because of platform thread compatibility.
    // This seems to be a unpatched issue even in audioplayers 6.2
    _player.play(_clickSound); 
    //await _player.setPlaybackRate(_getRandomPitch());
  }
}
