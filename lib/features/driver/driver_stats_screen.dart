import 'package:flutter/material.dart';

class DriverStatsScreen extends StatelessWidget {
  const DriverStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: ESTADÍSTICAS CONDUCTOR',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
