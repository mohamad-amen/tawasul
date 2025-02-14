import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:keep_screen_on/keep_screen_on.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/features/video_call_page/domain/rtc_provider.dart';
import 'package:tawasul/features/video_call_page/presentation/widgets/call_control_buttons.dart';
import 'package:tawasul/features/video_call_page/presentation/widgets/roomid_widget.dart';
import 'package:tawasul/features/video_call_page/presentation/widgets/local_video_view.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with WidgetsBindingObserver {
  late RTCProvider rtcProvider;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) KeepScreenOn.turnOn();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    super.dispose();
    if (!kIsWeb) KeepScreenOn.turnOff();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      rtcProvider.stopMedia();
      log("media stopped");
    } else if (state == AppLifecycleState.resumed && !kIsWeb) {
      rtcProvider.resumeMedia();
      log("media resumed");
    }
  }

  @override
  Widget build(BuildContext context) {
    rtcProvider = Provider.of<RTCProvider>(context);

    return Scaffold(
      body: Stack(
        children: [
          RTCVideoView(
            rtcProvider.remoteRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          LocalVideoView(),
          RoomIdWidget(),
          CallControlButtons(),
        ],
      ),
    );
  }
}
