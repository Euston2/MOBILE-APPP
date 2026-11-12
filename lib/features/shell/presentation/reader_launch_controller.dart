import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Requests to open the Reader tab from outside the app shell.
///
/// The native block screen and overlay offer "Read something instead". That
/// shortcut launches Lockout with a Reader intent, which `main.dart` forwards
/// here. Incrementing the counter lets a running shell switch tabs, while a
/// cold start sees a non-zero value and opens on Reader directly. The shortcut
/// never unlocks or dismisses the guard on the blocked app.
class ReaderLaunchController extends Notifier<int> {
  @override
  int build() => 0;

  void open() => state++;
}

final readerLaunchProvider = NotifierProvider<ReaderLaunchController, int>(
  ReaderLaunchController.new,
);
