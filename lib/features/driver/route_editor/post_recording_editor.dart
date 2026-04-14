import 'package:flutter/material.dart';

class PostRecordingEditor extends StatelessWidget {
  const PostRecordingEditor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: Text('PANTALLA: EDITOR POST-GRABACIÓN',
            style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
      ),
    );
  }
}
