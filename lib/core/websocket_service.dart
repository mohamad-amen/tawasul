import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  static String? participantId;
  static String? roomId;

  static late Uri uri;

  static late WebSocketChannel websocket;

  static late Function(Map response) onCreateRoom;
  static late Function(Map response) onJoinRoom;
  static late Function onNewParticipant;
  static late Function onOfferSDP;
  static late Function onAnswerSDP;
  static late Function onICE;
  static late Function onOtherParticipantDisconnected;

  static late Function() onWebsocketClose;

  static Future<bool> init() async {
    uri = kDebugMode
        ? Uri(scheme: 'wss', host: 'tawasul-backend.onrender.com')
        : Uri(scheme: 'ws', host: '192.168.0.105', port: 8001);
    websocket = WebSocketChannel.connect(uri);

    try {
      await websocket.ready;
      _listenToStream();
      return true;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }

  static void _listenToStream() {
    websocket.stream.listen(
      (messageString) {
        log("recieved: $messageString");
        Map message = jsonDecode(messageString);

        switch (message['type']) {
          case "participantId":
            participantId = message["participantId"];
            log("participantId set: $participantId");
            break;

          case 'createRoom':
            onCreateRoom(message);
            break;

          case 'joinRoom':
            onJoinRoom(message);
            break;

          case 'newParticipant':
            onNewParticipant();
            break;

          case 'offerSDP':
            onOfferSDP(message);
            break;

          case 'answerSDP':
            onAnswerSDP(message);
            break;

          case 'ice':
            onICE(message['ice']);
            break;

          case 'otherParticipantDisconnected':
            onOtherParticipantDisconnected();
            break;
        }
      },
      onDone: onWebsocketClose,
    );
  }

  static void createRoom() {
    String message = jsonEncode({"type": 'createRoom'});

    websocket.sink.add(message);
  }

  static void joinRoom(String roomId) {
    String message = jsonEncode({"type": "joinRoom", 'roomId': roomId});

    websocket.sink.add(message);
  }

  static void postOfferSDP(Map offerSDP) {
    String message = jsonEncode({'type': 'offerSDP', 'sdpType': 'offer', 'sdp': offerSDP});

    websocket.sink.add(message);
  }

  static void postAnswerSDP(Map answerSDP) async {
    String message = jsonEncode({'type': 'answerSDP', 'sdpType': 'answer', 'sdp': answerSDP});

    websocket.sink.add(message);
  }

  static void postICE(Map ice) {
    String message = jsonEncode({'type': 'ice', 'ice': ice});

    websocket.sink.add(message);
  }

  static void hangUp() {
    String message = jsonEncode({"type": 'hangup'});

    websocket.sink.add(message);

    roomId = null;
    participantId = null;
  }

  static void closeWebSocket() {
    websocket.sink.close();
  }
}
