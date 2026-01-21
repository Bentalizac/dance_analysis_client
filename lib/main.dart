import 'package:flutter/material.dart';

import 'ui/design_system.dart';
import 'ui/main_scaffold.dart';

void main() {
  runApp(const MyApp());
}

/// Root widget for the MVP upload client.
///
/// Kept intentionally small: a single screen with basic theming.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dance Coaching Upload',
      debugShowCheckedModeBanner: false,
      theme: AppDesignSystem.darkTheme,
      home: const MainScaffold(),
    );
  }
}
