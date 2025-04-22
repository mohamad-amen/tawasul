import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:tawasul/core/services/webrtc/webrtc_provider.dart';

class CallControlButtons extends StatefulWidget {
  const CallControlButtons({super.key});

  @override
  State<CallControlButtons> createState() => _CallControlButtonsState();
}

class _CallControlButtonsState extends State<CallControlButtons> {
  @override
  Widget build(BuildContext context) {
    WebRTCProvider webRTCProvider = Provider.of<WebRTCProvider>(context, listen: false);

    return Align(
      alignment: const Alignment(0, 0.95), // align to bottom center
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton(
            onPressed: () {
              setState(() {
                webRTCProvider.toggleMic(!webRTCProvider.isMicOn);
              });
            },
            heroTag: "Mic Button",
            child: webRTCProvider.isMicOn
                ? const Icon(Icons.mic_rounded)
                : const Icon(Icons.mic_off_rounded),
          ),
          const SizedBox(
            width: 10,
          ),
          FloatingActionButton(
            onPressed: () async {
              await webRTCProvider.closeConnection();
              final SignalingService signalingService = getIt<SignalingService>();
              signalingService.hangUp();

              webRTCProvider.isMicOn = false;
              webRTCProvider.isCameraOn = false;
              webRTCProvider.isCameraFacingFront = true;

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
                webRTCProvider.toggleCamera(!webRTCProvider.isCameraOn);
              });
            },
            heroTag: "Camera Button",
            child: webRTCProvider.isCameraOn
                ? const Icon(Icons.videocam_rounded)
                : const Icon(Icons.videocam_off_rounded),
          ),
        ],
      ),
    );
  }
}
