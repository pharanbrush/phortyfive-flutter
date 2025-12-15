import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/image_memory_data.dart';
import 'package:pfs2/core/image_data.dart' as image_data;
import 'package:pfs2/core/image_data.dart' show ImageData, ImageFileData;
import 'package:pfs2/main_screen/annotations_tool.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/phlutter/escape_route.dart';
import 'package:pfs2/phlutter/material_state_property_utils.dart';
import 'package:pfs2/phlutter/utils/open_in_browser.dart' as open_in_browser;
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/phlutter/values_notifier.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/libraries/annotation_overlay.dart';
import 'package:pfs2/widgets/clipboard_handlers.dart';
import 'package:pfs2/phlutter/scroll_listener.dart';

/// Contains image viewer functionality such as managing zooming, panning and applying filters to the image.
class ImagePhviewer with ImageZoomPanner, ImageFilters {
  ImagePhviewer();

  static final imageWidgetKey = GlobalKey();

  @override
  Size getImageSize() {
    return imageWidgetKey.currentContext?.size ?? Size.zero;
  }

  Widget widget(ValueListenable<double> bottomBarHeight) {
    return ImageViewerStackWidget(
      bottomBarHeight: bottomBarHeight,
      zoomPanner: this,
      filters: this,
      panDurationListenable: panDuration,
      revealInExplorerHandler: image_data.revealImageFileDataInExplorer,
    );
  }
}

mixin ImageFilters {
  static const double _minBlurLevel = 0;
  static const double _maxBlurLevel = 12;

  ({double blurLevel, bool isUsingGrayscale})? lastSettings;

  final blurLevelListenable = ValueNotifier<double>(0.0);
  double get blurLevel => blurLevelListenable.value;
  set blurLevel(double val) => blurLevelListenable.value =
      clampDouble(val, _minBlurLevel, _maxBlurLevel);

  final usingGrayscaleListenable = ValueNotifier<bool>(false);
  bool get isUsingGrayscale => usingGrayscaleListenable.value;
  set isUsingGrayscale(bool value) => usingGrayscaleListenable.value = value;

  late final filtersChangeListenable = ValuesNotifier([
    blurLevelListenable,
    usingGrayscaleListenable,
  ]);

  late final filterActiveChecks = [
    () => isUsingGrayscale,
    () => blurLevelListenable.value > 0,
  ];

  bool get isFilterActive => activeFilterCount > 0;

  int get activeFilterCount {
    int currentActiveFiltersCount = 0;

    for (final filterCheck in filterActiveChecks) {
      if (filterCheck()) currentActiveFiltersCount++;
    }

    return currentActiveFiltersCount;
  }

  void storeLastSettings() {
    lastSettings = (
      blurLevel: blurLevelListenable.value,
      isUsingGrayscale: usingGrayscaleListenable.value,
    );
  }

  void restoreLastSettings() {
    if (lastSettings == null) return;
    blurLevelListenable.value = lastSettings!.blurLevel;
    usingGrayscaleListenable.value = lastSettings!.isUsingGrayscale;
  }

  void incrementBlurLevel(int increment) {
    if (increment > 0) {
      blurLevel += 1;
    } else if (increment < 0) {
      blurLevel -= 1;
    }
  }

  void resetAllFilters() {
    isUsingGrayscale = false;
    blurLevel = 0;
  }

  ValueListenableBuilder<bool> grayscaleFilterLayer() {
    return ValueListenableBuilder(
      valueListenable: usingGrayscaleListenable,
      builder: (_, value, ___) =>
          value ? grayscaleBackdropFilter : const SizedBox.expand(),
    );
  }

  ValueListenableBuilder<double> blurFilterLayer() {
    return ValueListenableBuilder(
      valueListenable: blurLevelListenable,
      builder: (_, blurValue, __) {
        if (blurValue <= 0) return const SizedBox.expand();
        final sigma = pow(1.3, blurValue).toDouble();
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: const SizedBox.expand(),
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

mixin ImageZoomPanner {
  final flipHorizontalListenable = ValueNotifier<bool>(false);

  final zoomLevelListenable =
      ValueNotifier<int>(ImageZoomPanner._defaultZoomLevel);
  double get currentZoomScale =>
      ImageZoomPanner._zoomScales[zoomLevelListenable.value];
  int get currentZoomScalePercent => (currentZoomScale * 100).toInt();
  bool get isZoomLevelDefault =>
      (zoomLevelListenable.value == ImageZoomPanner._defaultZoomLevel);
  bool get isZoomedIn => currentZoomScale > 1;

  final offsetListenable = ValueNotifier<Offset>(Offset.zero);
  Offset get panOffset => offsetListenable.value;

  double zoomAccumulator = 0;

  final panDuration =
      ValueNotifier<Duration>(Phanimations.zoomTransitionDuration);

  static const List<double> _zoomScales = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0,
    8.0,
  ];
  static const _defaultZoomLevel = 3;

  void incrementZoomAccumulator(double dragIncrement) {
    const zoomSensitivity = 0.04;
    zoomAccumulator += dragIncrement * zoomSensitivity;

    if (zoomAccumulator > 1) {
      zoomAccumulator -= 1;
      incrementZoomLevel(1);
    } else if (zoomAccumulator < -1) {
      zoomAccumulator += 1;
      incrementZoomLevel(-1);
    }
  }

  void resetZoomAccumulator() {
    zoomAccumulator = 0;
  }

  void incrementZoomLevel(int increment) {
    final previousZoomLevel = zoomLevelListenable.value;
    final newZoomLevel = (previousZoomLevel + increment)
        .clamp(0, ImageZoomPanner._zoomScales.length - 1);

    if (newZoomLevel != previousZoomLevel) {
      final newZoomScale = ImageZoomPanner._zoomScales[newZoomLevel];
      final previousZoomScale = ImageZoomPanner._zoomScales[previousZoomLevel];
      _scalePanOffset(previousZoomScale, newZoomScale);
    }

    if (newZoomLevel <= ImageZoomPanner._defaultZoomLevel) {
      resetOffset();
    } else if (increment < 1) {
      offsetListenable.value *= 0.75;
    }

    zoomLevelListenable.value = newZoomLevel;
  }

  void _resetZoomLevel() {
    zoomLevelListenable.value = ImageZoomPanner._defaultZoomLevel;
  }

  void resetOffset() {
    offsetListenable.value = Offset.zero;
  }

  void resetTransform() {
    panRelease();
    _resetZoomLevel();
    resetOffset();
    resetFlip();
  }

  void resetFlip() {
    flipHorizontalListenable.value = false;
  }

  void flipHorizontal() {
    flipHorizontalListenable.value = !flipHorizontalListenable.value;
  }

  void _scalePanOffset(double previousZoomScale, double newZoomScale) {
    final scaleDifference = newZoomScale / previousZoomScale;
    final newOffsetValue = offsetListenable.value * scaleDifference;
    _setPanOffsetClamped(newOffsetValue);
  }

  void panImage(Offset delta) {
    final isFlippedHorizontal = flipHorizontalListenable.value;
    if (isFlippedHorizontal) {
      delta = delta.scale(-1, 1);
    }

    final newOffsetValue = offsetListenable.value + delta;
    panDuration.value = Phanimations.userPanDuration;
    _setPanOffsetClamped(newOffsetValue);
  }

  void panRelease() {
    panDuration.value = Phanimations.zoomTransitionDuration;
  }

  Size getImageSize();

  void _setPanOffsetClamped(Offset newOffset) {
    Offset clampPanOffset(Offset offset) {
      final imageSize = getImageSize();
      final scaledSize = imageSize * currentZoomScale;

      final xMax = scaledSize.width * 0.5;
      final yMax = scaledSize.height * 0.5;
      final dx = clampDouble(offset.dx, -xMax, xMax);
      final dy = clampDouble(offset.dy, -yMax, yMax);

      return Offset(dx, dy);
    }

    offsetListenable.value = clampPanOffset(newOffset);
  }
}

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
    final buttonHoverBackground = Theme.of(context).scaffoldBackgroundColor;
    final buttonMaterialColors = hoverColors(
      idle: buttonHoverBackground.withAlpha(0x00),
      hover: buttonHoverBackground,
    );

    final textMaterialColors = hoverColors(
      idle: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(0x6C),
      hover: PfsTheme.hyperlinkColorHovered,
    );

    final ButtonStyle style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(minSize),
      maximumSize: const WidgetStatePropertyAll(maxSize),
      padding: const WidgetStatePropertyAll(padding),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
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

class ImageRightClick extends StatelessWidget {
  const ImageRightClick({
    super.key,
    required this.child,
    required this.resetZoomLevelHandler,
    required this.revealInExplorerHandler,
  });

  final Widget child;
  final VoidCallback resetZoomLevelHandler;
  final VoidCallback revealInExplorerHandler;

  @override
  Widget build(BuildContext context) {
    final model = PfsAppModel.of(context);

    void handleCopyFilePath() {
      final currentImageData = model.getCurrentImageData();
      if (currentImageData is ImageFileData) {
        ClipboardHandlers.of(context)?.copyText(
          text: currentImageData.filePath,
          toastMessage: "File path copied to clipboard.",
        );
      }
    }

    void handleCopyFilename() {
      final currentImageData = model.getCurrentImageData();
      if (currentImageData is ImageFileData) {
        ClipboardHandlers.of(context)?.copyText(
          text: currentImageData.fileName,
          toastMessage: "Filename copied to clipboard.",
        );
      }
    }

    void handleCopyCurrentImage() {
      ClipboardHandlers.of(context)?.copyCurrentImage();
    }

    final imageData = model.getCurrentImageData();
    final isFile = imageData is ImageFileData;

    final copyImageItem = MenuItem(
      label: PfsLocalization.copyImageToClipboard,
      onClick: (menuItem) => handleCopyCurrentImage(),
      disabled: imageData is image_data.InvalidImageData,
    );

    final copyFilename = MenuItem(
      label: PfsLocalization.copyFileName,
      onClick: (menuItem) => handleCopyFilename(),
      disabled: !isFile,
    );

    final copyFilePathItem = MenuItem(
      label: PfsLocalization.copyFilePath,
      onClick: (menuItem) => handleCopyFilePath(),
      disabled: !isFile,
    );

    final revealInExplorerItem = MenuItem(
      label: PfsLocalization.revealInExplorer,
      onClick: (menuItem) => revealInExplorerHandler(),
      disabled: !isFile,
    );

    final contextMenu = Menu(
      items: [
        copyImageItem,
        copyFilePathItem,
        copyFilename,
        MenuItem.separator(),
        revealInExplorerItem,
      ],
    );

    // nativeapi API
    //
    // Menu getContextMenu() {
    //   final copyImage = MenuItem(PfsLocalization.copyImageToClipboard)
    //     ..on<MenuItemClickedEvent>((_) => handleCopyCurrentImage())
    //     ..enabled = imageData is! image_data.InvalidImageData;

    //   final copyFilename = MenuItem(PfsLocalization.copyFileName)
    //     ..on<MenuItemClickedEvent>((_) => handleCopyFilename())
    //     ..enabled = isFile;

    //   final copyFilePath = MenuItem(PfsLocalization.copyFilePath)
    //     ..on<MenuItemClickedEvent>((_) => handleCopyFilePath())
    //     ..enabled = isFile;

    //   final revealInExplorer = MenuItem(PfsLocalization.revealInExplorer)
    //     ..on<MenuItemClickedEvent>((_) => handleCopyFilename())
    //     ..enabled = isFile;

    //   final colorChangeMode = MenuItem(PfsLocalization.openColorChangeMeter)
    //     ..on<MenuItemClickedEvent>((_) => colorChangeModeHandler());

    //   return Menu()
    //     ..addItem(copyImage)
    //     ..addItem(copyFilePath)
    //     ..addItem(copyFilename)
    //     ..addSeparator()
    //     ..addItem(colorChangeMode)
    //     ..addSeparator()
    //     ..addItem(revealInExplorer);
    // }

    // void openContextMenu() {
    //   getContextMenu().open(PositioningStrategy.cursorPosition());
    // }

    void openContextMenu() {
      popUpContextualMenu(contextMenu);
    }

    return GestureDetector(
      onTertiaryTapDown: (details) => resetZoomLevelHandler(),
      onSecondaryTapDown: (details) => openContextMenu(),
      child: child,
    );
  }
}

class ImageViewerStackWidget extends StatelessWidget {
  const ImageViewerStackWidget({
    super.key,
    required this.bottomBarHeight,
    required this.revealInExplorerHandler,
    required this.panDurationListenable,
    required this.zoomPanner,
    required this.filters,
  });

  final ImageZoomPanner zoomPanner;
  final ImageFilters filters;
  final ValueNotifier<Duration> panDurationListenable;
  final ValueListenable<double> bottomBarHeight;
  final Function(ImageFileData fileData) revealInExplorerHandler;

  @override
  Widget build(BuildContext context) {
    final model = PfsAppModel.of(context);

    final content = ListenableBuilder(
      listenable: model.currentImageChangedNotifier,
      builder: (context, _) {
        Image getImageWidget(ImageData imageData) {
          if (imageData is image_data.ImageFileData) {
            final imageFile = File(imageData.filePath);
            return Image.file(
              filterQuality: FilterQuality.medium,
              key: ImagePhviewer.imageWidgetKey,
              imageFile,
            );
          } else if (imageData is ImageMemoryData) {
            final byteData = imageData.bytes;
            if (byteData != null) {
              return Image.memory(
                filterQuality: FilterQuality.medium,
                key: ImagePhviewer.imageWidgetKey,
                byteData,
              );
            }
          }

          return Image.file(File(""));
        }

        final currentImageData = model.getCurrentImageData();
        final imageWidget = getImageWidget(currentImageData);
        final possiblyOverlayedWidget = ValueListenableBuilder(
          valueListenable: model.currentAppControlsMode,
          builder: (
            BuildContext context,
            PfsAppControlsMode mode,
            Widget? child,
          ) {
            switch (mode) {
              case PfsAppControlsMode.annotation:
                final annotatedImageWidget = AnnotationOverlay(
                  zoomPanner: zoomPanner,
                  image: imageWidget,
                  annotationType: AnnotationType.line,
                  child: imageWidget,
                );
                return annotatedImageWidget;

              default:
                return imageWidget;
            }
          },
        );

        Widget imageFilenameLayer(ImageData imageData) {
          if (imageData is ImageFileData) {
            return Align(
              heightFactor: 2,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onSecondaryTap: () async {
                  try {
                    final urls = await image_data
                        .tryGetUrls(imageData)
                        .timeout(Duration(milliseconds: 900));
                    if (urls == null) throw Exception("URLs was null");
                    if (urls.isEmpty) throw Exception("URLs was empty");

                    Iterable<MenuItem> getMenuItems() sync* {
                      yield MenuItem(
                          label:
                              "URLs from '..${Platform.pathSeparator}${imageData.parentFolderName}${Platform.pathSeparator}${image_data.linksFilename}'",
                          disabled: true);

                      const linkLimitCount = 8;
                      const lastIndex = linkLimitCount - 1;
                      for (final (i, url) in urls.indexed) {
                        if (i > lastIndex) break;
                        yield MenuItem(
                          label: url.shortenWithEllipsis(50),
                          onClick: (menuItem) =>
                              open_in_browser.openInBrowser(Uri.parse(url)),
                        );
                      }
                    }

                    final contextMenu = Menu(items: getMenuItems().toList());

                    popUpContextualMenu(contextMenu);
                  } catch (e) {
                    popUpContextualMenu(
                      Menu(
                        items: [
                          MenuItem(
                            label: "Reveal in explorer",
                            onClick: (menuItem) =>
                                revealInExplorerHandler(imageData),
                          ),
                        ],
                      ),
                    );
                  }
                },
                child: ImageClickableLabel(
                  label: imageData.fileName,
                  tooltip:
                      "${PfsLocalization.revealInExplorer} : ${imageData.parentFolderName}",
                  onTap: () => revealInExplorerHandler(imageData),
                ),
              ),
            );
          }

          return SizedBox.shrink();
        }

        final isNextImageTransition = model.lastIncrement > 0;
        final currentImageIndexString = model.currentImageIndex.toString();
        final slideKeyString = model.isCountingDown
            ? 'countingDownImage'
            : 'i$currentImageIndexString';

        return Stack(
          children: [
            SizedBox.expand(
              child: ValueListenableBuilder(
                valueListenable: zoomPanner.flipHorizontalListenable,
                builder: (_, __, ___) {
                  return Transform.flip(
                    flipX: zoomPanner.flipHorizontalListenable.value,
                    flipY: false,
                    child: ValueListenableBuilder(
                        valueListenable: panDurationListenable,
                        builder: (_, panDuration, ___) {
                          return ListeningAnimatedTranslate(
                            offsetListenable: zoomPanner.offsetListenable,
                            duration: panDuration,
                            child: ValueListenableBuilder(
                              valueListenable: zoomPanner.zoomLevelListenable,
                              builder: (_, __, ___) {
                                return AnimatedScale(
                                  duration: Phanimations.zoomTransitionDuration,
                                  curve: Phanimations.zoomTransitionCurve,
                                  scale: zoomPanner.currentZoomScale,
                                  child: possiblyOverlayedWidget,
                                );
                              },
                            ),
                          );
                        }),
                  );
                },
              ),
            ).animate(
              key: Key(slideKeyString),
              effects: isNextImageTransition
                  ? Phanimations.imageNext
                  : Phanimations.imagePrevious,
            ),
            annotationEscapeGesturesLayer(model, context),
            filters.blurFilterLayer(),
            filters.grayscaleFilterLayer(),
            imageFilenameLayer(currentImageData),
          ],
        );
      },
    );

    return ValueListenableBuilder(
      valueListenable: bottomBarHeight,
      builder: (_, bottomBarHeightValue, __) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutExpo,
          padding: EdgeInsets.only(
            bottom: bottomBarHeightValue,
            top: kWindowTitleBarHeight,
          ),
          child: content,
        );
      },
    );
  }

  Widget annotationEscapeGesturesLayer(
    PfsAppModel model,
    BuildContext context,
  ) {
    return ValueListenableBuilder(
      valueListenable: model.currentAppControlsMode,
      builder: (_, appControlsModeValue, __) {
        if (appControlsModeValue != PfsAppControlsMode.annotation) {
          return SizedBox.shrink();
        }

        const translucent = HitTestBehavior.translucent;

        return GestureDetector(
          behavior: translucent,
          onSecondaryTap: () {
            final restoredMode =
                AnnotationsModel.of(context).tryRestoreBaselineMode();
            if (restoredMode) return;

            EscapeNavigator.of(context)?.tryEscape();
          },
          child: ImagePhviewerZoomOnScrollListener(
            behavior: translucent,
            zoomPanner: zoomPanner,
            child: SizedBox.expand(),
          ),
        );
      },
    );
  }
}

class ImagePhviewerPanListener extends StatelessWidget {
  const ImagePhviewerPanListener({
    super.key,
    required this.zoomPanner,
    required this.child,
  });

  final ImageZoomPanner zoomPanner;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) =>
          handlePanUpdate(details: details, zoomPanner: zoomPanner),
      onPanEnd: (details) =>
          handlePanEnd(details: details, zoomPanner: zoomPanner),
      child: child,
    );
  }

  static void handlePanEnd({
    required DragEndDetails details,
    required ImageZoomPanner zoomPanner,
  }) {
    zoomPanner.resetZoomAccumulator();

    if (!zoomPanner.isZoomedIn) return;
    zoomPanner.panRelease();
  }

  static void handlePanUpdate({
    required DragUpdateDetails details,
    required ImageZoomPanner zoomPanner,
    bool useZoomPannerScale = false,
  }) {
    final pointerDelta = details.delta;

    if (Phshortcuts.isDragZoomModifierPressed()) {
      zoomPanner.incrementZoomAccumulator(pointerDelta.dx);
      zoomPanner.incrementZoomAccumulator(-pointerDelta.dy);
      return;
    }

    //if (!zoomPanner.isZoomedIn) return;

    final deltaScale = (useZoomPannerScale ? zoomPanner.currentZoomScale : 1.0);
    zoomPanner.panImage(pointerDelta * deltaScale);
  }
}

class ImagePhviewerZoomOnScrollListener extends StatelessWidget {
  const ImagePhviewerZoomOnScrollListener({
    super.key,
    required this.child,
    required this.zoomPanner,
    this.behavior = HitTestBehavior.deferToChild,
  });

  final Widget child;
  final ImageZoomPanner zoomPanner;
  final HitTestBehavior behavior;

  @override
  Widget build(BuildContext context) {
    return ScrollListener(
      behavior: behavior,
      onScrollDown: () => zoomPanner.incrementZoomLevel(-1),
      onScrollUp: () => zoomPanner.incrementZoomLevel(1),
      child: child,
    );
  }
}

class ResetZoomButton extends StatelessWidget {
  const ResetZoomButton({
    super.key,
    required this.zoomPanner,
  });

  final ImageZoomPanner zoomPanner;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: zoomPanner.zoomLevelListenable,
      builder: (_, __, ___) {
        return Visibility(
          visible: !zoomPanner.isZoomLevelDefault,
          child: IconButton(
            tooltip: "Reset zoom",
            onPressed: () => zoomPanner.resetTransform(),
            icon: const Icon(Icons.youtube_searched_for),
          ),
        );
      },
    );
  }
}
