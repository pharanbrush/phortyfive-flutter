import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/phcontext_menu.dart';
import 'package:pfs2/widgets/animation/phanimations.dart';
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
        final imageWidget = Image.file(
          gaplessPlayback: true,
          filterQuality: FilterQuality.medium,
          imageFile,
        );

        final imageFilenameLayer = Align(
          alignment: Alignment.topCenter,
          child: ImageClickableLabel(
            label: imageFileData.fileName,
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
  const ImageClickableLabel({super.key, required this.label, this.onTap});

  final String label;
  final Function()? onTap;

  static Color getButtonColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return const Color(0xFFFFFFFF);
    }
    return Colors.transparent;
  }

  static Color getTextColor(Set<MaterialState> states) {
    if (states.contains(MaterialState.hovered)) {
      return Colors.blue;
    }
    return const Color(0x66C0C0C0);
  }

  static TextStyle getTextStyle(Set<MaterialState> states) {
    const double fontSize = 11;
    if (states.contains(MaterialState.hovered)) {
      return const TextStyle(
        decoration: TextDecoration.underline,
        fontSize: fontSize,
        overflow: TextOverflow.ellipsis,
      );
    }

    return const TextStyle(
      decoration: TextDecoration.none,
      fontSize: fontSize,
      overflow: TextOverflow.ellipsis,
    );
  }

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(vertical: 0, horizontal: 14);
    const double maxWidth = 380;

    final ButtonStyle style = ButtonStyle(
      maximumSize: const MaterialStatePropertyAll(Size(maxWidth, 50)),
      backgroundColor: MaterialStateProperty.resolveWith(getButtonColor),
      foregroundColor: MaterialStateProperty.resolveWith(getTextColor),
      textStyle: MaterialStateProperty.resolveWith(getTextStyle),
      padding: const MaterialStatePropertyAll(padding),
      overlayColor: const MaterialStatePropertyAll(Colors.transparent),
    );

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: Phbuttons.revealInExplorerText,
        preferBelow: true,
        child: TextButton(style: style, onPressed: onTap, child: Text(label)),
      ),
    );
  }
}
