import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pfs2/models/pfs_model.dart';

class LoadingSheet extends StatelessWidget {
  const LoadingSheet({
    super.key,
    required this.loadedFileCountListenable,
  });

  final ValueListenable<int> loadedFileCountListenable;

  @override
  Widget build(BuildContext context) {
    final imageListManager = PfsAppModel.of(context) as PfsImageListManager;
    final cancelNotifier = imageListManager.imageLoadingCanceledNotifier;

    return Stack(
      children: [
        ModalBarrier(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
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
              const SizedBox(height: 10),
              ValueListenableBuilder(
                valueListenable: cancelNotifier,
                builder: (context, isCanceled, child) {
                  return TextButton(
                    onPressed: isCanceled
                        ? null
                        : () => imageListManager.tryCancelLoading(),
                    child: Text("Cancel"),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
