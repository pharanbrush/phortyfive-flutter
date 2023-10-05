import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/screens/main_screen.dart';

class ImagePhviewer {
  static const List<double> zoomLevels = [
    0.25,
    0.5,
    0.75,
    1.0,
    1.5,
    2.0,
    3.0,
    4.0
  ];
  static const defaultZoomLevel = 3;

  bool get isEffectActive => (isUsingGrayscale || blurLevel > 0);
  bool isUsingGrayscale = false;
  double blurLevel = 0;

  int currentZoomLevel = defaultZoomLevel;

  static const Widget matrixGrayscale = BackdropFilter(
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

  void resetZoomLevel() {
    currentZoomLevel = defaultZoomLevel;
  }

  void toggleGrayscale() {
    isUsingGrayscale = !isUsingGrayscale;
  }

  void incrementZoomLevel(int increment) {
    currentZoomLevel += increment;
    currentZoomLevel = currentZoomLevel.clamp(0, zoomLevels.length - 1);
  }

  Widget widget(bool isBottomBarMinimized) {
    final double bottomPadding = isBottomBarMinimized ? 5 : 45;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Phbuttons.appModelWidget((_, __, model) {
        const defaultImage = '';

        final FileData imageFileData = model.hasFilesLoaded
            ? model.getCurrentImageData()
            : FileList.fileDataFromPath(defaultImage);

        final File imageFile = File(imageFileData.filePath);

        final style = TextStyle(
          color: Colors.grey.shade500,
          fontSize: 11,
        );
        var topText = Text(imageFileData.fileName, style: style);
        const opacity = 0.3;

        return Stack(
          children: [
            SizedBox.expand(
              child: Image.file(
                scale: zoomLevels[currentZoomLevel],
                gaplessPlayback: true,
                filterQuality: FilterQuality.medium,
                //fit: BoxFit.scaleDown,
                imageFile,
              ),
            ),
            if (blurLevel > 0)
              BackdropFilter(
                filter: ImageFilter.blur(
                    sigmaX: pow(1.3, blurLevel).toDouble(),
                    sigmaY: pow(1.3, blurLevel).toDouble()),
                child: const SizedBox.expand(),
              ),
            if (isUsingGrayscale) matrixGrayscale,
            Align(
              alignment: Alignment.topCenter,
              child: Material(
                color: Colors.transparent,
                child: Opacity(opacity: opacity, child: topText),
              ),
            ),
          ],
        );
      }),
    );
  }
}
