import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:tawasul/core/constants.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:tawasul/core/services/webrtc/webrtc_service.dart';
import 'package:tawasul/core/services/signaling/websocket_service.dart';

GetIt getIt = GetIt.instance;

void getItSetup() {
  // by default, signaling service will run on local host when in debug mode
  // and on remote server when in release mode
  getIt.registerSingleton<SignalingService>(
    WebSocketService(
      kDebugMode ? Constants.localUri : Constants.remoteUri,
    ),
  );

  getIt.registerSingleton<WebRTCService>(
    WebRTCService(getIt<SignalingService>()),
  );
}

void restartSignalingService(Uri uri) {
  getIt.unregister<SignalingService>();
  getIt.registerSingleton<SignalingService>(WebSocketService(uri));
}
