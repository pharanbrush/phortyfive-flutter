import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';

class ImageDropTarget extends StatefulWidget {
  const ImageDropTarget({super.key, this.onDragSuccess});

  static const Widget hiddenDropWidget = Center(
      child:
          Material(textStyle: PfsTheme.dropTargetTextStyle, child: Text('')));

  static const Widget visibleDropWidget = Center(
    child: Material(
      textStyle: PfsTheme.dropTargetTextStyle,
      color: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            color: PfsTheme.dropTargetTextColor,
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
            widget.onDragSuccess!();
          }
        },
        onDragEntered: (details) => _setDraggingActive(true),
        onDragExited: (details) => _setDraggingActive(false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutQuart,
          key: const Key('dropContainer'),
          margin:
              _isDragging ? const EdgeInsets.all(8) : const EdgeInsets.all(20),
          decoration: _isDragging
              ? PfsTheme.dropActiveBoxDecoration
              : PfsTheme.dropHiddenBoxDecoration,
          child: _isDragging
              ? ImageDropTarget.visibleDropWidget
              : ImageDropTarget.hiddenDropWidget,
        ),
      );
    });
  }
}
