import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/utils/values_notifier.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:pfs2/widgets/phbuttons.dart';
import 'package:url_launcher/url_launcher.dart';

class ImagePhviewer {
  ImagePhviewer();

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

  bool get isUsingGrayscale => usingGrayscaleListenable.value;
  set isUsingGrayscale(bool value) => usingGrayscaleListenable.value = value;
  final usingGrayscaleListenable = ValueNotifier<bool>(false);

  final offsetListenable = ValueNotifier<Offset>(Offset.zero);
  Offset get panOffset => offsetListenable.value;

  static const double _minBlurLevel = 0;
  static const double _maxBlurLevel = 12;
  final blurLevelListenable = ValueNotifier<double>(0.0);
  double get blurLevel => blurLevelListenable.value;
  set blurLevel(double val) => blurLevelListenable.value =
      clampDouble(val, _minBlurLevel, _maxBlurLevel);

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

  void panImage(Offset delta) {
    offsetListenable.value = offsetListenable.value + delta;
  }

  void _resetZoomLevel() {
    zoomLevelListenable.value = _defaultZoomLevel;
  }

  void resetOffset() {
    offsetListenable.value = Offset.zero;
  }

  void resetTransform() {
    _resetZoomLevel();
    resetOffset();
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

  Widget widget(ValueListenable<bool> isBottomBarMinimized) {
    return ImageDisplay(
      isBottomBarMinimized: isBottomBarMinimized,
      offsetListenable: offsetListenable,
      blurLevelListenable: blurLevelListenable,
      usingGrayscaleListenable: usingGrayscaleListenable,
      zoomLevelListenable: zoomLevelListenable,
      getCurrentZoomScale: () => currentZoomScale,
      revealInExplorerHandler: revealInExplorer,
    );
  }

  void incrementZoomLevel(int increment) {
    final newZoomLevel = zoomLevelListenable.value + increment;
    zoomLevelListenable.value = newZoomLevel.clamp(0, _zoomScales.length - 1);
  }

  static void revealInExplorer(FileData fileData) async {
    if (Platform.isWindows) {
      final windowsFilePath = fileData.filePath.replaceAll('/', '\\');
      await Process.start('explorer', ['/select,', windowsFilePath]);
    } else {
      Uri fileFolder = Uri.file(fileData.fileFolder);
      await launchUrl(fileFolder);
    }
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

  static final textMaterialStyles = PfsTheme.hoverProperty(
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
    final buttonMaterialColors = PfsTheme.hoverColors(
      idle: buttonHoverBackground.withAlpha(0x00),
      hover: buttonHoverBackground,
    );

    final textMaterialColors = PfsTheme.hoverColors(
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

typedef ClipboardCopyHandler = void Function(
    {required String newClipboardText, String? toastMessage});

class ImageRightClick extends StatelessWidget {
  const ImageRightClick({
    super.key,
    required this.child,
    this.clipboardCopyHandler,
    required this.resetZoomLevelHandler,
    required this.revealInExplorerHandler,
  });

  final Widget child;
  final ClipboardCopyHandler? clipboardCopyHandler;
  final VoidCallback resetZoomLevelHandler;
  final VoidCallback revealInExplorerHandler;

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      void handleCopyFilePath() {
        clipboardCopyHandler?.call(
          newClipboardText: model.getCurrentImageData().filePath,
          toastMessage: 'File path copied to clipboard.',
        );
      }

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

class ImageDisplay extends StatelessWidget {
  const ImageDisplay({
    super.key,
    required this.isBottomBarMinimized,
    required this.zoomLevelListenable,
    required this.blurLevelListenable,
    required this.usingGrayscaleListenable,
    required this.getCurrentZoomScale,
    required this.revealInExplorerHandler,
    required this.offsetListenable,
  });

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
          ? model.getCurrentImageData()
          : FileList.fileDataFromPath(defaultImage);

      final File imageFile = File(imageFileData.filePath);
      final imageWidget = Image.file(
        gaplessPlayback: true,
        filterQuality: FilterQuality.medium,
        imageFile,
      );

      final imageFilenameLayer = Align(
        heightFactor: 2,
        alignment: Alignment.topCenter,
        child: ImageClickableLabel(
          label: imageFileData.fileName,
          tooltip: PfsLocalization.revealInExplorer,
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
                valueListenable: offsetListenable,
                builder: (_, offset, ___) {
                  return Transform.translate(
                    offset: offset,
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
                },
              ),
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
