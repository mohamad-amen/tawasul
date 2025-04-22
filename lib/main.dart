import 'package:flutter/material.dart';
import 'package:tawasul/core/di_container.dart';
import 'package:tawasul/core/services/signaling/signaling_provider.dart';
import 'package:tawasul/core/services/webrtc/webrtc_provider.dart';
import 'core/routing_controller.dart';
import 'package:provider/provider.dart';

void main() {
  getItSetup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => WebRTCProvider()),
        ChangeNotifierProvider(create: (context) => SignalingProvider()),
      ],
      child: const MaterialApp(
        title: 'Tawasul',
        initialRoute: "/HomePage",
        onGenerateRoute: routeGenerator,
      ),
    );
  }
}
