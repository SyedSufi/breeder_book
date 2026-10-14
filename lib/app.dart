import 'package:flutter/material.dart';

import 'core/constants.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/home_screen.dart';

class BreederApp extends StatelessWidget {
  const BreederApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kAppName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      darkTheme: buildAppDarkTheme(),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
