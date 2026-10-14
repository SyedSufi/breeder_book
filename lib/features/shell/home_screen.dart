import 'package:flutter/material.dart';

import '../backup/presentation/settings_screen.dart';
import '../birds/presentation/birds_list_screen.dart';
import '../pairs/presentation/pairs_screen.dart';
import 'floating_pill_nav.dart';

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
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      extendBody: true,
      body: _tab(_index),
      bottomNavigationBar: SafeArea(
        minimum: EdgeInsets.only(bottom: 8 + bottomInset * 0.15),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: FloatingPillNav(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              FloatingPillDestination(
                icon: Icons.pets_outlined,
                selectedIcon: Icons.pets,
                label: 'Birds',
              ),
              FloatingPillDestination(
                icon: Icons.favorite_outline,
                selectedIcon: Icons.favorite,
                label: 'Pairs',
              ),
              FloatingPillDestination(
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
                label: 'Backup',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
