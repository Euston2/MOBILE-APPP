import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/core/utils/app_names.dart';

void main() {
  test('keeps a real display name', () {
    expect(friendlyAppName('com.twitter.android', 'X'), 'X');
  });

  test('does not expose a package name as a label', () {
    expect(
      friendlyAppName('com.twitter.android', ' com.twitter.android '),
      unknownAppName,
    );
    expect(friendlyAppName('com.twitter.android', null), unknownAppName);
    expect(friendlyAppName('com.twitter.android', ''), unknownAppName);
  });

  test('accepts a custom fallback for historical rows', () {
    expect(
      friendlyAppName('com.twitter.android', null, fallback: removedAppName),
      removedAppName,
    );
  });
}
