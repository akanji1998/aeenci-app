import 'package:aeenci_app/core/utils/version.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compareVersions', () {
    expect(compareVersions('1.0.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0', '1.0.1'), isNegative);
    expect(compareVersions('1.2.0', '1.10.0'), isNegative);
    expect(compareVersions('2.0.0', '1.99.99'), isPositive);
    expect(compareVersions('1.0', '1.0.0'), 0);
    expect(compareVersions('1.0.0-dev', '1.0.0'), 0);
    expect(compareVersions('1.0.0+12', '1.0.0'), 0);
    expect(compareVersions(' 1.4.2 ', '1.4.3'), isNegative);
  });
}
