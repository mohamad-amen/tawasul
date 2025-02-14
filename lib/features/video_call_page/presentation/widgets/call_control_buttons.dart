import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/websocket_service.dart';
import 'package:tawasul/features/video_call_page/domain/rtc_provider.dart';

class CallControlButtons extends StatefulWidget {
  const CallControlButtons({super.key});

  @override
  State<CallControlButtons> createState() => _CallControlButtonsState();
}

class _CallControlButtonsState extends State<CallControlButtons> {
  @override
  Widget build(BuildContext context) {
    RTCProvider rtcProvider = Provider.of<RTCProvider>(context, listen: false);

    return Align(
      alignment: const Alignment(0, 0.95), // align to bottom center
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                rtcProvider.isMicOn = !rtcProvider.isMicOn;
                rtcProvider.toggleMic(rtcProvider.isMicOn);
              });
            },
            heroTag: "Mic Button",
            child: rtcProvider.isMicOn
                ? const Icon(Icons.mic_rounded)
                : const Icon(Icons.mic_off_rounded),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              await rtcProvider.closeConnection();
              WebSocketService.hangUp();

              rtcProvider.isMicOn = false;
              rtcProvider.isCameraOn = false;
              rtcProvider.isCameraFacingFront = true;

              if (context.mounted) Navigator.pop(context);
            },
            heroTag: "HangUp Button",
            backgroundColor: Colors.red,
            child: const Icon(Icons.phone_disabled_rounded),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () {
              setState(() {
                rtcProvider.isCameraOn = !rtcProvider.isCameraOn;
                rtcProvider.toggleCamera(rtcProvider.isCameraOn);
              });
            },
            heroTag: "Camera Button",
            child: rtcProvider.isCameraOn
                ? const Icon(Icons.videocam_rounded)
                : const Icon(Icons.videocam_off_rounded),
          ),
        ],
      ),
    );
  }
}
