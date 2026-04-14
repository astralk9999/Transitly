import 'package:flutter/material.dart';

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text('PANTALLA: FEEDBACK RUTA $routeId',
            style: const TextStyle(
                color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
