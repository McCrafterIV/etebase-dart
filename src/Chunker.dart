/*
 * The rolling sum implementation is based on Rollsum from bup which is in turn based on rollsum from librsync:
 * https://github.com/bup/bup/blob/master/lib/bup/bupsplit.c
 * https://github.com/librsync/librsync/blob/master/src/rollsum.h
 *
 * We tried a few alternatives (see experiments/chunker/ for details) though this was by far the best one.
 *
 * The problem with using such a chunker is that it leaks information about the sizes of different chunks which
 * in turn leaks information about the original file (because the chunking is deterministic).
 * Therefore one needs to make sure to pad the chunks in a way that doesn't leak this information.
 */

import 'dart:typed_data';

const windowSize = 64;
const charOffset = 31;

class Rollsum {
  int _s1;
  int _s2;
  Uint8List _window;
  int _wofs;

  Rollsum._(this._s1, this._s2, this._window, this._wofs);

  factory Rollsum() {
    final window = Uint8List(windowSize);
    final s1 = windowSize * charOffset;
    final s2 = windowSize * (windowSize - 1) * charOffset;
    final wofs = 0;
    return Rollsum._(s1, s2, window, wofs);
  }

  void update(int ch) {
    _rollsumAdd(_window[_wofs], ch);
    _window[_wofs] = (ch);
    _wofs = (_wofs + 1) % windowSize;
  }

  void _rollsumAdd(int drop, int add) {
    _s1 = (_s1 + add - drop) >>> 0;
    _s2 = (_s2 + _s1 - (windowSize * (drop + charOffset))) >>> 0;
  }

  /// Returns true if splitting is needed, that is when the current digest
  /// reaches the given number of the same consecutive low bits.
  bool split(int mask) {
    return (_s2 & (mask)) == mask;
  }
}
