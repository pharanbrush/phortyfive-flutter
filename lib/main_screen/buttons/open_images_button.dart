import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nativeapi/nativeapi.dart';
import 'package:pfs2/core/image_data.dart';
import 'package:pfs2/models/pfs_model.dart';
import 'package:pfs2/models/pfs_preferences.dart' as pfs_preferences;
import 'package:pfs2/phlutter/utils/phclipboard.dart';
import 'package:pfs2/phlutter/widget/secondary_tap_menu.dart';
import 'package:pfs2/ui/pfs_localization.dart';
import 'package:pfs2/ui/phanimations.dart';
import 'package:pfs2/ui/phshortcuts.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:pfs2/widgets/phbuttons.dart';

import '../../phlutter/dart/shorten_paths.dart';
import '../../phlutter/macos_bookmarks.dart' as macos_bookmarks;

class ImageSetButton extends StatelessWidget {
  const ImageSetButton({
    super.key,
    this.narrowButton = false,
    this.extraTooltip,
    required this.model,
    this.pasteHandler,
  });

  static const double _iconSize = 17;
  static const IconData imageIcon = Icons.image;
  static const Icon _icon = Icon(imageIcon, size: _iconSize);

  final bool narrowButton;
  final String? extraTooltip;
  final PfsAppModel model;
  final VoidCallback? pasteHandler;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: model.imageListChangedNotifier,
      builder: (context, _) {
        final fileCount = model.imageList.count;
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
            onPressed: () => _popupImagesMenu(model, pasteHandler),
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
      },
    );
  }
}

Widget openFilesButton({
  double width = 40.0,
  required PfsAppModel model,
  VoidCallback? pasteHandler,
}) {
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
          onPressed: () => _popupImagesMenu(model, pasteHandler),
          child: SizedBox(
            width: width,
            child: const Icon(browseIcon),
          ),
        ),
      );
    },
  );
}

void _popupImagesMenu(PfsAppModel model, VoidCallback? pasteHandler) {
  _getOpenImagesMenu(model, pasteHandler).then(
    (menu) => menu.open(
      .cursorPosition(),
      .topEnd,
    ),
  );
}

void openFolderCommandCallback(
  PfsAppModel model,
  String folderPath,
  bool includeSubfolders,
) {
  model.loadFolder(
    folderPath,
    recursive: includeSubfolders,
    resolveShortcuts: true,
  );
}

Future<Menu> _getOpenImagesMenu(
  PfsAppModel model,
  VoidCallback? pasteHandler,
) async {
  final canPasteFromClipboard = await isClipboardHasImage().timeout(
    Duration(milliseconds: 250),
    onTimeout: () => false,
  );

  Menu addBaseMenuItems(Menu menu) {
    if (pasteHandler != null) {
      menu
              .addMenuItem(
                "Paste image from clipboard",
                onClick: () => pasteHandler(),
              )
              .enabled =
          canPasteFromClipboard;
      menu.addSeparator();
    }

    menu.addMenuItemObject(
      MenuItem("Open special", .submenu)
        ..submenu = (Menu()
          ..addMenuItem(
            "Open random folder in folder...",
            onClick: model.openFilePickerForRandomFolderInFolder,
          )
          ..addMenuItem(
            "Open images...",
            onClick: model.openFilePickerForImages,
          )
          ..addMenuItem(
            "Open folder without subfolders...",
            onClick: model.openFilePickerForFolder,
          )
          ..addMenuItem(
            "Open folder without shuffling...",
            onClick: () async {
              try {
                model.shuffleOnListLoad = false;
                await model.openFilePickerForFolder();
              } finally {
                model.shuffleOnListLoad = true;
              }
            },
          )),
    );

    menu.addSeparator();
    menu.addMenuItem(
      "${windowsHotkey}Open image folder...",
      onClick: () => model.openFilePickerForFolder(includeSubfolders: true),
    );

    return menu;
  }

  Menu getBasicMenu() {
    final menu = Menu();
    addBaseMenuItems(menu);
    return menu;
  }

  try {
    final Menu menu;

    if (Platform.isMacOS) {
      final recentFolderEntries = await macos_bookmarks.getRecentFoldersList();
      if (recentFolderEntries == null || recentFolderEntries.isEmpty) {
        return getBasicMenu();
      }

      menu = Menu();
      final recentFolderEntriesCount = recentFolderEntries.length;
      int i = recentFolderEntriesCount;
      for (final entry in recentFolderEntries) {
        final folderPath = macos_bookmarks.parseEntry(entry)?.path;
        if (folderPath == null) continue;

        final shortenedPath = shortenFolderPath(folderPath);

        menu.addMenuItem(
          "$windowsHotkey$i    $shortenedPath",
          onClick: () {
            macos_bookmarks.accessRecentFolder(entry, (dir) {
              model.openFolderCommandBasic(
                folderPath: dir.path,
                includeSubfolders: true,
              );
            });
          },
        );
        i--;
      }
    } else {
      final recentFolderEntries = await pfs_preferences
          .getRecentFolders()
          .timeout(Duration(milliseconds: 1500));
      if (recentFolderEntries == null || recentFolderEntries.isEmpty) {
        return getBasicMenu();
      }

      menu = Menu();
      final recentFolderEntriesCount = recentFolderEntries.length;
      int i = recentFolderEntriesCount;
      for (final e in recentFolderEntries) {
        final shortenedPath = shortenFolderPath(e.folderPath);
        // print(i);
        // print(e.toString());
        menu.addMenuItem(
          "$windowsHotkey$i    $shortenedPath",
          onClick: () => model.openFolderCommandBasic(
            folderPath: e.folderPath,
            includeSubfolders: e.includeSubfolders,
          ),
        );
        i--;
      }
    }

    if (menu.itemCount > 0) {
      menu.addSeparator();
    }

    if (model.imageList.isPopulated) {
      final currentImage = model.getCurrentImageData();
      if (currentImage is ImageFileData) {
        if (currentImage.fileFolder.isNotEmpty) {
          menu.addMenuItem(
            PfsLocalization.reloadCurrentFolder,
            onClick: () {
              model.openFolderCommandBasic(
                folderPath: currentImage.fileFolder,
                includeSubfolders: true,
              );
            },
          );
          menu.addSeparator();
        }
      }
    }

    addBaseMenuItems(menu);
    return menu;
  } catch (e) {
    return getBasicMenu();
  }
}
