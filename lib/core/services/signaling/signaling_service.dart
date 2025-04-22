abstract class SignalingService {
  // prams
  String? participantId;
  String? roomId;

  // connection management
  Future<bool> connect();
  Future<void> disconnect();

  // room management
  Future<void> createRoom();
  Future<void> joinRoom(String roomId);
  Future<void> hangUp();

  // signaling functions
  Future<void> sendOfferSDP(Map offerSDP);
  Future<void> sendAnswerSDP(Map answerSDP);
  Future<void> sendICE(Map ice);

  // callbacks
  late Function(Map response) onCreateRoom;
  late Function(Map response) onJoinRoom;
  late Function(Map offerSDP) onOfferSDP;
  late Function(Map answerSDP) onAnswerSDP;
  late Function(Map ice) onICE;
  late Function() onNewParticipant;
  late Function() onOtherParticipantDisconnected;
  late Function() onServerClosed;
}
