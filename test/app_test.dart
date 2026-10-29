import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/app.dart';
import 'package:lockout/core/constants/app_constants.dart';

void main() {
  testWidgets('app boots and shows the scaffold placeholder', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LockoutApp()));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('Project scaffold ready'), findsOneWidget);
    expect(find.text('v${AppConstants.appVersion}'), findsOneWidget);
  });

  testWidgets('app renders without overflow on a small phone', (tester) async {
    tester.view.physicalSize = const Size(320 * 3, 480 * 3);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const ProviderScope(child: LockoutApp()));

    expect(tester.takeException(), isNull);
  });
}
