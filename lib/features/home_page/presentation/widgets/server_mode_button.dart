import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/features/home_page/presentation/domain/websocket_provider.dart';

class ServerModeButton extends StatelessWidget {
  const ServerModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    WebSocketProvider websocketProvider = Provider.of<WebSocketProvider>(context);

    return Visibility(
      visible: kDebugMode,
      child: PopupMenuButton(
        tooltip: "Server Mode",
        itemBuilder: (context) {
          return [
            PopupMenuItem(
              child: Text(
                'Localhost',
                style: TextStyle(
                  color: websocketProvider.isLocal ? Colors.green : Colors.black,
                ),
              ),
              onTap: () {
                websocketProvider.changeServer(isLocal: true);
              },
            ),
            PopupMenuItem(
              child: Text(
                'Remote',
                style: TextStyle(
                  color: !websocketProvider.isLocal ? Colors.green : Colors.black,
                ),
              ),
              onTap: () {
                websocketProvider.changeServer(isLocal: false);
              },
            ),
          ];
        },
        child: Icon(Icons.developer_mode_rounded),
      ),
    );
  }
}
