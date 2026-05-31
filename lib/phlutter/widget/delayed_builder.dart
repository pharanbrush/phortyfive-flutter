import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// This requires a new key every time it needs to restart its timer.
class DelayedBuilder<T> extends StatefulWidget {
  const DelayedBuilder({
    super.key,
    required this.builder,
    this.delay = const Duration(seconds: 1),
  });

  final Duration delay;
  final Widget Function(BuildContext context) builder;

  @override
  State<DelayedBuilder<T>> createState() => _DelayedBuilderState<T>();
}

class _DelayedBuilderState<T> extends State<DelayedBuilder<T>> {
  bool _showWidget = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.delay, () {
      if (mounted) {
        setState(() => _showWidget = true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _showWidget ? widget.builder(context) : const SizedBox.shrink();
  }
}

/// This widget shows and hides a widget depending on a condition and
/// checks the conditions again whenever the listenable changes.
class ValueListenableDelayedBuilder<T> extends StatefulWidget {
  const ValueListenableDelayedBuilder({
    super.key,
    required this.valueListenable,
    required this.showWhen,
    required this.builder,
    this.delay = const Duration(seconds: 1),
  });

  final ValueListenable<T> valueListenable;
  final Duration delay;
  final bool Function(T value) showWhen;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<ValueListenableDelayedBuilder<T>> createState() =>
      _ValueListenableDelayedBuilderState<T>();
}

class _ValueListenableDelayedBuilderState<T>
    extends State<ValueListenableDelayedBuilder<T>> {
  bool _isShowing = false;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    widget.valueListenable.addListener(_handleValueChange);
  }

  @override
  void dispose() {
    widget.valueListenable.removeListener(_handleValueChange);
    _delayTimer?.cancel();
    super.dispose();
  }

  void _handleValueChange() {
    if (widget.showWhen(widget.valueListenable.value)) {
      _delayTimer?.cancel();
      _delayTimer = Timer(widget.delay, () {
        if (mounted && widget.showWhen(widget.valueListenable.value)) {
          setState(() => _isShowing = true);
        }
      });
    } else {
      _delayTimer?.cancel();
      if (_isShowing) {
        setState(() => _isShowing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isShowing
        ? widget.builder(context, widget.valueListenable.value)
        : const SizedBox.shrink();
  }
}
