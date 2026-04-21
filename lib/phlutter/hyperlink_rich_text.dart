import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

const Color hyperlinkColorPassive = Color.fromARGB(255, 84, 201, 255);
const Color hyperlinkColorHovered = Colors.blue;

class HyperlinkRichText extends StatefulWidget {
  const HyperlinkRichText({
    super.key,
    this.text,
    required this.urlText,
    required this.url,
    this.hoveredTextStyle,
    this.unhoveredTextStyle,
  });

  final String? text;
  final String urlText;
  final String url;
  final TextStyle? hoveredTextStyle;
  final TextStyle? unhoveredTextStyle;

  @override
  State<HyperlinkRichText> createState() => _HyperlinkRichTextState();
}

class _HyperlinkRichTextState extends State<HyperlinkRichText> {
  bool _isHovered = false;
  late final tapGestureRecognizer = TapGestureRecognizer()
    ..onTap = () async {
      await launchUrlString(widget.url);
    };

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: widget.text,
        children: [
          TextSpan(
            style: _isHovered
                ? widget.hoveredTextStyle ??
                      const TextStyle(color: hyperlinkColorHovered)
                : widget.unhoveredTextStyle ??
                      const TextStyle(color: hyperlinkColorPassive),
            text: widget.urlText,
            recognizer: tapGestureRecognizer,
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
          ),
        ],
      ),
    );
  }
}
