import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'bundled Pyodide runtime assets match pinned SHA-256 checksums',
    () async {
      final manifest =
          jsonDecode(
                await rootBundle.loadString(
                  'assets/pyodide/0.27.8/sha256.json',
                ),
              )
              as Map<String, dynamic>;
      final files = manifest['files'] as Map<String, dynamic>;
      var totalBytes = 0;
      for (final entry in files.entries) {
        final data = await rootBundle.load(
          'assets/pyodide/0.27.8/${entry.key}',
        );
        final bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );
        totalBytes += bytes.length;
        expect(sha256.convert(bytes).toString(), entry.value);
      }
      expect(manifest['version'], '0.27.8');
      expect(totalBytes, lessThan(20 * 1024 * 1024));
    },
  );
}
