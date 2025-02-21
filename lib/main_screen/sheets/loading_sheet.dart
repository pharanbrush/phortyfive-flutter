import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class LoadingSheet extends StatelessWidget {
  const LoadingSheet({
    super.key,
    required this.loadedFileCountListenable,
  });

  final ValueListenable<int> loadedFileCountListenable;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ModalBarrier(
          color: Theme.of(context).colorScheme.surface.withOpacity(0.9),
          dismissible: false,
        ),
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: loadedFileCountListenable,
                builder: (_, value, __) {
                  return Text("Listing $value images...");
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
