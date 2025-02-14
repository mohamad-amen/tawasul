import 'package:flutter/foundation.dart';
import 'package:tawasul/core/websocket_service.dart';

class WebSocketProvider extends ChangeNotifier {
  bool isConnected = false;
  bool isConnecting = true;
  bool isLocal = kDebugMode;

  void init() {
    connect();

    WebSocketService.onWebsocketClose = lostConnection;
  }

  void connect() async {
    isConnecting = true;
    notifyListeners();

    bool success = await WebSocketService.init();

    if (!success) {
      isConnected = false;
      isConnecting = false;
      notifyListeners();
      return;
    }

    connected();
  }

  void changeServer({required bool isLocal}) {
    this.isLocal = isLocal;
    WebSocketService.closeWebSocket();

    if (isLocal) {
      WebSocketService.uri = Uri(scheme: 'ws', host: '192.168.0.105', port: 8001);
    } else {
      WebSocketService.uri = Uri(scheme: 'wss', host: 'tawasul-backend.onrender.com');
    }

    connect();
  }

  void connected() {
    isConnected = true;
    isConnecting = false;
    notifyListeners();
  }

  void lostConnection() {
    isConnected = false;
    notifyListeners();
  }
}
