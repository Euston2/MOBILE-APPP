import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../home/presentation/home_screen.dart';
import '../../reader/presentation/reader_screen.dart';
import 'reader_launch_controller.dart';

/// The two top-level destinations: usage Today and the finite Reader.
///
/// Reader is built lazily on first visit so an empty cache does not trigger a
/// network fetch just because the app opened on Today. A Reader request from
/// the native block screen opens the tab directly.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;
  bool _readerOpened = false;

  @override
  void initState() {
    super.initState();
    // A cold start from the block screen's Reader shortcut is already recorded
    // by the time the shell is built.
    if (ref.read(readerLaunchProvider) > 0) {
      _index = 1;
      _readerOpened = true;
    }
  }

  void _select(int index) {
    if (index == _index) return;
    setState(() {
      _index = index;
      if (index == 1) _readerOpened = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // A shortcut tapped while Lockout is already running.
    ref.listen<int>(readerLaunchProvider, (_, next) {
      if (next > 0) _select(1);
    });

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
