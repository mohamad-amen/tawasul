import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/services/signaling/signaling_provider.dart';
import 'package:tawasul/features/home_page/presentation/widgets/server_mode_button.dart';

class NoConnectionPage extends StatelessWidget {
  const NoConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SignalingProvider signalingProvider =
        Provider.of<SignalingProvider>(context, listen: false);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.amberAccent),
                  ),
                  onPressed: () {
                    signalingProvider.connect();
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Try refreshing the page",
                        style: TextStyle(color: Colors.black),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.refresh_rounded,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 60),
                  Text(
                    "Something went wrong! we couldn't connect to the server :(",
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ServerModeButton(),
    );
  }
}
