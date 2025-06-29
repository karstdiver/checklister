import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class {{name}}Widget extends ConsumerWidget {
  const {{name}}Widget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{name}}')),
      body: const Center(child: Text('This is the {{name}} widget')),
    );
  }
}
