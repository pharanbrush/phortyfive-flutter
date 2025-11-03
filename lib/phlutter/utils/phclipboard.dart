import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart'
    show DataWriterItem, Formats, SystemClipboard;

Future copyImageFileToClipboardAsPngAndFileUri({
  required Image image,
  required String filePath,
  String suggestedName = "Image",
}) async {
  final byteData = await image.toByteData(format: ImageByteFormat.png);
  if (byteData == null) return;

  final imageData = byteData.buffer.asUint8List();
  final fileUri = Uri.file(filePath);

  final item = DataWriterItem(suggestedName: suggestedName);
  item.add(Formats.png(imageData));
  item.add(Formats.fileUri(fileUri));
  await SystemClipboard.instance?.write([item]);
}

Future<String?> getStringFromClipboard() async {
  var clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
  if (clipboardData == null) return null;

  return clipboardData.text;
}

void getImageBytesFromClipboard(
  void Function(Uint8List? imageBytes) onClipboardImageRead,
) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return;
  }

  final reader = await clipboard.read();

  if (reader.canProvide(Formats.png)) {
    reader.getFile(Formats.png, (file) async {
      Uint8List? data = await file.readAll();
      onClipboardImageRead.call(data);
    });
  }
}
