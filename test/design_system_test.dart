import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pypath/design_system.dart';

void main() {
  test('light and dark themes provide the app design system', () {
    final light = AppTheme.light();
    final dark = AppTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.textTheme.bodyMedium?.fontFamily, 'Poppins');
    expect(dark.textTheme.bodyMedium?.fontFamily, 'Poppins');
    expect(light.filledButtonTheme.style, isNotNull);
    expect(dark.cardTheme.shape, isNotNull);
  });
}
