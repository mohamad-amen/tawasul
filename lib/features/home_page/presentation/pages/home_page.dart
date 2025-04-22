import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_service.dart';
import 'package:tawasul/core/utils.dart';
import 'package:tawasul/core/services/signaling/signaling_provider.dart';
import 'package:tawasul/features/home_page/presentation/pages/no_connection_page.dart';
import 'package:tawasul/features/home_page/presentation/widgets/server_mode_button.dart';
import 'package:tawasul/core/services/webrtc/webrtc_provider.dart';
import 'package:tawasul/features/home_page/presentation/widgets/devider_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final WebRTCProvider webRTCProvider;
  late SignalingProvider signalingProvider;

  bool isJoiningRoom = false;
  bool isCreatingRoom = false;

  TextEditingController roomIdField = TextEditingController();

  SignalingService signalingService = getIt<SignalingService>();

  bool isRoomIdValid(String roomId) {
    if (roomId.isEmpty && mounted) {
      Utils.showErrorDialog(context, "Please enter a room ID");
      return false;
    }

    if (roomId.length != 15 && mounted) {
      Utils.showErrorDialog(
        context,
        "Please enter a valid room ID\n Room ID should be 15 letters",
      );
      return false;
    }

    return true;
  }

  Future<void> handleJoinRoomButton(String roomId) async {
    if (!isRoomIdValid(roomId)) return;

    signalingService.onJoinRoom = (response) async {
      if (response['error'] != null) {
        setState(() {
          isJoiningRoom = false;
        });

        Utils.showErrorDialog(context, response['error']);

        return;
      }

      await webRTCProvider.createConnection();

      signalingService.roomId = roomId;

      setState(() {
        isJoiningRoom = false;
      });

      if (mounted) await Navigator.pushNamed(context, "/CallPage");
    };

    setState(() {
      isJoiningRoom = true;
    });

    signalingService.joinRoom(roomId);
  }

  void handleCreateRoomButton() {
    signalingService.onCreateRoom = (response) async {
      if (response['error'] != null) {
        setState(() {
          isCreatingRoom = false;
        });

        Utils.showErrorDialog(context, response['error']);

        return;
      }

      String roomId = response['roomId'];

      await webRTCProvider.createConnection();

      roomIdField.text = "";
      signalingService.roomId = response['roomId'];

      setState(() {
        isCreatingRoom = false;
      });

      await Utils.copyToClipboard(roomId);
      if (mounted) Utils.showSnackbar(context, "Room ID copied to clipboard: $roomId");

      log("roomId set: $roomId");

      if (mounted) Navigator.pushNamed(context, "/CallPage");
    };

    setState(() {
      isCreatingRoom = true;
    });

    signalingService.createRoom();
  }

  @override
  void initState() {
    webRTCProvider = Provider.of<WebRTCProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        Provider.of<SignalingProvider>(context, listen: false).init();
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    signalingService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    signalingProvider = Provider.of<SignalingProvider>(context);

    if (signalingProvider.isConnecting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!signalingProvider.isConnected) return NoConnectionPage();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Tawasul"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10),
                child: TextField(
                  controller: roomIdField,
                  textAlign: TextAlign.center,
                  onSubmitted: handleJoinRoomButton,
                  decoration: const InputDecoration(
                    hintText: "Enter room ID here",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isJoiningRoom || isCreatingRoom || !signalingProvider.isConnected
                        ? null
                        : () => handleJoinRoomButton(roomIdField.text),
                    child: isJoiningRoom
                        ? Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: FittedBox(child: CircularProgressIndicator()),
                          )
                        : const Text("Join room"),
                  ),
                ),
              ),
              const DividerWidget(),
              Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  height: 40,
                  child: ElevatedButton(
                    onPressed: isCreatingRoom || isJoiningRoom || !signalingProvider.isConnected
                        ? null
                        : handleCreateRoomButton,
                    style: ButtonStyle(backgroundColor: WidgetStateProperty.all(Colors.grey)),
                    child: isCreatingRoom
                        ? const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: FittedBox(child: CircularProgressIndicator()),
                          )
                        : const Text("Create room"),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ServerModeButton(),
    );
  }
}
