import 'package:flutter/widgets.dart';

class CenteredVertically extends StatelessWidget {
  const CenteredVertically({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: SizedBox()),
        Center(child: child),
        Expanded(child: SizedBox()),
      ],
    );
  }
}
