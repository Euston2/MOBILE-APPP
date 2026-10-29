import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Gives a test a phone-tall canvas so lazily built list items (permission
/// cards, app rows) are all laid out and findable.
void useTallScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
