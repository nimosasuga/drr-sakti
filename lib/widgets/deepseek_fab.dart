import 'package:flutter/material.dart';

class DeepSeekFAB extends StatelessWidget {
  final VoidCallback? onPressed;

  const DeepSeekFAB({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed:
          onPressed ??
          () {
            Navigator.pushNamed(context, '/deepseek');
          },
      backgroundColor: Colors.blue.shade700,
      icon: const Icon(Icons.smart_toy),
      label: const Text('AI Assistant'),
    );
  }
}
