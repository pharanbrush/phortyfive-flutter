import 'dart:io';
import 'dart:ui';
import 'package:flutter/painting.dart';

Future<Image> getUiImageFromFile(String fullFilePath) async {
  final FileImage fileImage = FileImage(File(fullFilePath));
  final imageBytes = await fileImage.file.readAsBytes();
  final Codec codec = await instantiateImageCodec(
    imageBytes,
    allowUpscaling: false,
  );
  final FrameInfo frameInfo = await codec.getNextFrame();
  final uiImage = frameInfo.image;
  return uiImage;
}
