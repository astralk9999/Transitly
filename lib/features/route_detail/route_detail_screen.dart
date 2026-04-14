import 'package:flutter/material.dart';

class RouteDetailScreen extends StatelessWidget {
  const RouteDetailScreen({super.key, required this.routeId});

  final String routeId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Text('PANTALLA: DETALLE LÍNEA $routeId',
            style: const TextStyle(
                color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
