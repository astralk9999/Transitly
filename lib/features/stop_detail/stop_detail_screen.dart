import 'package:flutter/material.dart';

class StopDetailScreen extends StatelessWidget {
  const StopDetailScreen({super.key, required this.stopId});

  final String stopId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text('PANTALLA: DETALLE PARADA $stopId',
            style: const TextStyle(
                color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
