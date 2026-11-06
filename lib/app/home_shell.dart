import 'package:flutter/material.dart';

import '../features/map/presentation/map_screen.dart';
import '../features/qibla/presentation/qibla_screen.dart';
import '../features/trips/presentation/trips_screen.dart';
import '../features/weather/presentation/weather_screen.dart';

/// الهيكل الرئيسي بعد التهيئة: أربعة تبويبات مع الحفاظ على حالة الخريطة.
///
/// `IndexedStack` يُبقي الشاشات حيّة، فلا تُفقد حالة الخريطة أو تسجيل
/// الرحلة عند التبديل بين التبويبات. التبويبات تُبنى عند أول زيارة فقط
/// حتى لا يبدأ الطقس بالشبكة أو البوصلة بالحساسات قبل الحاجة.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  late final List<Widget?> _pages = [
    const MapScreen(),
    null,
    null,
    null,
  ];

  static Widget _pageFor(int index) {
    return switch (index) {
      0 => const MapScreen(),
      1 => const WeatherScreen(),
      2 => const QiblaScreen(),
      _ => const TripsScreen(),
    };
  }

  void _select(int index) {
    setState(() {
      _index = index;
      _pages[index] ??= _pageFor(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          for (final page in _pages) page ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'الخريطة',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny),
            label: 'الطقس',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'القبلة',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: 'رحلاتي',
          ),
        ],
      ),
    );
  }
}
