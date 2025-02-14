import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tawasul/core/utils.dart';
import 'package:tawasul/features/home_page/presentation/domain/websocket_provider.dart';
import 'package:tawasul/features/home_page/presentation/widgets/server_mode_button.dart';
import 'package:tawasul/features/video_call_page/domain/rtc_provider.dart';
import 'package:tawasul/features/home_page/presentation/widgets/devider_widget.dart';
import 'package:tawasul/core/websocket_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final RTCProvider rtcProvider;
  late WebSocketProvider websocketProvider;

  bool isJoiningRoom = false;
  bool isCreatingRoom = false;

  TextEditingController roomIdField = TextEditingController();

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

    WebSocketService.onJoinRoom = (response) async {
      if (response['error'] != null) {
        setState(() {
          isJoiningRoom = false;
        });

        Utils.showErrorDialog(context, response['error']);

        return;
      }

      await rtcProvider.createConnection();
      await rtcProvider.getMedia();
      rtcProvider.toggleCamera(false);
      rtcProvider.toggleMic(false);

      WebSocketService.roomId = roomId;

      setState(() {
        isJoiningRoom = false;
      });

      if (mounted) await Navigator.pushNamed(context, "/CallPage");
    };

    setState(() {
      isJoiningRoom = true;
    });

    WebSocketService.joinRoom(roomId);
  }

  void handleCreateRoomButton() {
    WebSocketService.onCreateRoom = (response) async {
      if (response['error'] != null) {
        setState(() {
          isCreatingRoom = false;
        });

        Utils.showErrorDialog(context, response['error']);

        return;
      }

      String roomId = response['roomId'];

      await rtcProvider.createConnection();
      await rtcProvider.getMedia();
      rtcProvider.toggleCamera(false);
      rtcProvider.toggleMic(false);

      roomIdField.text = "";
      WebSocketService.roomId = response['roomId'];

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

    WebSocketService.createRoom();
  }

  @override
  void initState() {
    rtcProvider = Provider.of<RTCProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback(
      (timeStamp) {
        Provider.of<WebSocketProvider>(context, listen: false).init();
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    WebSocketService.closeWebSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    websocketProvider = Provider.of<WebSocketProvider>(context);

    if (websocketProvider.isConnecting) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!websocketProvider.isConnected) {
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
                      websocketProvider.connect();
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

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text("Tawasul"),
        centerTitle: true,
        actions: [],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            // mainAxisSize: MainAxisSize.max,
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
                    onPressed: isJoiningRoom || isCreatingRoom || !websocketProvider.isConnected
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
                    onPressed: isCreatingRoom || isJoiningRoom || !websocketProvider.isConnected
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
