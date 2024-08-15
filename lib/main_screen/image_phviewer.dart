import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_data.dart' as file_data;
import 'package:pfs2/core/file_data.dart' show FileData;
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/phlutter/material_state_property_utils.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/utils/values_notifier.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';

/// Contains image viewer functionality such as managing zooming, panning and applying filters to the image.
class ImagePhviewer with ImageZoomPanner, ImageFilters {
  ImagePhviewer();

  static final imageWidgetKey = GlobalKey();

  @override
  Size getImageSize() {
    return imageWidgetKey.currentContext?.size ?? Size.zero;
  }

  Widget widget(ValueListenable<bool> isBottomBarMinimized) {
    return ImageViewerStackWidget(
      panDurationListenable: panDurationListenable,
      isBottomBarMinimized: isBottomBarMinimized,
      offsetListenable: offsetListenable,
      blurLevelListenable: blurLevelListenable,
      usingGrayscaleListenable: usingGrayscaleListenable,
      zoomLevelListenable: zoomLevelListenable,
      getCurrentZoomScale: () => currentZoomScale,
      revealInExplorerHandler: file_data.revealInExplorer,
    );
  }
}

mixin ImageFilters {
  static const double _minBlurLevel = 0;
  static const double _maxBlurLevel = 12;
  final blurLevelListenable = ValueNotifier<double>(0.0);
  double get blurLevel => blurLevelListenable.value;
  set blurLevel(double val) => blurLevelListenable.value =
      clampDouble(val, _minBlurLevel, _maxBlurLevel);

  bool get isUsingGrayscale => usingGrayscaleListenable.value;
  set isUsingGrayscale(bool value) => usingGrayscaleListenable.value = value;
  final usingGrayscaleListenable = ValueNotifier<bool>(false);

  late final filtersChangeListenable = ValuesNotifier([
    blurLevelListenable,
    usingGrayscaleListenable,
  ]);

  bool get isFilterActive =>
      (isUsingGrayscale || blurLevelListenable.value > 0);

  int get activeFilterCount {
    int currentActiveFiltersCount = 0;
    if (blurLevelListenable.value > 0) currentActiveFiltersCount++;
    if (isUsingGrayscale) currentActiveFiltersCount++;

    return currentActiveFiltersCount;
  }

  void resetAllFilters() {
    isUsingGrayscale = false;
    blurLevel = 0;
  }

  void incrementBlurLevel(int increment) {
    if (increment > 0) {
      blurLevel += 1;
    } else if (increment < 0) {
      blurLevel -= 1;
    }
  }
}

mixin ImageZoomPanner {
  static const List<double> _zoomScales = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0
  ];
  static const _defaultZoomLevel = 3;

  final zoomLevelListenable = ValueNotifier<int>(_defaultZoomLevel);
  double get currentZoomScale => _zoomScales[zoomLevelListenable.value];
  int get currentZoomScalePercent => (currentZoomScale * 100).toInt();
  bool get isZoomLevelDefault =>
      (zoomLevelListenable.value == _defaultZoomLevel);
  bool get isZoomedIn => currentZoomScale > 1;

  final offsetListenable = ValueNotifier<Offset>(Offset.zero);
  Offset get panOffset => offsetListenable.value;
  final panDurationListenable =
      ValueNotifier<Duration>(Phanimations.zoomTransitionDuration);

  void incrementZoomLevel(int increment) {
    final previousZoomLevel = zoomLevelListenable.value;
    final newZoomLevel =
        (previousZoomLevel + increment).clamp(0, _zoomScales.length - 1);

    if (newZoomLevel != previousZoomLevel) {
      final newZoomScale = _zoomScales[newZoomLevel];
      final previousZoomScale = _zoomScales[previousZoomLevel];
      _scalePanOffset(previousZoomScale, newZoomScale);
    }

    if (newZoomLevel <= _defaultZoomLevel) {
      resetOffset();
    } else if (increment < 1) {
      offsetListenable.value *= 0.75;
    }

    zoomLevelListenable.value = newZoomLevel;
  }

  void _resetZoomLevel() {
    zoomLevelListenable.value = _defaultZoomLevel;
  }

  void resetOffset() {
    offsetListenable.value = Offset.zero;
  }

  void resetTransform() {
    panRelease();
    _resetZoomLevel();
    resetOffset();
  }

  void _scalePanOffset(double previousZoomScale, double newZoomScale) {
    final scaleDifference = newZoomScale / previousZoomScale;
    var newOffsetValue = offsetListenable.value * scaleDifference;
    _setPanOffsetClamped(newOffsetValue);
  }

  void panImage(Offset delta) {
    var newOffsetValue = offsetListenable.value + delta;
    panDurationListenable.value = Phanimations.userPanDuration;
    _setPanOffsetClamped(newOffsetValue);
  }

  void panRelease() {
    panDurationListenable.value = Phanimations.zoomTransitionDuration;
  }

  Size getImageSize();

  void _setPanOffsetClamped(Offset newOffset) {
    Offset clampPanOffset(Offset offset) {
      final imageSize = getImageSize();
      final scaledSize = imageSize * currentZoomScale;

      final xMax = scaledSize.width * 0.5;
      final yMax = scaledSize.height * 0.5;
      var dx = clampDouble(offset.dx, -xMax, xMax);
      var dy = clampDouble(offset.dy, -yMax, yMax);

      return Offset(dx, dy);
    }

    offsetListenable.value = clampPanOffset(newOffset);
  }
}

enum ImageColorMode { color, grayscale }

class ImageClickableLabel extends StatelessWidget {
  const ImageClickableLabel({
    super.key,
    required this.label,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final String? tooltip;
  final Function()? onTap;

  static const double fontSize = 11;
  static const padding = EdgeInsets.symmetric(vertical: 0, horizontal: 14);
  static const Size minSize = Size(280, 36);
  static const Size maxSize = Size(380, 50);

  static final textMaterialStyles = hoverProperty(
    idle: const TextStyle(
      decoration: TextDecoration.none,
      fontSize: fontSize,
      overflow: TextOverflow.ellipsis,
    ),
    hover: const TextStyle(
      decoration: TextDecoration.underline,
      fontSize: fontSize,
      overflow: TextOverflow.ellipsis,
    ),
  );

  @override
  Widget build(BuildContext context) {
    Color buttonHoverBackground = Theme.of(context).scaffoldBackgroundColor;
    final buttonMaterialColors = hoverColors(
      idle: buttonHoverBackground.withAlpha(0x00),
      hover: buttonHoverBackground,
    );

    final textMaterialColors = hoverColors(
      idle: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(0x6C),
      hover: PfsTheme.hyperlinkColorHovered,
    );

    final ButtonStyle style = ButtonStyle(
      minimumSize: const MaterialStatePropertyAll(minSize),
      maximumSize: const MaterialStatePropertyAll(maxSize),
      padding: const MaterialStatePropertyAll(padding),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
      textStyle: textMaterialStyles,
      backgroundColor: buttonMaterialColors,
      foregroundColor: textMaterialColors,
    );

    return Tooltip(
      message: tooltip,
      preferBelow: true,
      child: TextButton(style: style, onPressed: onTap, child: Text(label)),
    );
  }
}

typedef ClipboardCopyTextHandler = void Function(
    {required String newClipboardText, String? toastMessage});

class ImageRightClick extends StatelessWidget {
  const ImageRightClick({
    super.key,
    required this.child,
    this.clipboardCopyHandler,
    required this.resetZoomLevelHandler,
    required this.revealInExplorerHandler,
    required this.copyImageHandler,
  });

  final Widget child;
  final ClipboardCopyTextHandler? clipboardCopyHandler;
  final VoidCallback resetZoomLevelHandler;
  final VoidCallback revealInExplorerHandler;
  final VoidCallback copyImageHandler;

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      void handleCopyFilePath() {
        clipboardCopyHandler?.call(
          newClipboardText: model.getCurrentImageFileData().filePath,
          toastMessage: 'File path copied to clipboard.',
        );
      }

      final copyImageItem = MenuItem(
        label: PfsLocalization.copyImageToClipboard,
        onClick: (menuItem) => copyImageHandler(),
      );

      final copyFilePathItem = MenuItem(
        label: PfsLocalization.copyFilePath,
        onClick: (menuItem) => handleCopyFilePath(),
      );

      final revealInExplorerItem = MenuItem(
        label: PfsLocalization.revealInExplorer,
        onClick: (menuItem) => revealInExplorerHandler(),
      );

      final contextMenu = Menu(
        items: [
          copyImageItem,
          copyFilePathItem,
          MenuItem.separator(),
          revealInExplorerItem,
        ],
      );

      void openContextMenu() {
        popUpContextualMenu(contextMenu);
      }

      return GestureDetector(
        onTertiaryTapDown: (details) => resetZoomLevelHandler(),
        onSecondaryTapDown: (details) => openContextMenu(),
        child: child,
      );
    });
  }
}

class ImageViewerStackWidget extends StatelessWidget {
  const ImageViewerStackWidget({
    super.key,
    required this.isBottomBarMinimized,
    required this.zoomLevelListenable,
    required this.blurLevelListenable,
    required this.usingGrayscaleListenable,
    required this.getCurrentZoomScale,
    required this.revealInExplorerHandler,
    required this.offsetListenable,
    required this.panDurationListenable,
  });

  final ValueNotifier<Duration> panDurationListenable;
  final ValueListenable<bool> isBottomBarMinimized;
  final ValueListenable<Offset> offsetListenable;
  final ValueNotifier<int> zoomLevelListenable;
  final ValueNotifier<double> blurLevelListenable;
  final ValueNotifier<bool> usingGrayscaleListenable;
  final double Function() getCurrentZoomScale;
  final Function(FileData fileData) revealInExplorerHandler;

  @override
  Widget build(BuildContext context) {
    final content = PfsAppModel.scope((_, __, model) {
      const defaultImage = '';

      final FileData imageFileData = model.hasFilesLoaded
          ? model.getCurrentImageFileData()
          : file_data.fileDataFromPath(defaultImage);

      final File imageFile = File(imageFileData.filePath);
      final imageWidget = Image.file(
        filterQuality: FilterQuality.medium,
        key: ImagePhviewer.imageWidgetKey,
        imageFile,
      );

      final imageFilenameLayer = Align(
        heightFactor: 2,
        alignment: Alignment.topCenter,
        child: ImageClickableLabel(
          label: imageFileData.fileName,
          tooltip:
              "${PfsLocalization.revealInExplorer} : ${imageFileData.parentFolderName}",
          onTap: () => revealInExplorerHandler(imageFileData),
        ),
      );

      final isNextImageTransition = model.lastIncrement > 0;
      final currentImageIndexString = model.currentImageIndex.toString();
      final slideKeyString = model.isCountingDown
          ? 'countingDownImage'
          : 'i$currentImageIndexString';

      return Stack(
        children: [
          Animate(
            key: Key(slideKeyString),
            effects: isNextImageTransition
                ? Phanimations.imageNext
                : Phanimations.imagePrevious,
            child: SizedBox.expand(
              child: ValueListenableBuilder(
                  valueListenable: panDurationListenable,
                  builder: (_, panDuration, ___) {
                    return ListeningAnimatedTranslate(
                      offsetListenable: offsetListenable,
                      duration: panDuration,
                      child: ValueListenableBuilder(
                        valueListenable: zoomLevelListenable,
                        builder: (_, __, ___) {
                          return AnimatedScale(
                            duration: Phanimations.zoomTransitionDuration,
                            curve: Phanimations.zoomTransitionCurve,
                            scale: getCurrentZoomScale(),
                            child: imageWidget,
                          );
                        },
                      ),
                    );
                  }),
            ),
          ),
          ValueListenableBuilder(
            valueListenable: blurLevelListenable,
            builder: (_, blurValue, __) {
              if (blurValue <= 0) return const SizedBox.expand();
              final sigma = pow(1.3, blurValue).toDouble();
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
                child: const SizedBox.expand(),
              );
            },
          ),
          ValueListenableBuilder(
            valueListenable: usingGrayscaleListenable,
            builder: (_, value, ___) =>
                value ? grayscaleBackdropFilter : const SizedBox.expand(),
          ),
          imageFilenameLayer,
        ],
      );
    });

    return ValueListenableBuilder(
      valueListenable: isBottomBarMinimized,
      builder: (_, isMinimized, __) {
        const minimizedPadding = EdgeInsets.only(
          bottom: 5,
          top: Phbuttons.windowTitleBarHeight,
        );
        const normalPadding = EdgeInsets.only(
          bottom: 46,
          top: Phbuttons.windowTitleBarHeight,
        );

        final padding = isMinimized ? minimizedPadding : normalPadding;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          padding: padding,
          child: content,
        );
      },
    );
  }

  static const Widget grayscaleBackdropFilter = BackdropFilter(
    filter: ColorFilter.matrix(<double>[
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0.2126,
      0.7152,
      0.0722,
      0,
      0,
      0,
      0,
      0,
      1,
      0
    ]),
    child: SizedBox.expand(),
  );
}

class ListeningAnimatedTranslate extends StatelessWidget {
  const ListeningAnimatedTranslate({
    super.key,
    required this.offsetListenable,
    required this.child,
    required this.duration,
  });

  final ValueListenable<Offset> offsetListenable;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: offsetListenable,
      builder: (_, offset, __) {
        return AnimatedTranslate(
          curve: Phanimations.zoomTransitionCurve,
          duration: duration,
          offset: offset,
          child: child,
        );
      },
    );
  }
}

class AnimatedTranslate extends StatelessWidget {
  const AnimatedTranslate({
    super.key,
    required this.child,
    required this.offset,
    this.duration = const Duration(milliseconds: 150),
    this.curve = Curves.easeOutQuint,
  });

  final Widget child;
  final Offset offset;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      duration: duration,
      curve: curve,
      tween: Tween<Offset>(begin: Offset.zero, end: offset),
      builder: (_, animatedOffsetValue, __) {
        return Transform.translate(
          offset: animatedOffsetValue,
          child: child,
        );
      },
    );
  }
}

class ImagePhviewerPanListener extends StatelessWidget {
  const ImagePhviewerPanListener({
    super.key,
    required this.imagePhviewer,
    required this.child,
  });

  final ImagePhviewer imagePhviewer;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        if (!imagePhviewer.isZoomedIn) return;

        imagePhviewer.panImage(details.delta);
      },
      onPanEnd: (details) {
        if (!imagePhviewer.isZoomedIn) return;

        imagePhviewer.panRelease();
      },
      child: child,
    );
  }
}

class ImagePhviewerZoomOnScrollListener extends StatelessWidget {
  const ImagePhviewerZoomOnScrollListener({
    super.key,
    required this.child,
    required this.imagePhviewer,
  });

  final Widget child;
  final ImagePhviewer imagePhviewer;

  @override
  Widget build(BuildContext context) {
    return ScrollListener(
      onScrollDown: () => imagePhviewer.incrementZoomLevel(-1),
      onScrollUp: () => imagePhviewer.incrementZoomLevel(1),
      child: child,
    );
  }
}

class ResetZoomButton extends StatelessWidget {
  const ResetZoomButton({
    super.key,
    required this.imageZoomPanner,
  });

  final ImageZoomPanner imageZoomPanner;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: imageZoomPanner.zoomLevelListenable,
      builder: (_, __, ___) {
        return Visibility(
          visible: !imageZoomPanner.isZoomLevelDefault,
          child: IconButton(
            tooltip: 'Reset zoom',
            onPressed: () => imageZoomPanner.resetTransform(),
            icon: const Icon(Icons.youtube_searched_for),
          ),
        );
      },
    );
  }
}
