import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/image_phviewer.dart';
import 'package:pfs2/widgets/modal_underlay.dart';

class FilterMenu extends StatelessWidget {
  const FilterMenu(
      {super.key, required this.imagePhviewer, required this.onDismiss});

  final ImagePhviewer imagePhviewer;
  final Function()? onDismiss;

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.only(
      left: 22,
      right: 25,
      top: 15,
      bottom: 15,
    );

    // PARTS
    const heading = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 7,
      children: [
        Icon(
          Icons.invert_colors,
          color: PfsTheme.subtleHeadingIconColor,
          size: PfsTheme.subtleHeadingIconSize,
        ),
        Text(
          'Filters',
          style: PfsTheme.subtleHeadingStyle,
        ),
      ],
    );

    final resetAllFiltersButton = IconButton(
      tooltip: 'Reset all filters',
      color: Theme.of(context).colorScheme.tertiary,
      onPressed: imagePhviewer.isFilterActive
          ? () => imagePhviewer.resetAllFilters()
          : null,
      icon: const Icon(Icons.format_color_reset),
    );

    
    // HANDLERS
    void handleImageModeSelectionChanged(Set<ImageColorMode> newSelection) {
      final isSelectionGrayscale =
          newSelection.contains(ImageColorMode.grayscale);
      imagePhviewer.setGrayscaleActive(isSelectionGrayscale);
    }

    void handleBlurSliderChanged(value) {
      imagePhviewer.setBlurLevel(value);
    }


    // HIERARCHY
    return Stack(
      children: [
        ModalUnderlay(
          isTransparent: true,
          onDismiss: onDismiss,
        ),
        Positioned(
          bottom: 10,
          right: 280,
          child: Animate(
            effects: Phanimations.bottomMenuEffects,
            child: SizedBox(
              child: Container(
                decoration: PfsTheme.popupPanelBoxDecoration,
                child: Padding(
                  padding: padding,
                  child: Wrap(
                    direction: Axis.vertical,
                    spacing: 5,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Row(
                          children: [
                            heading,
                            const Spacer(),
                            resetAllFiltersButton,
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ColorModeButtons(
                        imagePhviewer: imagePhviewer,
                        onSelectionChanged: handleImageModeSelectionChanged,
                      ),
                      BlurSlider(
                        imagePhviewer: imagePhviewer,
                        onChanged: handleBlurSliderChanged,
                      ),
                    ],
                  ),
                ),
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
        SizedBox(
          width: 220,
          child: Slider.adaptive(
            min: 0,
            max: 12,
            divisions: 12,
            label: imagePhviewer.blurLevel.toInt().toString(),
            onChanged: onChanged,
            value: imagePhviewer.blurLevel,
          ),
        ),
      ],
    );
  }
}
