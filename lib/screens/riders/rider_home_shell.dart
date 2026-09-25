import 'package:flutter/material.dart';

import '../../widgets/navigation/app_bottom_nav.dart';
import 'rider_deliveries_screen.dart';
import 'rider_earnings_screen.dart';
import 'rider_home_screen.dart';
import 'rider_profile_screen.dart';

class RiderHomeShell extends StatefulWidget {
  const RiderHomeShell({super.key});

  @override
  State<RiderHomeShell> createState() => _RiderHomeShellState();
}

class _RiderHomeShellState extends State<RiderHomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      AppBottomNavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
      AppBottomNavItem(icon: Icons.local_shipping_outlined, activeIcon: Icons.local_shipping, label: 'Deliveries'),
      AppBottomNavItem(icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet, label: 'Earnings'),
      AppBottomNavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
    ];

    final screens = [
      const RiderHomeScreen(),
      const RiderDeliveriesScreen(),
      const RiderEarningsScreen(),
      const RiderProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: AppBottomNav(
        items: tabs,
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}
