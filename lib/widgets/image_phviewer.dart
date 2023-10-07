import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:url_launcher/url_launcher.dart';

class ImagePhviewer {
  ImagePhviewer({this.onNotify});

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

  Function(IconData icon, String text)? onNotify;

  void resetZoomLevel() {
    currentZoomLevel = _defaultZoomLevel;
  }

  void resetAllFilters() {
    _isUsingGrayscale = false;
    _blurLevel = 0;
  }

  void setBlurLevel(double newBlurLevel) {
    _blurLevel = newBlurLevel;
  }

  void setGrayscaleActive(bool active) {
    _isUsingGrayscale = active;
  }

  void toggleGrayscale() {
    _isUsingGrayscale = !_isUsingGrayscale;
  }

  void incrementZoomLevel(int increment) {
    currentZoomLevel += increment;
    currentZoomLevel = currentZoomLevel.clamp(0, _zoomScales.length - 1);
  }

  Widget widget(bool isBottomBarMinimized) {
    const filenameTextStyle = TextStyle(color: Color(0xFF9E9E9E), fontSize: 11);

    const minimizedPadding = EdgeInsets.only(bottom: 5);
    const normalPadding = EdgeInsets.only(bottom: 45);
    final padding = isBottomBarMinimized ? minimizedPadding : normalPadding;

    return Padding(
      padding: padding,
      child: PfsAppModel.scope((_, __, model) {
        const defaultImage = '';

        final FileData imageFileData = model.hasFilesLoaded
            ? model.getCurrentImageData()
            : FileList.fileDataFromPath(defaultImage);

        final File imageFile = File(imageFileData.filePath);
        var topText = Text(imageFileData.fileName, style: filenameTextStyle);
        const opacity = 0.3;

        return Stack(
          children: [
            SizedBox.expand(
              child: AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: _zoomScales[currentZoomLevel],
                curve: Curves.easeOutExpo,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  switchInCurve: Curves.easeOutExpo,
                  switchOutCurve: Curves.easeInExpo,
                  child: Image.file(
                    key: Key('i${model.currentImageIndex.toString()}'),
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    imageFile,
                  ),
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
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Opacity(
                  opacity: opacity,
                  child: Tooltip(
                    message: 'Reveal in File Explorer',
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
            ),
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
