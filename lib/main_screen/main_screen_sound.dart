import 'dart:math';
import 'package:flutter/widgets.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

mixin MainScreenSound<T extends StatefulWidget> on State<T> {
  final Random _soundRandom = Random();
  AudioSource? _clickSound;

  static const assetKey = "assets/sounds/clack.wav";

  bool get isSoundsEnabled;
  bool get isTimerRunning;

  @override
  void initState() {
    SoLoud.instance
        .init(bufferSize: 512)
        .then(
          (_) {
            return SoLoud.instance.loadAsset(assetKey);
          },
        )
        .then(
          (loadedAsset) {
            _clickSound = loadedAsset;
          },
        );
    super.initState();
  }

  void playClickSound({bool playWhilePaused = false}) {
    if (!isSoundsEnabled) return;
    if (!isTimerRunning && !playWhilePaused) return;
    _playSound();
  }

  double _getRandomPitch() {
    const min = 0.92;
    const max = 1.15;
    return _soundRandom.nextDouble() * (max - min) + min;
  }

  void _playSound() {
    final sound = _clickSound;
    if (sound == null) return;

    final soloud = SoLoud.instance;
    final handle = soloud.play(sound);
    soloud.setRelativePlaySpeed(handle, _getRandomPitch());
  }
}
