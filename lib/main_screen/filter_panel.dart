import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/widgets/scroll_listener.dart';

class FilterPanel extends StatelessWidget {
  const FilterPanel({
    super.key,
    required this.imagePhviewer,
  });

  final ImagePhviewer imagePhviewer;

  @override
  Widget build(BuildContext context) {
    return _container(
      context,
      content: Wrap(
        direction: Axis.vertical,
        spacing: 5,
        children: [
          _headerRow(
            children: [
              const FilterPanelHeading(),
              const Spacer(),
              ResetAllFiltersButton(imagePhviewer: imagePhviewer),
            ],
          ),
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
    );
  }

  void handleImageModeSelectionChanged(Set<ImageColorMode> newSelection) {
    final isSelectionGrayscale =
        newSelection.contains(ImageColorMode.grayscale);
    imagePhviewer.isUsingGrayscale = isSelectionGrayscale;
  }

  void handleBlurSliderChanged(value) {
    imagePhviewer.blurLevel = value;
  }

  Widget _headerRow({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        width: 250,
        child: Row(
          children: children,
        ),
      ),
    );
  }

  Widget _container(BuildContext context, {required Widget content}) {
    const panelPadding = EdgeInsets.only(
      left: 22,
      right: 25,
      top: 15,
      bottom: 15,
    );

    final windowSize = MediaQuery.of(context).size;

    const double widestNarrowWidth = 600;
    const double narrowestNarrowWidth = 450;
    const double rightMarginNormal = 280;
    const double squeezeOffset = 5;
    const double rightMarginNarrow = rightMarginNormal -
        (widestNarrowWidth - narrowestNarrowWidth) +
        squeezeOffset;

    final double rightOffset = Phbuttons.squeezeRemap(
      inputValue: windowSize.width,
      iMin: narrowestNarrowWidth,
      iThreshold: widestNarrowWidth,
      oMin: rightMarginNarrow,
      oRegular: rightMarginNormal,
    );

    final panelMaterial = PfsAppTheme.boxPanelFrom(Theme.of(context));

    return Stack(
      children: [
        Positioned(
          bottom: 10,
          right: rightOffset,
          child: panelMaterial(
            child: Padding(
              padding: panelPadding,
              child: content,
            ),
          ).animate(effects: const [Phanimations.growBottomEffect]),
        ),
      ],
    );
  }
}

class ColorModeButtons extends StatelessWidget {
  const ColorModeButtons({
    super.key,
    required this.imagePhviewer,
    required this.onSelectionChanged,
  });

  final ImagePhviewer imagePhviewer;
  final Function(Set<ImageColorMode> newSelection) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imagePhviewer.filtersChangeListenable,
      builder: (_, __, ___) {
        return buttons(context, imagePhviewer);
      },
    );
  }

  Widget buttons(BuildContext context, ImagePhviewer imagePhviewer) {
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
            ? const {ImageColorMode.grayscale}
            : const {ImageColorMode.color},
        onSelectionChanged: (Set<ImageColorMode> newSelection) {
          onSelectionChanged(newSelection);
        },
      ),
    );
  }
}

class BlurSlider extends StatelessWidget {
  const BlurSlider({
    super.key,
    required this.imagePhviewer,
    required this.onChanged,
  });

  final ImagePhviewer imagePhviewer;
  final Function(double) onChanged;

  @override
  Widget build(BuildContext context) {
    final label = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        'Blur',
        style: Theme.of(context).textTheme.labelLarge,
      ),
    );

    return ValueListenableBuilder(
      valueListenable: imagePhviewer.blurLevelListenable,
      builder: (_, __, ___) {
        return ScrollListener(
          onScrollUp: () => imagePhviewer.incrementBlurLevel(1),
          onScrollDown: () => imagePhviewer.incrementBlurLevel(-1),
          child: Row(
            children: [
              label,
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
          ),
        );
      },
    );
  }
}

class FilterPanelHeading extends StatelessWidget {
  const FilterPanelHeading({super.key});

  @override
  Widget build(BuildContext context) {
    final headingIcon = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Icon(
        Icons.invert_colors,
        size: 18,
        color: Theme.of(context).colorScheme.outline,
      ),
    );

    final heading = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      children: [
        headingIcon,
        Text(
          'Filters',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );

    return heading;
  }
}

class ResetAllFiltersButton extends StatelessWidget {
  const ResetAllFiltersButton({
    super.key,
    required this.imagePhviewer,
  });

  final ImagePhviewer imagePhviewer;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imagePhviewer.filtersChangeListenable,
      builder: (_, __, ___) => IconButton(
        tooltip: 'Reset all filters',
        color: Theme.of(context).colorScheme.tertiary,
        onPressed: imagePhviewer.isFilterActive
            ? () => imagePhviewer.resetAllFilters()
            : null,
        icon: const Icon(Icons.format_color_reset),
      ),
    );
  }
}
