import 'package:flutter/material.dart';

import '../backup/presentation/settings_screen.dart';
import '../birds/presentation/birds_list_screen.dart';
import '../pairs/presentation/pairs_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  // Each tab is rebuilt when selected, so lists always show fresh data.
  Widget _tab(int i) {
    switch (i) {
      case 1:
        return const PairsScreen();
      case 2:
        return const SettingsScreen();
      default:
        return const BirdsListScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tab(_index),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.flutter_dash),
            label: 'Birds',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_outline),
            selectedIcon: Icon(Icons.favorite),
            label: 'Pairs',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Backup',
          ),
        ],
      ),
    );
  }
}
