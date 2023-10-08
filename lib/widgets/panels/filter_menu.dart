import 'package:flutter/material.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class FilterMenu extends StatelessWidget {
  const FilterMenu(
      {super.key, required this.imagePhviewer, required this.onDismiss});

  final ImagePhviewer imagePhviewer;
  final Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    const decoration = BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(10)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 2)]);
    const padding = EdgeInsets.symmetric(horizontal: 25, vertical: 15);

    const heading = Row(
      children: [
        Icon(Icons.invert_colors, color: Color(0xFFE4E4E4), size: 14),
        SizedBox(width: 7),
        Text(
          'Filters',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );

    return Stack(
      children: [
        ModalUnderlay(
          isTransparent: true,
          onTapDown:
              onDismiss, //onTapDown: () => setState(() => isShowingFiltersMenu = false),
        ),
        Positioned(
          bottom: 10,
          right: 280,
          child: SizedBox(
            child: Container(
              decoration: decoration,
              child: Padding(
                padding: padding,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Row(
                          children: [
                            heading,
                            const Expanded(child: Text('')),
                            IconButton(
                                tooltip: 'Reset all filters',
                                onPressed: imagePhviewer.isFilterActive
                                    ? () => imagePhviewer.resetAllFilters()
                                    : null,
                                icon: const Icon(Icons.format_color_reset)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      ColorModeButtons(
                        imagePhviewer: imagePhviewer,
                        onSelectionChanged: (Set<ImageColorMode> newSelection) {
                          final isSelectionGrayscale =
                              newSelection.contains(ImageColorMode.grayscale);
                          imagePhviewer
                              .setGrayscaleActive(isSelectionGrayscale);
                        },
                      ),
                      BlurSlider(
                        imagePhviewer: imagePhviewer,
                        onChanged: (value) {
                          imagePhviewer.setBlurLevel(value);
                        },
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ColorModeButtons extends StatelessWidget {
  const ColorModeButtons(
      {super.key,
      required this.imagePhviewer,
      required this.onSelectionChanged});

  final ImagePhviewer imagePhviewer;
  final Function(Set<ImageColorMode> newSelection) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: SegmentedButton<ImageColorMode>(
        emptySelectionAllowed: false,
        multiSelectionEnabled: false,
        style: const ButtonStyle(visualDensity: VisualDensity.compact),
        segments: const [
          ButtonSegment<ImageColorMode>(
              value: ImageColorMode.color,
              label: Text('Color'),
              icon: Icon(Icons.color_lens)),
          ButtonSegment<ImageColorMode>(
              value: ImageColorMode.grayscale,
              label: Text('Grayscale'),
              icon: Icon(Icons.invert_colors)),
        ],
        selected: imagePhviewer.isUsingGrayscale
            ? {ImageColorMode.grayscale}
            : {ImageColorMode.color},
        onSelectionChanged: (Set<ImageColorMode> newSelection) {
          onSelectionChanged(newSelection);
        },
      ),
    );
  }
}

class BlurSlider extends StatelessWidget {
  const BlurSlider(
      {super.key, required this.imagePhviewer, required this.onChanged});

  final ImagePhviewer imagePhviewer;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Blur'),
        Slider.adaptive(
          min: 0,
          max: 12,
          divisions: 12,
          label: imagePhviewer.blurLevel.toInt().toString(),
          onChanged: (value) {
            onChanged(value);
          },
          value: imagePhviewer.blurLevel,
        ),
      ],
    );
  }
}
