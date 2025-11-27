import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

class InitialUseChoiceSheet extends StatelessWidget {
  const InitialUseChoiceSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final model = PfsAppModel.of(context);

    final imageCount = model.circulator.count;
    const padding = EdgeInsets.symmetric(vertical: 10, horizontal: 20);

    final panelMaterial = PfsAppTheme.boxPanelFrom(Theme.of(context));

    void onChoseAnything() {
      model.isInitialUseChoiceChosen.value = true;
      model.tryStartSession();
    }

    void chooseTimerSession() {
      model.isUserChoseToStartTimer = true;
      onChoseAnything();
    }

    void chooseBrowseSession() {
      model.isUserChoseToStartTimer = false;
      onChoseAnything();
    }

    return Center(
      child: SizedBox(
        width: 350,
        height: 320,
        child: panelMaterial(
          child: Padding(
            padding: padding,
            child: RepaintBoundary(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 20),
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
                  modeChoiceButton(
                    text: "Start timer",
                    icon: Icon(Icons.timer),
                    //color: playColor,
                    onPressed: () => chooseTimerSession(),
                  ),
                  modeChoiceButton(
                    text: "Just browse",
                    icon: Icon(Icons.folder),
                    //color: pausedColor,
                    onPressed: () => chooseBrowseSession(),
                  ),
                  SizedBox(width: 10, height: 22),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget modeChoiceButton({
    String text = "",
    Widget? icon,
    VoidCallback? onPressed,
    Color? color,
  }) {
    final buttonStyle = OutlinedButton.styleFrom(
      minimumSize: Size(200, 70),
      //foregroundColor: color,
    );

    final button = FilledButton.tonalIcon(
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
