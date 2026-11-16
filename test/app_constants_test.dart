import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/constants/app_constants.dart';

void main() {
  test('the in-app version matches pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final match = RegExp(
      r'^version:\s*(\d+\.\d+\.\d+)',
      multiLine: true,
    ).firstMatch(pubspec);

    expect(match, isNotNull, reason: 'pubspec.yaml needs a semantic version');
    expect(
      AppConstants.appVersion,
      match!.group(1),
      reason: 'Update AppConstants.appVersion when bumping the release.',
    );
  });
}
