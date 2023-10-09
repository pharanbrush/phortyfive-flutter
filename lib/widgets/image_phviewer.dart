import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/phcontext_menu.dart';
import 'package:pfs2/widgets/phbuttons.dart';
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

  final MenuController imageMenuRightClickController = MenuController();

  bool _isUsingGrayscale = false;
  double _blurLevel = 0;

  int currentZoomLevel = _defaultZoomLevel;
  double get currentZoomScale => _zoomScales[currentZoomLevel];
  bool get isZoomLevelDefault => (currentZoomLevel == _defaultZoomLevel);

  int get currentZoomScalePercent => (currentZoomScale * 100).toInt();

  bool get isFilterActive => (_isUsingGrayscale || _blurLevel > 0);
  bool get isUsingGrayscale => _isUsingGrayscale;
  double get blurLevel => _blurLevel;

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

  Widget imageRightClick(
      {Widget? child,
      void Function(
              {required String newClipboardText, String? snackbarMessage})?
          clipboardCopyHandler}) {
    return PfsAppModel.scope((_, __, model) {
      return GestureDetector(
        onSecondaryTapDown: (details) {
          imageMenuRightClickController.open(position: details.localPosition);
        },
        onTertiaryTapDown: (details) {
          () => resetZoomLevel();
          onStateChange?.call();
        },
        child: MenuAnchor(
          anchorTapClosesMenu: true,
          controller: imageMenuRightClickController,
          menuChildren: [
            PhcontextMenu.menuItemButton(
              text: Phbuttons.revealInExplorerText,
              //icon: Icons.folder_open,
              onPressed: () => revealInExplorer(model.getCurrentImageData()),
            ),
            PhcontextMenu.menuItemButton(
              text: 'Copy file path',
              icon: Icons.copy,
              onPressed: () => clipboardCopyHandler?.call(
                newClipboardText: model.getCurrentImageData().filePath,
                snackbarMessage: 'File path copied to clipboard.',
              ),
            ),
          ],
          child: child,
        ),
      );
    });
  }

  Widget widget(bool isBottomBarMinimized) {
    const filenameTextStyle = TextStyle(color: Color(0xFF9E9E9E), fontSize: 11);

    const minimizedPadding = EdgeInsets.only(bottom: 5);
    const normalPadding = EdgeInsets.only(bottom: 45);
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
        var topText = Text(imageFileData.fileName, style: filenameTextStyle);
        const opacity = 0.3;

        final currentImageIndexString = model.currentImageIndex.toString();

        final imageWidget = Image.file(
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          imageFile,
        );

        const double imageSlideOriginX = 0.05;
        final imageSwapOrigin = model.lastIncrement > 0
            ? const Offset(imageSlideOriginX, 0)
            : const Offset(-imageSlideOriginX, 0);

        final keyString = model.isCountingDown
            ? 'countingDownImage'
            : 'i$currentImageIndexString';

        final imageFilenameLayer = Align(
          alignment: Alignment.topCenter,
          child: Material(
            color: Colors.transparent,
            child: Opacity(
              opacity: opacity,
              child: Tooltip(
                message: Phbuttons.revealInExplorerText,
                waitDuration: const Duration(milliseconds: 200),
                preferBelow: true,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => revealInExplorer(imageFileData),
                    child: topText,
                  ),
                ),
              ),
            ),
          ),
        );
        
        return Stack(
          children: [
            Animate(
              key: Key(keyString),
              effects: [
                SlideEffect(
                  begin: imageSwapOrigin,
                  end: Offset.zero,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutQuint,
                )
              ],
              child: SizedBox.expand(
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 400),
                  scale: _zoomScales[currentZoomLevel],
                  curve: Curves.easeOutExpo,
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

  void revealInExplorer(FileData fileData) async {
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
