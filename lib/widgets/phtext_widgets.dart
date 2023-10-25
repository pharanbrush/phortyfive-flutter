import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/ui/themes/pfs_theme.dart';
import 'package:url_launcher/url_launcher_string.dart';

class HyperlinkRichText extends StatefulWidget {
  const HyperlinkRichText(
    this.text, {
    super.key,
    required this.urlText,
    required this.url,
  });

  final String text;
  final String urlText;
  final String url;

  @override
  State<HyperlinkRichText> createState() => _HyperlinkRichTextState();
}

class _HyperlinkRichTextState extends State<HyperlinkRichText> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: widget.text,
        children: [
          TextSpan(
            style: _isHovered
                ? const TextStyle(color: PfsTheme.hyperlinkColorHovered)
                : const TextStyle(color: PfsTheme.hyperlinkColorPassive),
            text: widget.urlText,
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                await launchUrlString(widget.url);
              },
            onEnter: (_) => setState(() => _isHovered = true),
            onExit: (_) => setState(() => _isHovered = false),
          )
        ],
      ),
    );
  }
}

class SmallHeading extends StatelessWidget {
  const SmallHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final smallHeadingStyle = Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: smallHeadingStyle),
    );
  }
}
