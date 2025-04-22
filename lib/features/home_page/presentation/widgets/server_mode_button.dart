import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/services/signaling/signaling_provider.dart';

class ServerModeButton extends StatelessWidget {
  const ServerModeButton({super.key});

  @override
  Widget build(BuildContext context) {
    SignalingProvider signalingProvider = Provider.of<SignalingProvider>(context);

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
                  color: signalingProvider.isLocal ? Colors.green : Colors.black,
                ),
              ),
              onTap: () {
                signalingProvider.changeServer(isLocal: true);
              },
            ),
            PopupMenuItem(
              child: Text(
                'Remote',
                style: TextStyle(
                  color: !signalingProvider.isLocal ? Colors.green : Colors.black,
                ),
              ),
              onTap: () {
                signalingProvider.changeServer(isLocal: false);
              },
            ),
          ];
        },
        child: Icon(Icons.developer_mode_rounded),
      ),
    );
  }
}
