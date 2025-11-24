import 'dart:math' as math;

import 'package:flutter/foundation.dart';

extension BoolNotifierToggle on ValueNotifier<bool> {
  void toggle() {
    value = !value;
  }
}

extension NumNotifierIncrement on ValueNotifier<num> {
  void incrementClamped(num increment, num min, num max) {
    final newValueCandidate = value + increment;
    value = math.min(math.max(newValueCandidate, min), max);
  }
}
