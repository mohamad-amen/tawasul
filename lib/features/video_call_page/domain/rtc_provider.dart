import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;
import 'package:tawasul/core/websocket_service.dart';

class RTCProvider extends ChangeNotifier {
  rtc.RTCVideoRenderer remoteRenderer = rtc.RTCVideoRenderer();
  rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();

  rtc.RTCPeerConnection? _peerConnection;
  rtc.MediaStream? _localStream;

  Completer _connectionCompleter = Completer();
  Completer _mediaGettingCompleter = Completer();

  bool isCameraFacingFront = true;
  bool isCameraOn = false;
  bool isMicOn = false;

  bool isConnected = false;

  static final Map<String, dynamic> _sdpConstraints = {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true
  };

  RTCProvider() {
    WebSocketService.onNewParticipant = () async {
      Map offerSDP = await offer();

      WebSocketService.postOfferSDP(offerSDP);
      log('posted offer');
    };

    WebSocketService.onOfferSDP = (offerSDP) async {
      setRemoteSDP(offerSDP);

      Map answerSDP = await answer();

      WebSocketService.postAnswerSDP(answerSDP);
      log('posted answer');
    };

    WebSocketService.onAnswerSDP = (answerSDP) {
      log('remote sdp arrived');
      setRemoteSDP(answerSDP);
    };

    WebSocketService.onICE = (ice) {
      log('remote ice arrived');
      setICE(ice);
    };

    WebSocketService.onOtherParticipantDisconnected = () {
      isConnected = false;
      reCreateConnection();
    };
  }

  Future<void> createConnection() async {
    Map<String, dynamic> iceConfiguration = {
      "sdpSemantics": "unified-plan",
      "iceServers": [
        {"url": "stun:stun.l.google.com:19302"},
        {"urls": "stun:openrelay.metered.ca:80"},
        {
          "urls": "turn:openrelay.metered.ca:80",
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
        {
          "urls": "turn:openrelay.metered.ca:443",
          "username": "openrelayproject",
          "credential": "openrelayproject",
        }
      ]
    };

    _peerConnection = await rtc.createPeerConnection(iceConfiguration, _sdpConstraints);

    remoteRenderer = rtc.RTCVideoRenderer();
    await remoteRenderer.initialize();

    _connectionCompleter.complete();
    notifyListeners();
    log('connection created');

    _peerConnection!.onTrack = (trackEvent) {
      remoteRenderer.srcObject = trackEvent.streams[0];
      isConnected = true;
      notifyListeners();

      log("Remote stream added (onTrack)");
    };

    _peerConnection!.onIceCandidate = (candidate) {
      WebSocketService.postICE(
        {
          "candidate": candidate.candidate,
          "sdpMLineIndex": candidate.sdpMLineIndex,
          "sdpMid": candidate.sdpMid
        },
      );
    };

    _peerConnection!.onIceConnectionState = (state) {
      log('IceConnectionState: $state');
    };
  }

  void reCreateConnection() async {
    await closeConnection();
    await createConnection();
    await getMedia();

    toggleCamera(isCameraOn);
    toggleMic(isMicOn);
  }

  Future<Map<String, dynamic>> offer() async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    if (!_mediaGettingCompleter.isCompleted) await _mediaGettingCompleter.future;

    rtc.RTCSessionDescription offerSDP = await _peerConnection!.createOffer(_sdpConstraints);

    await _peerConnection!.setLocalDescription(offerSDP);

    log('created offer sdp');

    return sdp_transform.parse(offerSDP.sdp!);
  }

  Future<Map<String, dynamic>> answer() async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    if (!_mediaGettingCompleter.isCompleted) await _mediaGettingCompleter.future;

    rtc.RTCSessionDescription answerSDP = await _peerConnection!.createAnswer(_sdpConstraints);

    await _peerConnection!.setLocalDescription(answerSDP);

    log('created answer sdp');

    return sdp_transform.parse(answerSDP.sdp!);
  }

  Future<void> setRemoteSDP(Map<String, dynamic> sdp) async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;

    String sdpString = sdp_transform.write(sdp['sdp'], null);

    rtc.RTCSessionDescription remoteSDP = rtc.RTCSessionDescription(sdpString, sdp["sdpType"]);

    await _peerConnection!.setRemoteDescription(remoteSDP);

    log('remote sdp was set');
  }

  void setICE(Map ice) async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;

    rtc.RTCIceCandidate rtcCandidate = rtc.RTCIceCandidate(
      ice["candidate"],
      ice["sdpMid"],
      ice["sdpMLineIndex"],
    );

    _peerConnection!.addCandidate(rtcCandidate);
  }

  Future<void> closeConnection() async {
    await _peerConnection!.close();
    await _peerConnection!.dispose();
    await remoteRenderer.dispose();
    await localRenderer.dispose();
    _connectionCompleter = Completer();
    _mediaGettingCompleter = Completer();

    isConnected = false;

    log('connection closed');
  }

  Future<void> getMedia() async {
    Map<String, dynamic> mediaConstraints = {"audio": true, "video": true};

    _localStream = await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localStream!.getTracks().forEach(
      (track) async {
        await _peerConnection?.addTrack(track, _localStream!);
        log('added new local track');
      },
    );

    if (!_mediaGettingCompleter.isCompleted) _mediaGettingCompleter.complete();

    localRenderer = rtc.RTCVideoRenderer();
    await localRenderer.initialize();

    localRenderer.srcObject = _localStream;
    notifyListeners();
  }

  void toggleCamera(turnOn) {
    _localStream!.getVideoTracks()[0].enabled = turnOn;
  }

  void toggleMic(turnOn) {
    _localStream!.getAudioTracks()[0].enabled = turnOn;
  }

  Future<void> switchCamera() async {
    _localStream!.getVideoTracks().forEach(
      (track) async {
        await rtc.Helper.switchCamera(track);
      },
    );

    //because it takes time before flipping camera
    await Future.delayed(Duration(milliseconds: 600));
  }

  void stopMedia() {
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
  }

  //TODO: manage audio muting after resuming media
  void resumeMedia() async {
    String facingMode = isCameraFacingFront ? 'user' : 'environment';

    Map<String, dynamic> mediaConstraints = {
      "audio": true,
      "video": {'facingMode': facingMode}
    };

    try {
      _localStream = await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

      _localStream?.getTracks().forEach((newTrack) async {
        final kind = newTrack.kind; // "video" or "audio"
        var senders = await _peerConnection?.getSenders();

        senders?.forEach((sender) {
          if (sender.track?.kind == kind) {
            sender.replaceTrack(newTrack);
          }
        });
      });

      localRenderer = rtc.RTCVideoRenderer();
      await localRenderer.initialize();

      toggleCamera(isCameraOn);
      toggleMic(isMicOn);

      localRenderer.srcObject = _localStream;
      notifyListeners();
    } catch (error) {
      log(error.toString());
      resumeMedia();
    }
  }
}
