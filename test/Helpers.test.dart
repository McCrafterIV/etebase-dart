import 'dart:typed_data';

import 'package:test/test.dart';

import '../src/Crypto.dart';
import '../src/Helpers.dart';

void main() {
  test('Buffer to number', () {
    final numbers = [
      0,
      123,
      12314,
      123123,
      4324234,
      32434234,
      2147483648,
      3352352352,
    ];

    for (final num in numbers) {
      final buf = numToUint8Array(num);
      expect(num, equals(numFromUint8Array(buf)));
    }
  });

  test('Padding is larger than content', () async {
    // Because of how we use padding (unpadding) we need to make sure padding is always larger than the content
    // Otherwise we risk the unpadder to fail thinking it should unpad when it shouldn't.

    for (var i = 1; i < (1 << 14); i++) {
      if (getPadding(i) <= i) {
        // Always fail here.
        expect(i, equals(-1));
      }
    }

    expect(getPadding(2343242), equals(2359296));
  });

  test('Padding fixed size', () async {
    await ready;

    const blocksize = 32;
    for (var i = 1; i < blocksize * 2; i++) {
      final buf = Uint8List(i);
      buf.fillRange(0, i - 1, 60);
      final padded = bufferPadFixed(buf, blocksize);
      final unpadded = bufferUnpadFixed(padded, blocksize);
      expect(unpadded, equals(buf));
    }
  });

  test('Shuffle', () async {
    await ready;

    const len = 200;
    final shuffled = List<int>.filled(len, 0, growable: false);

    // Fill up with the indices
    for (var i = 0; i < len; i++) {
      shuffled[i] = i;
    }

    final indices = shuffle(shuffled);

    // Unshuffle
    for (var i = 0; i < len; i++) {
      expect(shuffled[indices[i]], equals(i));
    }
  });
}
