import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/main_screen/image_phviewer.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';

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
        spacing: 2,
        children: [
          _headerRow(
            children: [
              const FilterPanelHeading(),
              Transform.translate(
                offset: const Offset(0, 1),
                child: ResetFiltersSwitch(filters: imagePhviewer),
              ),
              const Spacer(),
            ],
          ),
          SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ColorModeButtons(
              filters: imagePhviewer,
              onSelectionChanged: handleImageModeSelectionChanged,
            ),
          ),
          BlurSlider(filters: imagePhviewer),
          FlipControls(zoomPanner: imagePhviewer),
        ],
      ),
    );
  }

  void handleImageModeSelectionChanged(Set<ImageColorMode> newSelection) {
    final isSelectionGrayscale =
        newSelection.contains(ImageColorMode.grayscale);
    imagePhviewer.isUsingGrayscale = isSelectionGrayscale;
  }

  Widget _headerRow({required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        width: 250,
        child: Row(children: children),
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

    final windowSize = MediaQuery.sizeOf(context);

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

class FlipControls extends StatelessWidget {
  const FlipControls({
    super.key,
    required this.zoomPanner,
  });

  final ImageZoomPanner zoomPanner;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: zoomPanner.flipHorizontalListenable,
      builder: (_, isFlippedHorizontal, ___) {
        final labelStyle = Theme.of(context).textTheme.labelMedium;

        return Row(
          spacing: 8,
          children: [
            Text("Flip", style: labelStyle),
            IconButton.filled(
              onPressed: () => zoomPanner.flipHorizontal(),
              icon: Icon(
                FluentIcons.flip_horizontal_16_regular,
                size: 18,
              ),
              isSelected: isFlippedHorizontal,
              tooltip: "Flip view horizontally (H)",
            ),
          ],
        );
      },
    );
  }
}

enum ImageColorMode { color, grayscale }

class ColorModeButtons extends StatelessWidget {
  const ColorModeButtons({
    super.key,
    required this.filters,
    required this.onSelectionChanged,
  });

  final ImageFilters filters;
  final Function(Set<ImageColorMode> newSelection) onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: filters.filtersChangeListenable,
      builder: (_, __, ___) {
        return buttons();
      },
    );
  }

  Widget buttons() {
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
        selected: filters.isUsingGrayscale
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
    required this.filters,
  });

  final ImageFilters filters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelMedium;

    final label = Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text("Blur", style: labelStyle),
    );

    return ValueListenableBuilder(
      valueListenable: filters.blurLevelListenable,
      builder: (_, __, ___) {
        return ScrollListener(
          onScrollUp: () => filters.incrementBlurLevel(1),
          onScrollDown: () => filters.incrementBlurLevel(-1),
          child: Row(
            children: [
              label,
              SizedBox(
                width: 220,
                height: 40,
                child: SliderTheme(
                  data: theme.sliderTheme.copyWith(
                    trackHeight: 3,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    min: 0,
                    max: 12,
                    divisions: 12,
                    label: filters.blurLevel.toInt().toString(),
                    onChanged: (newValue) => filters.blurLevel = newValue,
                    value: filters.blurLevel,
                  ),
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
          "Filters",
          style: Theme.of(context)
              .textTheme
              .labelLarge
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    );

    return heading;
  }
}

class ResetFiltersSwitch extends StatelessWidget {
  const ResetFiltersSwitch({
    super.key,
    required this.filters,
  });

  final ImageFilters filters;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsGeometry.symmetric(horizontal: 8),
      child: ValueListenableBuilder(
        valueListenable: filters.filtersChangeListenable,
        builder: (_, __, ___) {
          final isSomeFiltersAreOn = filters.isFilterActive;

          void toggleFilters(bool newValue) {
            if (isSomeFiltersAreOn) {
              filters.storeLastSettings();
              filters.resetAllFilters();
            } else {
              filters.restoreLastSettings();
            }
          }

          return Tooltip(
            message: "Reset all filters",
            child: Phswitch(
              height: 20,
              value: filters.isFilterActive,
              onChanged: (isSomeFiltersAreOn || filters.lastSettings != null)
                  ? toggleFilters
                  : null,
            ),
          );
        },
      ),
    );
  }
}
