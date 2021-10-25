// Shim document if it doesn't exist (e.g. on React native)
// if ((typeof global !== "undefined") && !(global as any).document) {
//   (global as any).document = {};
// }
import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:libsodium/libsodium.dart';

import 'Chunker.dart';
import 'Constants.dart';
import 'Exceptions.dart';
import 'Helpers.dart';

// import _sodium from "libsodium-wrappers";
// import * as Argon2 from "argon2-webworker";

// import * as Constants from "./Constants";
// import { numToUint8Array, symmetricNonceSize } from "./Helpers";

// import { Rollsum } from "./Chunker";

// import type rnsodiumType from "react-native-sodium";
// import
// import 'Exceptions.dart';{ ProgrammingError } from "./Exceptions";

// var rnsodium: typeof rnsodiumType;

// _setRnSodium(rnsodium_) {
//   rnsodium = rnsodium_;
// }
 final ready = Future.sync(() => {
   Sodium.init()
 });

Uint8List concatArrayBuffers(Uint8List buffer1, Uint8List buffer2) {
  // final ret = Uint8List(buffer1.length + buffer2.length);
  // ret.insertAll(0, buffer1);
  // ret.insertAll(buffer1.length, buffer2);
  final ret = Uint8List.fromList([...buffer1, ...buffer2]);
  return ret;
}

Uint8List concatArrayBuffersArrays(List<Uint8List> buffers) {
  // final length = buffers.reduce((x, y) => x + y.length, 0);
  var length = 0;
  buffers.forEach((v) => length += v.length);
  final ret = Uint8List(length);
  var pos = 0;
  for (final buffer in buffers) {
    ret.insertAll(pos, buffer);
    pos += buffer.length;
  }
  return ret;
}

enum KeyDerivationDifficulty {
  Hard, //= 90,
  Medium, //= 50,
  Easy, //= 10,
}

Future<Uint8List> deriveKey(Uint8List salt, String password,
    [KeyDerivationDifficulty? difficulty]) async {
  difficulty = difficulty ?? KeyDerivationDifficulty.Hard;
  salt = salt.sublist(0, Sodium.cryptoPwhashSaltbytes);
  int opslimit;

  switch (difficulty) {
    case KeyDerivationDifficulty.Hard:
      opslimit = Sodium.cryptoPwhashOpslimitSensitive;
      break;
    case KeyDerivationDifficulty.Medium:
      opslimit = Sodium.cryptoPwhashOpslimitModerate;
      break;
    case KeyDerivationDifficulty.Easy:
      opslimit = Sodium.cryptoPwhashOpslimitInteractive;
      break;
    default:
      throw ProgrammingError('Passed invalid difficulty.');
  }

  try {
    final argonGenerator = Argon2BytesGenerator();
    var result = Uint8List(32);
    argonGenerator
      ..init(Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        secret: Uint8List.fromList(utf8.encode(password)),
        memory: (Sodium.cryptoPwhashMemlimitModerate / 1024).floor(),
      ))
      ..generateBytes(
          Uint8List.fromList(utf8.encode(password)), result, 0, result.length);
    // final ret = await Argon2.hash({
    //   hashLen: 32,
    //   pass: password,
    //   salt,
    //   time: opslimit,
    //   mem: sodium.crypto_pwhash_MEMLIMIT_MODERATE / 1024,
    //   parallelism: 1,
    //   type: Argon2.ArgonType.Argon2id,
    // });
    return result;
  } catch (e) {}

  return Sodium.cryptoPwhash(
      32,
      Uint8List.fromList(utf8.encode(password)),
      salt,
      opslimit,
      Sodium.cryptoPwhashMemlimitModerate,
      Sodium.cryptoPwhashAlgDefault);
}

class CryptoManager {
  final int version;
  late Uint8List cipherKey;
  late Uint8List macKey;
  late Uint8List asymKeySeed;
  late Uint8List subDerivationKey;
  late Uint8List determinsticEncryptionKey;

  CryptoManager(Uint8List key, String keyContext,
      [this.version = Constants.CURRENT_VERSION]) {
    keyContext = keyContext.padRight(8);
    final keyContextUint8List = Uint8List.fromList(utf8.encode(keyContext));

    cipherKey = Sodium.cryptoKdfDeriveFromKey(32, 1, keyContextUint8List, key);
    macKey = Sodium.cryptoKdfDeriveFromKey(32, 2, keyContextUint8List, key);
    asymKeySeed =
        Sodium.cryptoKdfDeriveFromKey(32, 3, keyContextUint8List, key);
    subDerivationKey =
        Sodium.cryptoKdfDeriveFromKey(32, 4, keyContextUint8List, key);
    determinsticEncryptionKey =
        Sodium.cryptoKdfDeriveFromKey(32, 5, keyContextUint8List, key);
  }

  Uint8List encrypt(Uint8List message, [Uint8List? additionalData]) {
    final nonce = Sodium.randombytesBuf(symmetricNonceSize);
    return concatArrayBuffers(
        nonce,
        Sodium.cryptoAeadXchacha20poly1305IetfEncrypt(
            message, additionalData, null, nonce, cipherKey));
  }

  Uint8List decrypt(Uint8List nonceCiphertext, [Uint8List? additionalData]) {
    final nonce = nonceCiphertext.sublist(0, symmetricNonceSize);
    final ciphertext = nonceCiphertext.sublist(symmetricNonceSize);
    return Sodium.cryptoAeadXchacha20poly1305IetfDecrypt(
        null, ciphertext, additionalData, nonce, cipherKey);
  }

  List<Uint8List> encryptDetached(
      Uint8List message, [Uint8List? additionalData]) {
    final nonce = Sodium.randombytesBuf(symmetricNonceSize);
    final ret = Sodium.cryptoAeadXchacha20poly1305IetfEncryptDetached(
        message, additionalData, null, nonce, cipherKey);
    return [ret.mac, concatArrayBuffers(nonce, ret.c)];
  }

  Uint8List decryptDetached(
      Uint8List nonceCiphertext, Uint8List mac, [Uint8List? additionalData]) {
    final nonce = nonceCiphertext.sublist(0, symmetricNonceSize);
    final ciphertext = nonceCiphertext.sublist(symmetricNonceSize);
    return Sodium.cryptoAeadXchacha20poly1305IetfDecryptDetached(
        null, ciphertext, mac, additionalData, nonce, cipherKey);
  }

  bool verify(
      Uint8List nonceCiphertext, Uint8List mac, [Uint8List? additionalData]) {
    final nonce = nonceCiphertext.sublist(0, symmetricNonceSize);
    final ciphertext = nonceCiphertext.sublist(symmetricNonceSize);
    Sodium.cryptoAeadXchacha20poly1305IetfDecryptDetached(
        null, ciphertext, mac, additionalData, nonce, cipherKey);
    return true;
  }

  Uint8List deterministicEncrypt(Uint8List message,
      [Uint8List? additionalData]) {
    // FIXME: we could me slightly more efficient (save 8 bytes) and use crypto_stream_xchacha20_xor directly, and
    // just have the mac be used to verify. Though that  is not exposed in libsodium.js (the slimmer version),
    // and it's easier to get wrong, so we are just using the full xchacha20poly1305 we already use anyway.
    final nonce = calculateMac(message).sublist(0, symmetricNonceSize);
    return concatArrayBuffers(
        nonce,
        Sodium.cryptoAeadXchacha20poly1305IetfEncrypt(
            message, additionalData, null, nonce, determinsticEncryptionKey));
  }

  Uint8List deterministicDecrypt(Uint8List nonceCiphertext,
      [Uint8List? additionalData]) {
    final nonce = nonceCiphertext.sublist(0, symmetricNonceSize);
    final ciphertext = nonceCiphertext.sublist(symmetricNonceSize);
    return Sodium.cryptoAeadXchacha20poly1305IetfDecrypt(
        null, ciphertext, additionalData, nonce, determinsticEncryptionKey);
  }

  Uint8List deriveSubkey(Uint8List salt) {
    return Sodium.cryptoGenerichash(32, subDerivationKey, salt);
  }

  CryptoMac getCryptoMac([withKey = true]) {
    final key = (withKey) ? macKey : null;
    return CryptoMac(key);
  }

  Uint8List calculateMac(Uint8List message, [withKey = true]) {
    final key = (withKey) ? macKey : null;
    return Sodium.cryptoGenerichash(32, message, key);
  }

  Rollsum getChunker() {
    return Rollsum();
  }
}

class LoginCryptoManager {
  final KeyPair _keypair;

  LoginCryptoManager(this._keypair);

  static LoginCryptoManager keygen(Uint8List seed) {
    return LoginCryptoManager(Sodium.cryptoSignSeedKeypair(seed));
  }

  Uint8List signDetached(Uint8List message) {
    return Sodium.cryptoSignDetached(message, _keypair.pk);
  }

  static bool verifyDetached(
      Uint8List message, Uint8List signature, Uint8List pubkey) {
    return Sodium.cryptoSignVerifyDetached(signature, message, pubkey) == 1;
  }

  Uint8List get pubkey {
    return _keypair.pk;
  }
}

class BoxCryptoManager {
  final KeyPair _keypair;

  BoxCryptoManager._(this._keypair);

  static BoxCryptoManager keygen([Uint8List? seed]) {
    if (seed != null) {
      return BoxCryptoManager._(Sodium.cryptoBoxSeedKeypair(seed));
    } else {
      return BoxCryptoManager._(Sodium.cryptoBoxKeypair());
    }
  }

  static BoxCryptoManager fromPrivkey(Uint8List privkey) {
    return BoxCryptoManager._(
        KeyPair(pk: Sodium.cryptoScalarmultBase(privkey), sk: privkey));
  }

  Uint8List encrypt(Uint8List message, Uint8List pubkey) {
    final nonce = Sodium.randombytesBuf(Sodium.cryptoBoxNoncebytes);
    final ret = Sodium.cryptoBoxEasy(message, nonce, pubkey, _keypair.sk);

    return concatArrayBuffers(nonce, ret);
  }

  Uint8List decrypt(Uint8List nonceCiphertext, Uint8List pubkey) {
    final nonceSize = Sodium.cryptoBoxNoncebytes;
    final nonce = nonceCiphertext.sublist(0, nonceSize);
    final ciphertext = nonceCiphertext.sublist(nonceSize);

    return Sodium.cryptoBoxOpenEasy(ciphertext, nonce, pubkey, _keypair.sk);
  }

  Uint8List get pubkey {
    return _keypair.pk;
  }

  Uint8List get privkey {
    return _keypair.sk;
  }
}

typedef StateAddress = Pointer<Uint8>;

class CryptoMac {
  final StateAddress _state;
  final int _length;

  CryptoMac(Uint8List? key, [this._length = 32])
      : _state = Sodium.cryptoGenerichashInit(key, _length);

  void updateWithLenPrefix(Uint8List messageChunk) {
    Sodium.cryptoGenerichashUpdate(
        _state, numToUint8Array(messageChunk.length));
    Sodium.cryptoGenerichashUpdate(_state, messageChunk);
  }

  void update(Uint8List messageChunk) {
    Sodium.cryptoGenerichashUpdate(_state, messageChunk);
  }

  Uint8List finalize() {
    return Sodium.cryptoGenerichashFinal(_state, _length);
  }
}

String getEncodedChunk(Uint8List content, int offset) {
  final num = ((content[offset] << 16) +
          (content[offset + 1] << 8) +
          content[offset + 2]) %
      100000;
  return num.toString().padLeft(5, '0');
}

String getPrettyFingerprint(Uint8List content, [delimiter = '   ']) {
  final fingerprint = Sodium.cryptoGenerichash(32, content, null);

  /* We use 3 bytes each time to generate a 5 digit number - this means 10 pairs for bytes 0-29
   * We then use bytes 29-31 for another number, and then the 3 most significant bits of each first byte for the last.
   */
  var ret = '';
  var lastNum = 0;
  for (var i = 0; i < 10; i++) {
    final suffix = (i % 4 == 3) ? '\n' : delimiter;
    ret += getEncodedChunk(fingerprint, i * 3) + suffix;
    lastNum = (lastNum << 3) | ((fingerprint[i] & 0xE0) >>> 5);
  }
  ret += getEncodedChunk(fingerprint, 29) + delimiter;
  ret += (lastNum % 100000).toString().padLeft(5, '0');
  return ret;
}
