import 'dart:io';
import 'dart:ui';
import 'package:flutter/painting.dart';

Future<Image> getImageDataFromFile(String fullFilePath) async {
  FileImage fileImage = FileImage(File(fullFilePath));
  final imageData = await fileImage.file.readAsBytes();
  Codec codec = await instantiateImageCodec(
    imageData,
    allowUpscaling: false,
  );
  FrameInfo frameInfo = await codec.getNextFrame();
  final image = frameInfo.image;
  return image;
}
