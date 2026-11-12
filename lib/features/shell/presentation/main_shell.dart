import 'package:flutter/material.dart';

import '../../home/presentation/home_screen.dart';
import '../../reader/presentation/reader_screen.dart';

/// The two top-level destinations: usage Today and the finite Reader.
///
/// Reader is built lazily on first visit so an empty cache does not trigger a
/// network fetch just because the app opened on Today.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  bool _readerOpened = false;

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      if (index == 1) _readerOpened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _index != 0) _select(0);
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const HomeScreen(),
            _readerOpened ? const ReaderScreen() : const SizedBox.shrink(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _select,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.shield_outlined),
              selectedIcon: Icon(Icons.shield),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Reader',
            ),
          ],
        ),
      ),
    );
  }
}
