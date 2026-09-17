import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../history/history_screen.dart';
import '../home/home_screen.dart';
import '../monetization/stable_banner_ad.dart';
import '../routines/routines_screen.dart';
import '../settings/settings_screen.dart';

/// Rangka utama: empat tab, satu banner yang hanya muncul di Home dan History.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  late int _index = widget.initialIndex;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.cleaning_services_outlined),
      selectedIcon: Icon(Icons.cleaning_services),
      label: 'Clean',
    ),
    NavigationDestination(
      icon: Icon(Icons.checklist_rtl_outlined),
      selectedIcon: Icon(Icons.checklist_rtl),
      label: 'Routines',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.tune_outlined),
      selectedIcon: Icon(Icons.tune),
      label: 'Settings',
    ),
  ];

  /// Banner hanya di tempat yang tidak mengganggu: Home dan History.
  BannerPlacement? get _bannerPlacement => switch (_index) {
    0 => BannerPlacement.home,
    2 => BannerPlacement.history,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final placement = _bannerPlacement;
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          RoutinesScreen(),
          HistoryScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (placement != null) StableBannerAd(placement: placement),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: _destinations,
          ),
        ],
      ),
    );
  }
}
