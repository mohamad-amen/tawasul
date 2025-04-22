import 'package:flutter/foundation.dart';
import 'package:tawasul/core/constants.dart';
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';

class SignalingProvider extends ChangeNotifier {
  bool isConnected = false;
  bool isConnecting = true;
  bool isLocal = kDebugMode;

  final SignalingService _signalingService = getIt<SignalingService>();

  void init() {
    connect();

    _signalingService.onServerClosed = () => setConnected(false);
  }

  void connect() async {
    isConnecting = true;
    notifyListeners();

    bool success = await _signalingService.connect();

    if (!success) {
      setConnected(false);
      return;
    }

    setConnected(true);
  }

  void disconnect() {
    _signalingService.disconnect();
    setConnected(false);
  }

  void changeServer({required bool isLocal}) {
    disconnect();

    this.isLocal = isLocal;

    if (isLocal) {
      restartSignalingService(Constants.localUri);
    } else {
      restartSignalingService(Constants.remoteUri);
    }

    connect();
  }

  void setConnected(bool isConnected) {
    this.isConnected = isConnected;
    isConnecting = false;
    notifyListeners();
  }
}
