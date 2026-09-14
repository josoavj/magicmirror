import 'package:flutter/material.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      '/': (context) =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      '/mirror': (context) =>
          const Scaffold(body: Center(child: Text('Mirror Screen'))),
      '/agenda': (context) =>
          const Scaffold(body: Center(child: Text('Agenda Screen'))),
      '/outfit-suggestion': (context) =>
          const Scaffold(body: Center(child: Text('Outfit Suggestion Screen'))),
    };
  }
}
