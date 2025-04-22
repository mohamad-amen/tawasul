import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:tawasul/core/services/webrtc/webrtc_service.dart';

class WebRTCProvider extends ChangeNotifier {
  rtc.RTCVideoRenderer remoteRenderer = rtc.RTCVideoRenderer();
  rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();

  bool isCameraFacingFront = true;
  bool isCameraOn = false;
  bool isMicOn = false;
  bool isConnected = false;

  final WebRTCService _webRTCService = getIt<WebRTCService>();

  WebRTCProvider() {
    _webRTCService.onConnected = () {
      isConnected = true;
      notifyListeners();
    };

    _webRTCService.onDisconnected = () {
      isConnected = false;
      notifyListeners();
    };

    _webRTCService.onTrack = (trackEvent) {
      remoteRenderer.srcObject = trackEvent.streams[0];
      isConnected = true;
      notifyListeners();

      log("Remote stream added (onTrack)");
    };

    getIt<SignalingService>().onOtherParticipantDisconnected = () async {
      isConnected = false;
      await reCreateConnection();
      notifyListeners();
    };
  }

  Future<void> createConnection() async {
    localRenderer = rtc.RTCVideoRenderer();
    await localRenderer.initialize();

    remoteRenderer = rtc.RTCVideoRenderer();
    await remoteRenderer.initialize();

    await _webRTCService.createConnection();
    rtc.MediaStream localStream = await _webRTCService.getMedia();

    localRenderer.srcObject = localStream;
    notifyListeners();

    _webRTCService.toggleCamera(false);
    _webRTCService.toggleMic(false);
  }

  Future<void> reCreateConnection() async {
    await _webRTCService.closeConnection();

    await createConnection();

    toggleCamera(isCameraOn);
    toggleMic(isMicOn);
  }

  Future<void> closeConnection() async {
    await remoteRenderer.dispose();
    await localRenderer.dispose();
    await _webRTCService.closeConnection();
  }

  Future<void> switchCamera() async {
    await _webRTCService.switchCamera();
    isCameraFacingFront = !isCameraFacingFront;
    notifyListeners();
  }

  void toggleMic(bool turnOn) async {
    isMicOn = turnOn;
    _webRTCService.toggleMic(turnOn);
  }

  void toggleCamera(bool turnOn) async {
    isCameraOn = turnOn;
    _webRTCService.toggleCamera(turnOn);
  }

  void stopMedia() {
    _webRTCService.stopMedia();
  }

  Future<void> resumeMedia() async {
    rtc.MediaStream localStream = await _webRTCService.resumeMedia(isCameraFacingFront);

    localRenderer = rtc.RTCVideoRenderer();
    await localRenderer.initialize();

    toggleCamera(isCameraOn);
    toggleMic(isMicOn);

    localRenderer.srcObject = localStream;
    notifyListeners();
  }
}
