import 'package:flutter/material.dart';

class LiveRouteRecorder extends StatelessWidget {
  const LiveRouteRecorder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: GRABACIÓN EN VIVO',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
