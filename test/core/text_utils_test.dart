import 'package:dhamma_echo/core/text_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalizeText collapses unicode whitespace', () {
    expect(
      normalizeText('  Venerable\n\tSayadaw   U Jotika  '),
      'Venerable Sayadaw U Jotika',
    );
    expect(normalizeText('  မေတ္တာ   ပို့  '), 'မေတ္တာ ပို့');
  });

  test('formatDuration renders minutes and hours safely', () {
    expect(formatDuration(-1), '0:00');
    expect(formatDuration(65), '1:05');
    expect(formatDuration(3661), '1:01:01');
  });
}
