import 'package:flutter_test/flutter_test.dart';
import 'package:lockout/features/protection/presentation/oem_guidance.dart';

void main() {
  test('maps Xiaomi and Redmi to autostart guidance', () {
    final guidance = oemGuidanceFor(manufacturer: 'Xiaomi', brand: 'Redmi');

    expect(guidance.label, 'Xiaomi / Redmi / POCO');
    expect(guidance.hasAutostartShortcut, isTrue);
    expect(guidance.steps.join(' '), contains('Autostart'));
  });

  test('maps Transsion brands to manual guidance', () {
    final guidance = oemGuidanceFor(manufacturer: 'TECNO', brand: 'Tecno');

    expect(guidance.label, 'Tecno / Infinix / itel');
    expect(guidance.hasAutostartShortcut, isFalse);
    expect(guidance.steps.join(' '), contains('Phone Master'));
  });

  test('covers the documented Samsung, Oppo and Huawei families', () {
    expect(
      oemGuidanceFor(manufacturer: 'samsung', brand: 'samsung').label,
      'Samsung',
    );
    expect(
      oemGuidanceFor(manufacturer: 'OPPO', brand: 'realme').label,
      'Oppo / Realme',
    );
    expect(
      oemGuidanceFor(manufacturer: 'HUAWEI', brand: 'HONOR').label,
      'Huawei / Honor',
    );
  });

  test('keeps Vivo and OnePlus shortcuts enabled', () {
    expect(
      oemGuidanceFor(manufacturer: 'vivo', brand: 'iQOO').hasAutostartShortcut,
      isTrue,
    );
    expect(
      oemGuidanceFor(
        manufacturer: 'OnePlus',
        brand: 'OnePlus',
      ).hasAutostartShortcut,
      isTrue,
    );
  });

  test('falls back to generic Android steps for unknown devices', () {
    final guidance = oemGuidanceFor(manufacturer: 'Acme', brand: 'Phone');

    expect(guidance.label, 'Android');
    expect(guidance.hasAutostartShortcut, isFalse);
    expect(guidance.steps, isNotEmpty);
  });
}
