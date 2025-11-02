import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

void getImageDataFromClipboard(
    void Function(Uint8List? imageBytes) onClipboardImageRead) async {
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
