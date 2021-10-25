// const sodium = _sodium;

import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:libsodium/libsodium.dart';
import 'package:msgpack2/msgpack2.dart' as msgpack;

typedef base64 = String;

const symmetricKeyLength =
    32; // sodium.crypto_aead_xchacha20poly1305_ietf_KEYBYTES;
const symmetricTagLength =
    16; // sodium.crypto_aead_xchacha20poly1305_ietf_ABYTES;
const symmetricNonceSize =
    24; // sodium.crypto_aead_xchacha20poly1305_ietf_NPUBBYTES;

Uint8List randomBytes(int length) {
  return Sodium.randombytesBuf(length);
}

Uint8List randomBytesDeterministic(int length, Uint8List seed) {
  return Sodium.randombytesBufDeterministic(length, seed);
}

String toBase64(input) {
  if(input.runtimeType != Uint8List){
    input = Uint8List.fromList(utf8.encode(input.toString()));
  }
  return Sodium.bin2base64(input, variant: Sodium.base64VariantUrlsafeNoPadding);
}

Uint8List fromBase64(String input) {
  return Sodium.base642bin(input, variant: Sodium.base64VariantUrlsafeNoPadding);
}

String toString(Uint8List input) {
  return utf8.decode(input);
}

Uint8List fromString(String input) {
  return Uint8List.fromList(utf8.encode(input));
}

bool memcmp(Uint8List b1, Uint8List b2) {
  return Sodium.memcmp(b1, b2);
}

// Fisher–Yates shuffle - an unbiased shuffler
// The returend indices of where item is now.
// So if the first item moved to position 3: ret[0] = 3
List<int> shuffle<T>(List<T> a) {
  final len = a.length;
  final shuffledIndices = List.generate(len, (v) => v);

  // Fill up with the indices
  for (var i = 0; i < len; i++) {
    shuffledIndices[i] = i;
  }

  for (var i = 0; i < len; i++) {
    final j = i + Sodium.randombytesUniform(len - i);
    final tmp = a[i];
    a[i] = a[j];
    a[j] = tmp;

    // Also swap the index array
    final tmp2 = shuffledIndices[i];
    shuffledIndices[i] = shuffledIndices[j];
    shuffledIndices[j] = tmp2;
  }

  final ret = List.generate(len, (v) => v);
  for (var i = 0; i < len; i++) {
    ret[shuffledIndices[i]] = i;
  }

  return ret;
}

int getPadding(int length) {
  // Use the padme padding scheme for efficiently
  // https://www.petsymposium.org/2019/files/papers/issue4/popets-2019-0056.pdf

  // We want a minimum pad size of 4k
  if (length < (1 << 14)) {
    const size = (1 << 10) - 1;
    // We add 1 so we always have some padding
    return (length | size) + 1;
  }

  final e = (math.log(length) / math.log(2)).floor();
  final s = (math.log(e) / math.log(2)).floor() + 1;
  final lastBits = e - s;
  final bitMask = math.pow(2, lastBits) - 1;
  return ((length + bitMask) as int) & ~(bitMask as int);
}

// FIXME: we should properly pad the meta and probably change these s
// This  is the same as bufferPad, but doesn't enforce a large minimum padding size
Uint8List bufferPadSmall(Uint8List buf) {
  return Sodium.pad(buf, buf.length + 1);
}

Uint8List bufferPad(Uint8List buf) {
  return Sodium.pad(buf, getPadding(buf.length));
}

Uint8List bufferUnpad(Uint8List buf) {
  if (buf.isEmpty) {
    return buf;
  }

  // We pass the buffer's length as the block size because due to padme there's always some variable-sized padding.
  return Sodium.unpad(buf, buf.length);
}

Uint8List bufferPadFixed(Uint8List buf, int blocksize) {
  return Sodium.pad(buf, blocksize);
}

Uint8List bufferUnpadFixed(Uint8List buf, int blocksize) {
  return Sodium.unpad(buf, blocksize);
}

Uint8List msgpackEncode(value) {
  return msgpack.serialize(value);
}

// : ArrayLike<number> | ArrayBuffer
dynamic msgpackDecode(List<int> buffer) {
  return msgpack.deserialize(buffer);
}

Uint8List numToUint8Array(int num) {
  // We are using little-endian because on most platforms it'll mean zero-conversion
  return Uint8List.fromList([
    num & 255,
    (num >> 8) & 255,
    (num >> 16) & 255,
    (num >> 24) & 255,
  ]);
}

int numFromUint8Array(Uint8List buf) {
  if (buf.length != 4) {
    throw Exception('numFromUint8Array: buffer should be of length 4.');
  }

  return (buf[0] +
      (buf[1] << 8) +
      (buf[2] << 16) +
      (((buf[3] << 23) >>> 0) * 2));
}

class SumType<O, T> {
  O one;
  T two;

  SumType(this.one, this.two);
}
