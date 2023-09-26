import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/core/file_list.dart';
import 'package:window_manager/window_manager.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Color backgroundColor = Colors.white;
  final Color accentColor = Colors.blueAccent;
  final FileList fileList = FileList();
  bool rightOrientation = true;
  int fileCount = 0;
  bool isAlwaysOnTop = false;
  bool isSoundsEnabled = true;
  bool isTouch = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Stack(
        children: [
          _imageViewer(),
          _topRightWindowControls(),
          _bottomBar(),
          _dockingControls(),
        ],
      ),
    );
  }

  void openFiles() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      //type: FileType.image,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'webp', 'png', 'jpeg', 'jfif', 'gif'],
    );

    if (result == null) return;

    fileList.load(result.paths);
    setState(() {
      fileCount = fileList.getCount();
    });
  }

  Widget _topRightWindowControls() {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Opacity(
        opacity: 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Phbuttons.topControl(() => _toggleSounds(),
                isSoundsEnabled ? Icons.volume_up : Icons.volume_off, 'Sounds'),
            Phbuttons.topControl(
                () => _toggleAlwaysOnTop(),
                isAlwaysOnTop
                    ? Icons.push_pin_rounded
                    : Icons.push_pin_outlined,
                'Keep Window on Top'),
            Phbuttons.topControl(() {}, Icons.help_rounded, 'Help...'),
            Phbuttons.topControl(() {}, Icons.info_outline_rounded, 'About...'),
          ],
        ),
      ),
    );
  }

  void _toggleAlwaysOnTop() {
    setState(() {
      isAlwaysOnTop = !isAlwaysOnTop;
      windowManager.setAlwaysOnTop(isAlwaysOnTop);
    });
  }

  void _toggleSounds() {
    setState(() {
      isSoundsEnabled = !isSoundsEnabled;
    });
  }

  Widget _imageViewer() {
    const defaultImage = 'C:/Projects/pfs2/assets/83131sf5043558883378.png';
    final FileData imageFileData = fileList.isPopulated()
        ? fileList.getFirst()
        : FileList.fileDataFromPath(defaultImage);

    final File imageFile = File(imageFileData.filePath);

    final style = TextStyle(
      color: Colors.grey.shade500,
      fontSize: 11,
    );
    var topText = Text(imageFileData.fileName, style: style);
    const opacity = 0.3;

    return Padding(
      padding: const EdgeInsets.only(bottom: 43),
      child: Stack(
        children: [
          Center(
            child: Image.file(
              imageFile,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Material(
              color: Colors.transparent,
              child: Opacity(opacity: opacity, child: topText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Positioned(
      bottom: 0,
      right: 10,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withAlpha(10),
        ),
        child: Opacity(
          opacity: 0.4,
          child: Row(
            children: [
              //_bottomButton(() => null, Icons.swap_horiz, 'Flip controls'), // Do this in the settings menu
              _imageSetStats(),
              const SizedBox(width: 15),
              PopupMenuButton(
                itemBuilder: _settingsMenuItemBuilder,
                tooltip: 'Options',
              ),
              const SizedBox(width: 15),
              _timerControls(),
              const SizedBox(width: 15),
              Phbuttons.openFiles(() => openFiles()),
              const SizedBox(width: 15),
            ],
          ),
        ),
      ),
    );
  }

  List<PopupMenuEntry<dynamic>> _settingsMenuItemBuilder(context) {
    double height = isTouch ? kMinInteractiveDimension : 32;

    return [
      PopupMenuItem(
        enabled: false,
        height: height,
        child: const Text('Timer Duration'),
      ),
      PopupMenuDivider(height: height),
      PopupMenuItem(height: height, child: const Text('15 seconds')),
      PopupMenuItem(height: height, child: const Text('30 seconds')),
      PopupMenuItem(height: height, child: const Text('45 seconds')),
      PopupMenuItem(height: height, child: const Text('1 minute')),
      PopupMenuDivider(height: height),
      PopupMenuItem(height: height, child: const Text('Custom...')),
    ];
  }

  Widget _dockingControls() {
    return Positioned(
      bottom: 3,
      right: 3,
      child: Phbuttons.collapseBottomBarButton(() {}),
    );
  }

  Widget _timeElapsedBar(double width) {
    return SizedBox(
      width: width,
      height: 2,
      child: const LinearProgressIndicator(
        backgroundColor: Colors.black12,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        value: 0.25,
      ),
    );
  }

  Widget _timerControls() {
    return Column(children: [
      _timeElapsedBar(200),
      Row(
        children: [
          Phbuttons.timerControl(() {}, Icons.refresh, 'Restart Timer (R)'),
          Phbuttons.timerControl(
              () {}, Icons.skip_previous, 'Previous Image (K)'),
          Phbuttons.playPauseTimer(() {}),
          Phbuttons.timerControl(() {}, Icons.skip_next, 'Next Image (J)'),
        ],
      )
    ]);
  }

  Widget _imageSetStats() {
    String message =
        '$fileCount ${fileCount == 1 ? 'image' : 'images'} loaded : 45 seconds each';
    final style = TextStyle(color: Colors.grey.shade800);

    var text = Text(message, style: style);

    return Opacity(
      opacity: 0.7,
      child: Material(
        color: Colors.transparent,
        child: text,
      ),
    );
  }
}

class Phbuttons {
  static const Color accentColor = Colors.blueAccent;
  static const Color topBarButtonColor = Colors.black12;

  static Widget topControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    const double buttonSpacing = 5;
    const double iconSize = 20;
    const size = Size(25, 25);
    final style = TextButton.styleFrom(
      minimumSize: size,
      maximumSize: size,
      padding: const EdgeInsets.all(0),
    );

    return Container(
      margin: const EdgeInsets.only(right: buttonSpacing),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        color: topBarButtonColor,
        tooltip: tooltip,
        style: style,
      ),
    );
  }

  static Widget timerControl(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget bottomButton(
      Function()? onPressed, IconData icon, String? tooltip) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      focusColor: const Color(0xFFFFE4C0),
    );
  }

  static Widget playPauseTimer(Function()? onPressed) {
    const toolTipText = 'Pause/Resume Timer (P)';
    const playIcon = Icon(Icons.play_arrow);
    // ignore: unused_local_variable
    const pauseIcon = Icon(Icons.pause);
    var style = FilledButton.styleFrom(backgroundColor: accentColor);

    return Tooltip(
      message: toolTipText,
      child: FilledButton(
        style: style,
        onPressed: onPressed,
        child: const SizedBox(
          width: 50,
          child: playIcon,
        ),
      ),
    );
  }

  static Widget openFiles(Function()? onPressed) {
    const toolTipText = 'Open files... (Ctrl+O)';
    const color = Colors.black54;

    return Tooltip(
      message: toolTipText,
      child: TextButton(
        onPressed: onPressed,
        child: const SizedBox(
          width: 40,
          child: Icon(
            Icons.folder_open,
            color: color,
          ),
        ),
      ),
    );
  }

  static Widget collapseBottomBarButton(Function()? onPressed) {
    const buttonSize = Size(25, 25);

    const collapseIcon = Icons.keyboard_double_arrow_down_rounded;
    const iconColor = Colors.black38;

    const double iconSize = 20;

    final style = TextButton.styleFrom(
      minimumSize: buttonSize,
      maximumSize: buttonSize,
      padding: const EdgeInsets.all(0),
    );

    return Tooltip(
      message: 'Collapse controls',
      child: TextButton(
        style: style,
        onPressed: onPressed,
        child: const Icon(
          collapseIcon,
          size: iconSize,
          color: iconColor,
        ),
      ),
    );
  }
}
