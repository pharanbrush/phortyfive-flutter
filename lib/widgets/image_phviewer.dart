import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';

class ImagePhviewer {
  static const List<double> _zoomLevels = [
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

  bool get isEffectActive => (_isUsingGrayscale || _blurLevel > 0);
  bool get isUsingGrayscale => _isUsingGrayscale;
  double get blurLevel => _blurLevel;

  void setBlurLevel(double newBlurLevel) {
    _blurLevel = blurLevel;
  }
  
  void setGrayscaleActive(bool active) {
    _isUsingGrayscale = active;
  }

  void resetZoomLevel() {
    currentZoomLevel = _defaultZoomLevel;
  }

  void toggleGrayscale() {
    _isUsingGrayscale = !_isUsingGrayscale;
  }

  void incrementZoomLevel(int increment) {
    currentZoomLevel += increment;
    currentZoomLevel = currentZoomLevel.clamp(0, _zoomLevels.length - 1);
  }

  Widget widget(bool isBottomBarMinimized) {
    const minimizedPadding = EdgeInsets.only(bottom: 5);
    const normalPadding = EdgeInsets.only(bottom: 45);
    final padding = isBottomBarMinimized ? minimizedPadding : normalPadding;
    const filenameTextStyle = TextStyle(color: Color(0xFF9E9E9E), fontSize: 11);

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
              child: Image.file(
                scale: _zoomLevels[currentZoomLevel],
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                //fit: BoxFit.scaleDown,
                imageFile,
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
                  child: topText,
                ),
              ),
            ),
          ],
        );
      }),
    );
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
