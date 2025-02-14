import 'package:flutter/material.dart';
import 'package:tawasul/features/home_page/presentation/domain/websocket_provider.dart';
import 'package:tawasul/features/video_call_page/domain/rtc_provider.dart';
import 'core/routing_controller.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RTCProvider()),
        ChangeNotifierProvider(create: (context) => WebSocketProvider()),
      ],
      child: const MaterialApp(
        title: 'Tawasul',
        initialRoute: "/HomePage",
        onGenerateRoute: routeGenerator,
      ),
    );
  }
}
