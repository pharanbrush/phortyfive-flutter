import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

class WelcomeChooseModeSheet extends StatelessWidget {
  const WelcomeChooseModeSheet({
    super.key,
    required this.model,
  });

  final PfsAppModel model;

  void _chooseTimerSession() {
    model.isUserChoseToStartTimer = true;
    _onChoseAnything();
  }

  void _chooseBrowseSession() {
    model.isUserChoseToStartTimer = false;
    _onChoseAnything();
  }

  void _onChoseAnything() {
    model.isWelcomeDone = true;
    model.tryStartSession();
  }

  @override
  Widget build(BuildContext context) {
    int imageCount = model.circulator.count;
    const padding = EdgeInsets.symmetric(vertical: 10, horizontal: 20);

    // final currentTheme = Theme.of(context).extension<PhtimerTheme>();
    // final playColor = currentTheme?.runningColor;
    // final pausedColor = currentTheme?.pausedColor;
    // final labelSmall = Theme.of(context).textTheme.labelSmall;

    final panelMaterial = PfsAppTheme.boxPanelFrom(Theme.of(context));

    return Center(
      child: SizedBox(
        width: 350,
        height: 320,
        child: panelMaterial(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(9.0),
                        child: Icon(Icons.image),
                      ),
                      Text(
                        textAlign: TextAlign.center,
                        "$imageCount ${PfsLocalization.imageNoun(imageCount)} loaded",
                      ),
                      SizedBox(width: 28, height: 28),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Center(
                    child: Text(
                      "How do you want to start this session?",
                      //style: labelSmall,
                    ),
                  ),
                ),
                welcomeChoiceButton(
                  text: "Start timer",
                  icon: Icon(Icons.timer),
                  //color: playColor,
                  onPressed: () => _chooseTimerSession(),
                ),
                welcomeChoiceButton(
                  text: "Just browse",
                  icon: Icon(Icons.folder),
                  //color: pausedColor,
                  onPressed: () => _chooseBrowseSession(),
                ),
                SizedBox(width: 10, height: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget welcomeChoiceButton({
    String text = "",
    Widget? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: Size(200, 70),
      //foregroundColor: color,
    );

    var button = FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: icon,
      style: buttonStyle,
      label: Text(text),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
      child: button,
    );
  }
}
