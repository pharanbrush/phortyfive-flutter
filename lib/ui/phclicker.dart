import 'dart:math';

import 'package:audioplayers/audioplayers.dart';

class Phclicker {
  final Random _random = Random();
  final _player = AudioPlayer();
  final _clickSound = AssetSource('sounds/clack.wav');

  double getRandomPitch() {
    const min = 0.95;
    const max = 1.1;
    return _random.nextDouble() * (max - min) + min;
  }

  void playSound() async {
    _player.play(_clickSound);
    //await _player.setPlaybackRate(_getRandomPitch());
  }
}
