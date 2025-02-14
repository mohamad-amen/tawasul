import 'package:flutter/material.dart';
import 'package:tawasul/core/constants.dart';
import 'package:tawasul/core/utils.dart';
import 'package:tawasul/core/websocket_service.dart';

class RoomIdWidget extends StatelessWidget {
  const RoomIdWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(width: Constants.localVideoWidthWhenConnected),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.grey[350]),
                ),
                onPressed: () async {
                  await Utils.copyToClipboard(WebSocketService.roomId!);

                  if (context.mounted) {
                    Utils.showSnackbar(
                      context,
                      "Room ID copied to clipboard: ${WebSocketService.roomId}",
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(Icons.copy_rounded),
                    const SizedBox(width: 10),
                    Text(
                      "${WebSocketService.roomId}",
                      style: TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
