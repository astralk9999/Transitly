import 'package:flutter/material.dart';

class FeedbackDetailScreen extends StatelessWidget {
  const FeedbackDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: DETALLE FEEDBACK',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
