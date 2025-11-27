import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/game/game_screen.dart';

void main() {
  runApp(const ProviderScope(child: HoneycombApp()));
}

class HoneycombApp extends StatelessWidget {
  const HoneycombApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Honeycomb One Pass',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
