import 'package:flutter/material.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class HelpSheet extends StatelessWidget {
  static const Color textColor = Color(0xFFEEEEEE);
  static const Color sheetColor = Color(0xEE000000);
  static const double sheetHeight = 500;

  static const Icon headingIcon = Icon(
    Icons.keyboard,
    color: textColor,
    size: 40,
  );

  static const TextStyle headingStyle = TextStyle(
    color: textColor,
    fontWeight: FontWeight.bold,
    fontSize: 30,
  );

  static const BoxDecoration sheetDecoration = BoxDecoration(
    color: sheetColor,
    borderRadius: BorderRadius.all(Radius.circular(20)),
  );

  const HelpSheet({super.key, this.onTapUnderlay});
  final Function()? onTapUnderlay;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.center,
      children: [
        ModalUnderlay(onTapDown: onTapUnderlay),
        Center(
          child: Material(
            color: Colors.transparent,
            textStyle: const TextStyle(color: textColor, inherit: true),
            child: Container(
              height: sheetHeight,
              decoration: sheetDecoration,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 100,
                    child: Column(
                      children: [
                        headingIcon,
                        Text('Keyboard Shortcuts', style: headingStyle)
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 720,
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  _shortcutItem('Open images...', 'O',
                                      modifier: 'Ctrl'),
                                  const Text(''),
                                  _shortcutItem('Next image', 'J'),
                                  _shortcutItem('Previous image', 'K'),
                                  const Text(''),
                                  _shortcutItem('Play/Pause', 'P'),
                                  _shortcutItem('Restart timer', 'R'),
                                  _shortcutItem('Change timer duration', 'F2'),
                                ]),
                          ),
                        ),
                        Expanded(
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _shortcutItem('Toggle "Always on top"', 'T',
                                    modifier: 'Ctrl'),
                                _shortcutItem('Show/hide bottom bar', 'H'),
                                _shortcutItem('Open help sheet', 'F1'),
                                _shortcutItem('Mute/unmute sounds', 'M'),
                              ]),
                        )
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: SizedBox(
                        width: 600,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: Icon(
                                Icons.file_open_outlined,
                                color: textColor,
                                size: 30,
                              ),
                            ),
                            Text(
                                'You can also load new images using drag and drop.'),
                            Padding(
                              padding: EdgeInsets.all(20.0),
                              child: SizedBox(
                                width: 30,
                                height: 30,
                              ),
                            )
                          ],
                        )),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }

  Widget _shortcutItem(String text, String key, {String? modifier}) {
    const double textWidth = 160;
    const double keysWidth = 100;
    const double padding = 3;

    return Padding(
      padding: const EdgeInsets.all(padding),
      child: Row(
        children: [
          SizedBox(
            width: textWidth,
            child: Text(text),
          ),
          SizedBox(
            width: keysWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (modifier != null) _keySymbol(modifier),
                if (modifier != null) const Text(' + '),
                _keySymbol(key),                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _keySymbol(String key) {
    const double height = 32;
    const double minWidth = 32;
    const double verticalPadding = 3;
    const double horizontalPadding = 8;
    const double borderRadius = 5;
    const Color keyColor = Color(0xFF272727);

    return Container(
      constraints: const BoxConstraints(minWidth: minWidth, minHeight: height),
      padding: const EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: horizontalPadding,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        color: keyColor,
      ),
      child: Text(key),
    );
  }
}
