import 'package:flutter/material.dart';

import 'ui/upload_page.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const UploadPage(),
    );
  }
}
