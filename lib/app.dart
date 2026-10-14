import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'features/shell/home_screen.dart';

class BreederApp extends StatelessWidget {
  const BreederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.teal,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
