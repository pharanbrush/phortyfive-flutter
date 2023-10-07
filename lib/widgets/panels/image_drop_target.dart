import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';

class ImageDropTarget extends StatefulWidget {
  const ImageDropTarget({super.key, this.onDragSuccess});

  static const Color boxColor = Color(0xAA000000);
  static const Color textColor = Colors.white60;
  static const BoxDecoration activeBoxDecoration = BoxDecoration(
    color: boxColor,
    borderRadius: BorderRadius.all(Radius.circular(5)),
  );
  static const BoxDecoration hiddenBoxDecoration =
      BoxDecoration(color: Colors.transparent);

  static const TextStyle textStyle =
      TextStyle(fontSize: 40, color: textColor, inherit: true);

  static const Widget hiddenDropWidget =
      Center(child: Material(textStyle: textStyle, child: Text('')));

  static const Widget visibleDropWidget = Center(
    child: Material(
      textStyle: textStyle,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: textColor,
            size: 80,
          ),
          SizedBox(height: 15),
          Text(
            'Drop image files here.',
          ),
        ],
      ),
    ),
  );

  final Function()? onDragSuccess;

  @override
  State<ImageDropTarget> createState() => _ImageDropTargetState();
}

class _ImageDropTargetState extends State<ImageDropTarget> {
  bool _isDragging = false;

  void _setDraggingActive(bool active) {
    setState(() {
      _isDragging = active;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PfsAppModel.scope((_, __, model) {
      return DropTarget(
        onDragDone: (details) {
          _setDraggingActive(false);

          if (details.files.isEmpty) return;
          List<String> filePaths = [];
          for (var file in details.files) {
            var filePath = file.path;
            if (FileList.fileIsImage(filePath)) {
              filePaths.add(filePath);
            }
          }
          if (filePaths.isEmpty) return;

          model.loadImages(filePaths);

          if (model.hasFilesLoaded) {
            widget.onDragSuccess!(); //windowManager.focus();
          }
        },
        onDragEntered: (details) => _setDraggingActive(true),
        onDragExited: (details) => _setDraggingActive(false),
        child: Container(
          decoration: _isDragging
              ? ImageDropTarget.activeBoxDecoration
              : ImageDropTarget.hiddenBoxDecoration,
          child: _isDragging
              ? ImageDropTarget.visibleDropWidget
              : ImageDropTarget.hiddenDropWidget,
        ),
      );
    });
  }
}
