import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
import 'package:url_launcher/url_launcher.dart';

class ImagePhviewer {
  ImagePhviewer({this.onNotify, required this.onStateChange});

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

  bool _isUsingGrayscale = false;
  double _blurLevel = 0;

  int currentZoomLevel = _defaultZoomLevel;
  double get currentZoomScale => _zoomScales[currentZoomLevel];
  bool get isZoomLevelDefault => (currentZoomLevel == _defaultZoomLevel);

  int get currentZoomScalePercent => (currentZoomScale * 100).toInt();

  bool get isFilterActive => (_isUsingGrayscale || _blurLevel > 0);
  bool get isUsingGrayscale => _isUsingGrayscale;
  double get blurLevel => _blurLevel;

  int get activeFilterCount {
    int currentActiveFiltersCount = 0;
    if (_blurLevel > 0) currentActiveFiltersCount++;
    if (_isUsingGrayscale) currentActiveFiltersCount++;

    return currentActiveFiltersCount;
  }

  Function(IconData icon, String text)? onNotify;
  Function()? onStateChange;

  void resetZoomLevel() {
    currentZoomLevel = _defaultZoomLevel;
  }

  void resetAllFilters() {
    setGrayscaleActive(false);
    setBlurLevel(0);
  }

  void toggleGrayscale() {
    setGrayscaleActive(!_isUsingGrayscale);
  }

  void setBlurLevel(double newBlurLevel) {
    _blurLevel = newBlurLevel;
    onStateChange?.call();
  }

  void setGrayscaleActive(bool active) {
    _isUsingGrayscale = active;
    onStateChange?.call();
  }

  void incrementZoomLevel(int increment) {
    currentZoomLevel += increment;
    currentZoomLevel = currentZoomLevel.clamp(0, _zoomScales.length - 1);
  }

  Widget imageRightClick({
    required Widget child,
    void Function({required String newClipboardText, String? snackbarMessage})?
        clipboardCopyHandler,
  }) {
    return PfsAppModel.scope((_, __, model) {
      void handleCopyFilePath() {
        clipboardCopyHandler?.call(
          newClipboardText: model.getCurrentImageData().filePath,
          snackbarMessage: 'File path copied to clipboard.',
        );
      }

      void handleRevealInExplorer() {
        revealInExplorer(model.getCurrentImageData());
      }

      final copyFilePathItem = MenuItem(
        label: PfsLocalization.copyFilePath,
        onClick: (menuItem) => handleCopyFilePath(),
      );

      final revealInExplorerItem = MenuItem(
        label: PfsLocalization.revealInExplorer,
        onClick: (menuItem) => handleRevealInExplorer(),
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
        onTertiaryTapDown: (details) {
          () => resetZoomLevel();
          onStateChange?.call();
        },
        onSecondaryTapDown: (details) {
          openContextMenu();
        },
        child: child,
      );
    });
  }

  Widget widget(bool isBottomBarMinimized) {
    const minimizedPadding = EdgeInsets.only(bottom: 5);
    const normalPadding = EdgeInsets.only(bottom: 46);
    final padding = isBottomBarMinimized ? minimizedPadding : normalPadding;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutExpo,
      padding: padding,
      child: PfsAppModel.scope((_, __, model) {
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
          alignment: Alignment.topCenter,
          child: ImageClickableLabel(
            label: imageFileData.fileName,
            tooltip: PfsLocalization.revealInExplorer,
            onTap: () => revealInExplorer(imageFileData),
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
                child: AnimatedScale(
                  duration: Phanimations.zoomTransitionDuration,
                  curve: Phanimations.zoomTransitionCurve,
                  scale: _zoomScales[currentZoomLevel],
                  child: imageWidget,
                ),
              ),
            ),
            if (_blurLevel > 0)
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: pow(1.3, _blurLevel).toDouble(),
                    sigmaY: pow(1.3, _blurLevel).toDouble()),
                child: const SizedBox.expand(),
              ),
            if (_isUsingGrayscale) _matrixGrayscale,
            imageFilenameLayer,
          ],
        );
      }),
    );
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

  static const Widget _matrixGrayscale = BackdropFilter(
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

  static final buttonMaterialColors = PfsTheme.hoverColors(
    idle: Colors.white.withAlpha(0x00),
    hover: Colors.white,
  );

  @override
  Widget build(BuildContext context) {
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

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        preferBelow: true,
        child: TextButton(style: style, onPressed: onTap, child: Text(label)),
      ),
    );
  }
}
