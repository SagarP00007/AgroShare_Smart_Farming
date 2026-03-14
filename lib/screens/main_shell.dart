import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'explore_screen.dart';
import 'find_equipment_screen.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';

/// Root shell that provides bottom navigation between the five tabs.
///
/// Uses AnimatedSwitcher for smooth tab transitions.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(onSwitchTab: _switchTab);
      case 1:
        return const ExploreScreen();
      case 2:
        return const FindEquipmentScreen();
      case 3:
        return const MyBookingsScreen();
      case 4:
        return const ProfileScreen();
      default:
        return HomeScreen(onSwitchTab: _switchTab);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _buildScreen(_currentIndex),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (i) => setState(() => _currentIndex = i),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.primaryGreen,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_rounded),
                  activeIcon: const Icon(Icons.home_rounded, size: 28),
                  label: L.tr(context, 'home'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.explore_rounded),
                  activeIcon: const Icon(Icons.explore_rounded, size: 28),
                  label: L.tr(context, 'explore'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.search_rounded),
                  activeIcon: const Icon(Icons.search_rounded, size: 28),
                  label: L.tr(context, 'find'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.calendar_month_rounded),
                  activeIcon: const Icon(Icons.calendar_month_rounded, size: 28),
                  label: L.tr(context, 'bookings'),
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person_rounded),
                  activeIcon: const Icon(Icons.person_rounded, size: 28),
                  label: L.tr(context, 'profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
