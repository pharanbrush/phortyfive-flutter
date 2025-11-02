import 'dart:typed_data';

import 'package:pfs2/core/image_data.dart';

class ImageMemoryData extends ImageData {
  final Uint8List? bytes;

  ImageMemoryData({required this.bytes});
}
