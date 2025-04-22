import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/constants.dart';
import 'package:tawasul/core/services/webrtc/webrtc_provider.dart';

class LocalVideoView extends StatefulWidget {
  const LocalVideoView({super.key});

  @override
  State<LocalVideoView> createState() => _LocalVideoViewState();
}

class _LocalVideoViewState extends State<LocalVideoView> {
  @override
  Widget build(BuildContext context) {
    WebRTCProvider webRTCProvider = Provider.of<WebRTCProvider>(context);

    double localVideoWidth = webRTCProvider.isConnected
        ? Sizes.localVideoWidthWhenConnected
        : MediaQuery.of(context).size.width;

    double localVideoHeight = webRTCProvider.isConnected
        ? Sizes.localVideoHeightWhenConnected
        : MediaQuery.of(context).size.height;

    double borderRadius = webRTCProvider.isConnected ? 10 : 0;

    return Align(
      alignment: Alignment.topLeft,
      child: SafeArea(
        top: webRTCProvider.isConnected,
        child: AnimatedContainer(
          width: localVideoWidth,
          height: localVideoHeight,
          padding: EdgeInsets.all(webRTCProvider.isConnected ? 8 : 0),
          duration: const Duration(milliseconds: 500),
          child: Container(
            decoration: webRTCProvider.isConnected
                ? BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(borderRadius),
                  )
                : null,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Stack(
                children: [
                  RTCVideoView(
                    webRTCProvider.localRenderer,
                    mirror: webRTCProvider.isCameraFacingFront,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                  SafeArea(
                    child: Align(
                      alignment: Alignment(-1, -1),
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Visibility(
                          visible:
                              (webRTCProvider.localRenderer.srcObject == null ? false : true) &&
                                  !kIsWeb,
                          child: IconButton(
                            onPressed: () async {
                              if (kIsWeb) return;

                              await webRTCProvider.switchCamera();
                              setState(() {
                                webRTCProvider.isCameraFacingFront =
                                    !webRTCProvider.isCameraFacingFront;
                              });
                            },
                            icon: Icon(
                              Icons.cameraswitch_rounded,
                              size: 30,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
