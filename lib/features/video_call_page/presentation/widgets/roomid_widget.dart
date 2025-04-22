import 'package:flutter/material.dart';
import 'package:tawasul/core/constants.dart';
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:tawasul/core/utils.dart';

class RoomIdWidget extends StatelessWidget {
  const RoomIdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final SignalingService signalingService = getIt<SignalingService>();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: Sizes.localVideoWidthWhenConnected),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey[350]),
                ),
                onPressed: () async {
                  await Utils.copyToClipboard(signalingService.roomId!);

                  if (context.mounted) {
                    Utils.showSnackbar(
                      context,
                      "Room ID copied to clipboard: ${signalingService.roomId}",
                    );
                  }
                },
                child: FittedBox(
                  child: Row(
                    children: [
                      Icon(Icons.copy_rounded),
                      const SizedBox(width: 10),
                      Text(
                        "${signalingService.roomId}",
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
