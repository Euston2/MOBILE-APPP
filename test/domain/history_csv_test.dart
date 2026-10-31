import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/domain/entities/history_day.dart';
import 'package:lockout/domain/usecases/history_csv.dart';

void main() {
  test('returns only the header when there is no usage', () {
    final csv = historyCsv([
      HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 0,
        limitSeconds: 3600,
      ),
    ]);

    expect(csv, 'date,total_seconds,limit_seconds,limit_hit_at,apps\r\n');
  });

  test('writes one row per used day, oldest first, with sorted apps', () {
    final csv = historyCsv([
      HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 1800,
        limitSeconds: 3600,
        apps: const {'com.z': 300, 'com.a': 1500},
      ),
      HistoryDay(
        date: DateTime(2026, 10, 28),
        totalSeconds: 3900,
        limitSeconds: 3600,
        limitHitAt: DateTime(2026, 10, 28, 14, 5),
        apps: const {'com.a': 3900},
      ),
    ]);

    final lines = csv.split('\r\n');
    expect(lines[0], 'date,total_seconds,limit_seconds,limit_hit_at,apps');
    expect(lines[1], '2026-10-28,3900,3600,2026-10-28T14:05:00.000,com.a=3900');
    expect(lines[2], '2026-10-30,1800,3600,,com.a=1500|com.z=300');
    expect(lines[3], isEmpty);
    expect(csv.endsWith('\r\n'), isTrue);
  });

  test('quotes fields containing commas, quotes or newlines', () {
    final csv = historyCsv([
      HistoryDay(
        date: DateTime(2026, 10, 30),
        totalSeconds: 90,
        limitSeconds: 0,
        apps: const {'comma,app': 60, 'quote"app': 30},
      ),
    ]);

    final appsField = csv.split('\r\n')[1];
    expect(appsField, contains('"comma,app=60|quote""app=30"'));
  });
}
