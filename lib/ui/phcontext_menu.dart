import 'package:flutter/material.dart';

class PhcontextMenu {
  static const _textStyle = TextStyle(fontSize: 12);
  static const _itemPadding = EdgeInsets.symmetric(vertical: 0, horizontal: 5);

  static MenuItemButton menuItemButton(
      {required String text, IconData? icon, Function()? onPressed}) {
    return MenuItemButton(
      onPressed: onPressed,
      child: SizedBox(
        width: 230,
        child: Padding(
          padding: _itemPadding,
          child: Row(
            children: [
              SizedBox(
                width: 30,
                child: Row(children: [
                  if (icon != null)
                    Icon(
                      icon,
                      size: 18,
                    ),
                  const SizedBox(
                    width: 5,
                  ),
                ]),
              ),
              Text(
                text,
                style: _textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
