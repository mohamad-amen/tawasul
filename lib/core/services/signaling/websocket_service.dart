import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService implements SignalingService {
  @override
  String? participantId;
  @override
  String? roomId;

  @override
  late Function(Map response) onCreateRoom;
  @override
  late Function(Map response) onJoinRoom;
  @override
  late Function(Map offerSDP) onOfferSDP;
  @override
  late Function(Map answerSDP) onAnswerSDP;
  @override
  late Function(Map ice) onICE;
  @override
  late Function() onNewParticipant;
  @override
  late Function() onOtherParticipantDisconnected;
  @override
  late Function() onServerClosed;

  late WebSocketChannel websocket;

  late Uri uri;

  WebSocketService(this.uri);

  @override
  Future<bool> connect() async {
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

  void _listenToStream() {
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
      onDone: onServerClosed,
    );
  }

  void _sendMessage(Map messageData) {
    String message = jsonEncode(messageData);

    websocket.sink.add(message);
  }

  @override
  Future<void> createRoom() async {
    _sendMessage({"type": 'createRoom'});
  }

  @override
  Future<void> joinRoom(String roomId) async {
    _sendMessage({"type": "joinRoom", 'roomId': roomId});
  }

  @override
  Future<void> sendOfferSDP(Map offerSDP) async {
    _sendMessage({'type': 'offerSDP', 'sdpType': 'offer', 'sdp': offerSDP});
  }

  @override
  Future<void> sendAnswerSDP(Map answerSDP) async {
    _sendMessage({'type': 'answerSDP', 'sdpType': 'answer', 'sdp': answerSDP});
  }

  @override
  Future<void> sendICE(Map ice) async {
    _sendMessage({'type': 'ice', 'ice': ice});
  }

  @override
  Future<void> hangUp() async {
    _sendMessage({"type": 'hangup'});

    roomId = null;
    participantId = null;
  }

  @override
  Future<void> disconnect() async {
    await websocket.sink.close();
  }
}
