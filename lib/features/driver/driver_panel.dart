import 'package:flutter/material.dart';

class DriverPanel extends StatelessWidget {
  const DriverPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(24),
      child: const Center(
        child: Text('PANEL: CONDUCTOR',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
