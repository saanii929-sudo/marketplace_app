import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/cart/cart_controller.dart';
import '../../features/catalog/category.dart';
import '../../features/wishlist/wishlist_controller.dart';
import '../../widgets/navigation/app_bottom_nav.dart';
import 'cart_screen.dart';
import 'categories_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

/// App shell hosting the bottom navigation over Home, Categories, Cart,
/// Wishlist and Profile.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  int? _selectedCategoryId;

  void _openCategory(Category category) => setState(() {
    _selectedCategoryId = category.id;
    _index = 1;
  });

  void _goHome() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      AppBottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
      AppBottomNavItem(
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Categories',
      ),
      AppBottomNavItem(
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        label: 'Cart',
        badgeCount: ref.watch(cartControllerProvider).value?.itemCount ?? 0,
      ),
      AppBottomNavItem(
        icon: Icons.favorite_border,
        activeIcon: Icons.favorite,
        label: 'Wishlist',
        badgeCount: ref.watch(wishlistControllerProvider).value?.length ?? 0,
      ),
      const AppBottomNavItem(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Profile',
      ),
    ];

    final screens = [
      HomeScreen(onCategoryTap: _openCategory),
      CategoriesScreen(initialCategoryId: _selectedCategoryId),
      CartScreen(onStartShopping: _goHome),
      WishlistScreen(onStartShopping: _goHome),
      const ProfileScreen(),
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
