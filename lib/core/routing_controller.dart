import 'package:flutter/material.dart';
import '../features/video_call_page/presentation/pages/call_page.dart';
import '../features/home_page/presentation/pages/home_page.dart';

//TODO: remove this file and use another functionality
Route routeGenerator(RouteSettings settings) {
  switch (settings.name) {
    case "/HomePage":
      return MaterialPageRoute(builder: (context) => const HomePage());
    case "/CallPage":
      return MaterialPageRoute(builder: (context) => const CallPage());
    default:
      return MaterialPageRoute(
        builder: (context) => const Center(
          child: Text("ERROR: this page doesn't exist"),
        ),
      );
  }
}
