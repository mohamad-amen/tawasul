import 'dart:async';
import 'dart:developer';

import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'package:sdp_transform/sdp_transform.dart' as sdp_transform;
import 'package:tawasul/core/services/signaling/signaling_service.dart';

class WebRTCService {
  rtc.MediaStream? _localStream;
  rtc.RTCPeerConnection? _peerConnection;

  Completer _connectionCompleter = Completer();
  Completer _mediaGettingCompleter = Completer();

  late Function(rtc.RTCTrackEvent trackEvent) onTrack;
  late Function() onConnected;
  late Function() onDisconnected;

  late SignalingService _signalingService;

  static final Map<String, dynamic> _sdpConstraints = {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true
  };

  static final Map<String, dynamic> _iceConfiguration = {
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

  WebRTCService(SignalingService signalingService) {
    _signalingService = signalingService;

    _signalingService.onNewParticipant = () async {
      Map offerSDP = await offer();

      _signalingService.sendOfferSDP(offerSDP);
      log('posted offer');
    };

    _signalingService.onOfferSDP = (offerSDP) async {
      setRemoteSDP(offerSDP);

      Map answerSDP = await answer();

      _signalingService.sendAnswerSDP(answerSDP);
      log('posted answer');
    };

    _signalingService.onAnswerSDP = (answerSDP) {
      log('remote sdp arrived');
      setRemoteSDP(answerSDP);
    };

    _signalingService.onICE = (ice) {
      log('remote ice arrived');
      setICE(ice);
    };
  }

  Future<void> createConnection() async {
    _peerConnection = await rtc.createPeerConnection(_iceConfiguration, _sdpConstraints);

    _connectionCompleter.complete();
    log('connection created');

    initListeners();
  }

  void initListeners() {
    _peerConnection!.onTrack = onTrack;

    _peerConnection!.onIceCandidate = (candidate) {
      _signalingService.sendICE(
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

    toggleCamera(false);
    toggleMic(false);
  }

  Future<Map<String, dynamic>> offer() async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    if (!_mediaGettingCompleter.isCompleted) await _mediaGettingCompleter.future;
    // if there is connection and we got user media then procced to create offer

    rtc.RTCSessionDescription offerSDP = await _peerConnection!.createOffer(_sdpConstraints);

    await _peerConnection!.setLocalDescription(offerSDP);

    log('created offer sdp');

    return sdp_transform.parse(offerSDP.sdp!);
  }

  Future<Map<String, dynamic>> answer() async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    if (!_mediaGettingCompleter.isCompleted) await _mediaGettingCompleter.future;
    // if there is connection and we got user media then procced to create answer

    rtc.RTCSessionDescription answerSDP = await _peerConnection!.createAnswer(_sdpConstraints);

    await _peerConnection!.setLocalDescription(answerSDP);

    log('created answer sdp');

    return sdp_transform.parse(answerSDP.sdp!);
  }

  Future<void> setRemoteSDP(Map sdp) async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    // if there is connection procced to set remote sdp

    String sdpString = sdp_transform.write(sdp['sdp'], null);

    rtc.RTCSessionDescription remoteSDP = rtc.RTCSessionDescription(sdpString, sdp["sdpType"]);

    await _peerConnection!.setRemoteDescription(remoteSDP);

    log('remote sdp was set');
  }

  void setICE(Map ice) async {
    if (!_connectionCompleter.isCompleted) await _connectionCompleter.future;
    // if there is connection procced to set remote ice

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
    _connectionCompleter = Completer();
    _mediaGettingCompleter = Completer();

    onDisconnected();

    log('connection closed');
  }

  Future<rtc.MediaStream> getMedia() async {
    Map<String, dynamic> mediaConstraints = {"audio": true, "video": true};

    _localStream = await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localStream!.getTracks().forEach(
      (track) async {
        await _peerConnection?.addTrack(track, _localStream!);
        log('added new local track');
      },
    );

    if (!_mediaGettingCompleter.isCompleted) _mediaGettingCompleter.complete();

    return _localStream!;
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

  Future<rtc.MediaStream> resumeMedia(bool isCameraFacingFront) async {
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

      return _localStream!;
    } catch (error) {
      log(error.toString());
      return resumeMedia(isCameraFacingFront);
    }
  }
}
