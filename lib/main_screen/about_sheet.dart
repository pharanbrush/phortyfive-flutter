import 'package:flutter/material.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phtext_widgets.dart';

class AboutSheet extends StatelessWidget {
  const AboutSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _container(
          context,
          child: _contents(context),
        )
      ],
    );
  }

  Widget _contents(BuildContext context) {
    final headingStyle = Theme.of(context).textTheme.titleMedium;

    const spacing = SizedBox(height: 10);
    const pharanBrushUrl = 'ko-fi.com/Pharanbrush';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: Image.memory(PfsTheme.pfsIconBytes),
        ),
        spacing,
        Text(
          'Phorty-Five Seconds by PharanBrush',
          style: headingStyle,
        ),
        const Text('Timed Image Viewer for Drawing Practice'),
        spacing,
        const Text('Build 0.6.20231021b'),
        const HyperlinkRichText(
          'For more info, visit: ',
          urlText: pharanBrushUrl,
          url: 'https://$pharanBrushUrl',
        ),
        const Spacer(),
        Align(
          alignment: Alignment.topRight,
          child: TextButton(
            onPressed: () {
              showLicensePage(context: context);
            },
            child: const Text('License info...'),
          ),
        ),
      ],
    );
  }

  Widget _container(
    BuildContext context, {
    required Widget child,
  }) {
    final panel = PfsAppTheme.boxPanelFrom(Theme.of(context));

    return Center(
      child: SizedBox(
        width: 370,
        height: 260,
        child: panel(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            child: child,
          ),
        ),
      ),
    );
  }
}
