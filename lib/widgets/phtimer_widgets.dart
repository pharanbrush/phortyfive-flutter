import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/phtimer_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/widgets/phbuttons.dart';

class TimerControls extends StatelessWidget {
  const TimerControls({
    super.key,
    required this.playPauseIconController,
  });

  final AnimationController playPauseIconController;

  @override
  Widget build(BuildContext context) {
    // PARTS
    final restartTimerButton = PhtimerModel.scope(
      (_, __, timerModel) => TimerControlButton(
        onPressed: () => timerModel.resetTimer(),
        icon: Icons.refresh,
        tooltip: PfsLocalization.buttonTooltip(
          commandName: 'Restart timer',
          shortcut: Phshortcuts.restartTimer,
        ),
      ),
    );

    final previousButton = PfsAppModel.scope(
      (_, __, model) => Phbuttons.nextPreviousOnScrollListener(
        model: model,
        child: TimerControlButton(
          onPressed: () => model.previousImageNewTimer(),
          icon: Icons.skip_previous,
          tooltip: PfsLocalization.buttonTooltip(
            commandName: 'Previous Image',
            shortcut: Phshortcuts.previous2,
          ),
        ),
      ),
    );

    final nextButton = PfsAppModel.scope(
      (_, __, model) => Phbuttons.nextPreviousOnScrollListener(
        model: model,
        child: TimerControlButton(
          onPressed: () => model.nextImageNewTimer(),
          icon: Icons.skip_next,
          tooltip: PfsLocalization.buttonTooltip(
            commandName: 'Next Image',
            shortcut: Phshortcuts.next2,
          ),
        ),
      ),
    );

    // LAYOUT
    return Column(
      children: [
        const TimerBar(key: TimerBar.mainScreenKey),
        Container(
          height: 40,
          padding: const EdgeInsets.only(top: 1),
          margin: const EdgeInsets.only(bottom: 2),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 2,
            children: [
              restartTimerButton,
              previousButton,
              PlayPauseTimerButton(iconProgress: playPauseIconController),
              nextButton,
            ],
          ),
        )
      ],
    );
  }
}

class TimerBar extends StatelessWidget {
  const TimerBar({super.key});
  static const Key mainScreenKey = Key('mainScreenTimerBar');

  static const double almostZeroThreshold = 0.1;
  static const double barWidth = 200;

  @override
  Widget build(BuildContext context) {
    final timerTheme = Theme.of(context).extension<PhtimerTheme>() ??
        PhtimerTheme.defaultTheme;

    return SizedBox(
      width: TimerBar.barWidth,
      height: 2,
      child: PhtimerModel.scope(
        (_, __, timerModel) {
          final barValueFromModel = (1.0 - timerModel.progressPercent);
          Color barColor = timerModel.isRunning
              ? (barValueFromModel < TimerBar.almostZeroThreshold
                  ? timerTheme.almostZeroColor
                  : timerTheme.runningColor)
              : timerTheme.pausedColor;

          return TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutQuart,
            tween: Tween<double>(begin: 0, end: barValueFromModel),
            builder: (_, value, __) {
              return LinearProgressIndicator(
                backgroundColor: timerTheme.barBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
                value: value,
              );
            },
          );
        },
      ),
    );
  }
}

class PlayPauseTimerButton extends StatelessWidget {
  const PlayPauseTimerButton({super.key, required this.iconProgress});

  final Animation<double> iconProgress;

  @override
  Widget build(BuildContext context) {
    final timerTheme = Theme.of(context).extension<PhtimerTheme>() ??
        PhtimerTheme.defaultTheme;

    final shortcutLabel =
        PfsLocalization.tooltipShortcut(Phshortcuts.playPause);
    final pressLabel = PfsLocalization.pressCapital;

    return PfsAppModel.scope((_, __, model) {
      return PhtimerModel.scope((_, __, timerModel) {
        final playButtonTooltip =
            'Timer paused. $pressLabel to resume ($shortcutLabel)';
        final pauseButtonTooltip =
            'Timer running. $pressLabel to pause ($shortcutLabel)';
        final icon = AnimatedIcon(
          icon: AnimatedIcons.play_pause,
          progress: iconProgress,
        );

        bool allowTimerControl = model.allowTimerPlayPause;
        Color buttonColor = allowTimerControl
            ? (timerModel.isRunning
                ? timerTheme.runningButton
                : timerTheme.pausedButton)
            : timerTheme.disabledColor;

        final style = ButtonStyle(
          animationDuration: const Duration(milliseconds: 300),
          backgroundColor:
              WidgetStateProperty.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.hovered)) {
              return buttonColor.withValues(alpha: 1.0);
            }
            return buttonColor;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          elevation: const WidgetStatePropertyAll(0),
        );

        final tooltipText =
            timerModel.isRunning ? pauseButtonTooltip : playButtonTooltip;

        return Tooltip(
          message: tooltipText,
          child: FilledButton(
            style: style,
            onPressed: () => model.tryTogglePlayPauseTimer(),
            child: Container(
              alignment: Alignment.center,
              width: 50,
              child: icon,
            ),
          ),
        );
      });
    });
  }
}

class TimerControlButton extends StatelessWidget {
  const TimerControlButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.tooltip,
  });

  final Function()? onPressed;
  final IconData icon;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
    );
  }
}

class PhtimerTheme extends ThemeExtension<PhtimerTheme> {
  const PhtimerTheme({
    required this.pausedColor,
    required this.runningColor,
    required this.almostZeroColor,
    required this.disabledColor,
    required this.barBackgroundColor,
    required this.pausedButton,
    required this.runningButton,
  });

  static const defaultTheme = PhtimerTheme(
    pausedColor: Colors.orange,
    runningColor: Colors.blue,
    almostZeroColor: Colors.red,
    disabledColor: Color(0xFF9E9E9E),
    barBackgroundColor: Colors.black12,
    pausedButton: Colors.orange,
    runningButton: Colors.blue,
  );

  @override
  ThemeExtension<PhtimerTheme> copyWith({
    Color? pausedColor,
    Color? runningColor,
    Color? almostZeroColor,
    Color? disabledColor,
    Color? barBackgroundColor,
    Color? pausedButton,
    Color? runningButton,
  }) {
    return PhtimerTheme(
      pausedColor: pausedColor ?? this.pausedColor,
      runningColor: runningColor ?? this.runningColor,
      almostZeroColor: almostZeroColor ?? this.almostZeroColor,
      disabledColor: disabledColor ?? this.disabledColor,
      barBackgroundColor: barBackgroundColor ?? this.barBackgroundColor,
      pausedButton: pausedButton ?? this.pausedButton,
      runningButton: runningButton ?? this.runningButton,
    );
  }

  @override
  ThemeExtension<PhtimerTheme> lerp(
      covariant ThemeExtension<PhtimerTheme>? other, double t) {
    if (other is! PhtimerTheme) {
      return this;
    }

    return PhtimerTheme(
      pausedColor: Color.lerp(pausedColor, other.pausedColor, t)!,
      runningColor: Color.lerp(runningColor, other.runningColor, t)!,
      almostZeroColor: Color.lerp(almostZeroColor, other.almostZeroColor, t)!,
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t)!,
      barBackgroundColor:
          Color.lerp(barBackgroundColor, other.barBackgroundColor, t)!,
      pausedButton: Color.lerp(pausedButton, other.pausedButton, t)!,
      runningButton: Color.lerp(runningButton, other.runningButton, t)!,
    );
  }

  final Color pausedColor;
  final Color runningColor;
  final Color almostZeroColor;
  final Color disabledColor;
  final Color barBackgroundColor;
  final Color pausedButton;
  final Color runningButton;
}
