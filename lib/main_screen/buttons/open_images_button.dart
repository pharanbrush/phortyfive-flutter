import 'dart:io';

import 'package:contextual_menu/contextual_menu.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/pfs_preferences.dart' as pfs_preferences;
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';

class ImageSetButton extends StatelessWidget {
  const ImageSetButton({
    super.key,
    this.narrowButton = false,
    this.extraTooltip,
    required this.model,
  });

  static const double _iconSize = 17;
  static const IconData imageIcon = Icons.image;
  static const Icon _icon = Icon(imageIcon, size: _iconSize);

  final bool narrowButton;
  final String? extraTooltip;
  final PfsAppModel model;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: model.imageListChangedNotifier,
        builder: (context, __) {
          final fileCount = model.imageList.getCount();
          final lastFolder = model.lastFolder;
          final String tooltip =
              "${(extraTooltip != null ? "$extraTooltip\n\n" : "")}Folder: ...${Platform.pathSeparator}$lastFolder\n"
              "$fileCount ${PfsLocalization.imageNoun(fileCount)} loaded and shuffled";

          const double wideWidth = 80;
          const double narrowWidth = 18;

          final double currentWidth = narrowButton ? narrowWidth : wideWidth;

          return Tooltip(
            message: tooltip,
            child: TextButton(
              onPressed: () => _popupImagesMenu(model),
              child: AnimatedSizedBoxWidth(
                defaultWidth: narrowWidth,
                width: currentWidth,
                height: 28,
                duration: Phanimations.defaultDuration,
                child: Align(
                  alignment: Alignment.center,
                  child: OverflowBox(
                    maxWidth: currentWidth,
                    child: Row(
                      children: [
                        const Spacer(),
                        narrowButton
                            ? _icon
                            : IconAndText(
                                text: fileCount.toString(),
                                icon: imageIcon,
                                iconSize: _iconSize,
                                gap: 3,
                              ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
  }
}

Widget openFilesButton({double width = 40.0, required PfsAppModel model}) {
  final toolTipText =
      'Open images... (${PfsLocalization.tooltipShortcut(Phshortcuts.openFiles)})';

  return Builder(
    builder: (context) {
      final style = FilledButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.tertiary,
      );

      return Tooltip(
        message: toolTipText,
        child: FilledButton(
          style: style,
          onPressed: () => _popupImagesMenu(model),
          child: SizedBox(
            width: width,
            child: const Icon(browseIcon),
          ),
        ),
      );
    },
  );
}

// nativeapi API

// void _popupImagesMenu(PfsAppModel model) {
//   Menu getOpenImagesMenu(PfsAppModel model) {
//     return Menu()
//       ..addItem(
//         MenuItem("Open images...")
//           ..on<MenuItemClickedEvent>((_) => model.openFilePickerForImages()),
//       )
//       ..addSeparator()
//       ..addItem(
//         MenuItem("Open images...")
//           ..on<MenuItemClickedEvent>((_) => model.openFilePickerForFolder())
//       )
//       ..addItem(
//         MenuItem("Open folder and subfolders...")..on<MenuItemClickedEvent>(
//           (_) => model.openFilePickerForFolder(includeSubfolders: true),
//         ),
//       );
//   }

//   final menu = getOpenImagesMenu(model);
//   menu.open(PositioningStrategy.cursorPosition(), Placement.topStart);
// }

// Custom Popup Menu using OverlayEntry

// OverlayEntry? overlayEntry;

// void dummy(BuildContext context, PfsAppModel model) {
//   final getRecentFolders =
//       pfs_preferences.getRecentFolders().timeout(Duration(milliseconds: 1500));

//   void closePopup() {
//     if (overlayEntry != null) {
//       overlayEntry!.remove();
//       overlayEntry = null;
//     }
//   }

//   final overlay = Overlay.of(context);
//   overlayEntry = OverlayEntry(
//     builder: (context) {
//       final theme = Theme.of(context);

//       return Stack(
//         children: [
//           ModalUnderlay.transparent(
//             onDismiss: () => closePopup(),
//           ),
//           Positioned(
//             bottom: 10,
//             right: 10,
//             child: Material(
//               //color: theme.colorScheme.tertiary,
//               elevation: 8,
//               child: Padding(
//                 padding: const EdgeInsets.all(15.0),
//                 child: DefaultTextStyle(
//                   style: theme.textTheme.labelMedium!,
//                   child: FutureBuilder(
//                     future: getRecentFolders,
//                     builder: (context, snapshot) {
//                       final items = <Widget>[
//                         if (snapshot.hasData) Text("Recent folders"),
//                         if (snapshot.hasData)
//                           ...snapshot.data!.map(
//                             (folderItem) {
//                               final shortenedPath =
//                                   shortenFolderPath(folderItem.folderPath);

//                               return InkWell(
//                                 onTap: () {
//                                   model.loadFolder(
//                                     folderItem.folderPath,
//                                     recursive: folderItem.includeSubfolders,
//                                   );
//                                   closePopup();
//                                 },
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(10.0),
//                                   child: Padding(
//                                     padding: const EdgeInsets.only(right: 20.0),
//                                     child: IconAndText(
//                                       text: shortenedPath,
//                                       icon: FluentIcons.folder_16_regular,
//                                     ),
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                         if (!snapshot.hasData)
//                           CircularProgressIndicator(
//                             color: theme.colorScheme.onSurface,
//                           ),
//                         Text("Hello Item"),
//                       ];

//                       return IntrinsicWidth(
//                         child: Column(
//                           mainAxisSize: MainAxisSize.min,
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: items,
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ).animate(effects: [Phanimations.slideUpEffectLarge]),
//           ),
//         ],
//       );
//     },
//   );

//   if (overlayEntry != null) {
//     overlay.insert(overlayEntry!);
//   }
// }

void _popupImagesMenu(PfsAppModel model) {
  _getOpenImagesMenu(model).then(
    (menu) => popUpContextualMenu(menu, placement: Placement.topLeft),
  );
}

Future<Menu> _getOpenImagesMenu(PfsAppModel model) async {
  final baseMenuItems = [
    MenuItem(
      label: "Open images...",
      onClick: (menuItem) {
        model.openFilePickerForImages();
      },
    ),
    MenuItem.separator(),
    MenuItem(
      label: "Open image folder...",
      onClick: (menuItem) {
        model.openFilePickerForFolder();
      },
    ),
    MenuItem(
      label: "Open folder and subfolders...",
      onClick: (menuItem) {
        model.openFilePickerForFolder(includeSubfolders: true);
      },
    )
  ];

  try {
    final recentFolderEntries = await pfs_preferences
        .getRecentFolders()
        .timeout(Duration(milliseconds: 1500));

    if (recentFolderEntries == null) {
      return Menu(items: baseMenuItems);
    }

    final menuItems = <MenuItem>[];
    for (final e in recentFolderEntries) {
      final shortenedPath = shortenFolderPath(e.folderPath);

      menuItems.add(
        MenuItem(
          label: shortenedPath,
          onClick: (menuItem) => model.loadFolder(
            e.folderPath,
            recursive: e.includeSubfolders,
          ),
        ),
      );
    }

    if (menuItems.isNotEmpty) {
      // Add number prefixes
      for (final (i, item) in menuItems.reversed.indexed) {
        item.label = "${i + 1}   ${item.label}";
      }

      // Add separator
      menuItems.add(MenuItem.separator());
    }

    menuItems.addAll(baseMenuItems);

    return Menu(items: menuItems);
  } catch (e) {
    return Menu(items: baseMenuItems);
  }
}
