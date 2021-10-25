import 'dart:convert';
import 'dart:typed_data';

import './Helpers.dart';
import 'Constants.dart';
import 'Crypto.dart';
import 'Etebase.dart';
import 'Exceptions.dart';

// import * as Constants from "./Constants";

// import { CryptoManager, BoxCryptoManager, LoginCryptoManager, concatArrayBuffersArrays } from "./Crypto";
// import { IntegrityError, MissingContentError } from "./Exceptions";
// import { base64, fromBase64, toBase64, fromString, toString, randomBytes, symmetricKeyLength, msgpackEncode, msgpackDecode, bufferPad, bufferUnpad, memcmp, shuffle, bufferPadSmall, bufferPadFixed, bufferUnpadFixed } from "./Helpers";
// import { SignedInvitationContent } from "./Etebase";

typedef Collectiontypedef = String;

// typedef Contenttypedef = Either File | Blob | Uint8Array | string | null;

class Sfe<T> {
  String? type;
  String? name;
  String? mtime;

  String? description;
  String? color;

  Map<String, dynamic> data;

  Sfe(
      {this.type,
      this.name,
      this.mtime,
      this.description,
      this.color,
      Map<String, dynamic>? data})
      : data = data ?? <String, dynamic>{};
}

class ItemMetadata<T> implements Map<String, dynamic> {
  String? type;
  String? name;
  String? mtime;

  String? description;
  String? color;

  Map<String, dynamic> data;

  ItemMetadata(
      {this.type,
      this.name,
      this.mtime,
      this.description,
      this.color,
      Map<String, dynamic>? data})
      : data = data ?? <String, dynamic>{};

  @override
  dynamic operator [](dynamic key) {
    switch (key) {
      case 'type':
        return type;
      case 'name':
        return name;
      case 'mtime':
        return mtime;
      case 'description':
        return description;
      case 'color':
        return color;
      default:
        return data[key];
    }
  }

  @override
  void operator []=(String key, value) {
    switch (key) {
      case 'type':
        type = value;
        break;
      case 'name':
        name = value;
        break;
      case 'mtime':
        mtime = value;
        break;
      case 'description':
        description = value;
        break;
      case 'color':
        color = value;
        break;
      default:
        data[key] = value;
    }
  }

  @override
  void addAll(Map<String, dynamic> other) {
    other.forEach((key, value) {
      this[key] = value;
    });
  }

  @override
  void addEntries(Iterable<MapEntry<String, dynamic>> newEntries) {
    final map = <String, dynamic>{};
    map.addEntries(newEntries);
    addAll(map);
  }

  @override
  Map<RK, RV> cast<RK, RV>() {
    final newData = {...data};
    newData.addAll({
      'type': type,
      'name': name,
      'mtime': mtime,
      'description': description,
      'color': color,
    });
    return newData.cast<RK, RV>();
  }

  @override
  void clear() {
    type = null;
    name = null;
    mtime = null;
    description = null;
    color = null;
    data = {};
  }

  @override
  bool containsKey(Object? key) {
    switch (key) {
      case 'type':
      case 'name':
      case 'mtime':
      case 'description':
      case 'color':
        return true;
      default:
        return data.containsKey(key);
    }
  }

  @override
  bool containsValue(Object? value) {
    return type == value ||
        name == value ||
        mtime == value ||
        description == value ||
        color == value ||
        data.containsValue(value);
  }

  @override
  // TODO: implement entries
  Iterable<MapEntry<String, dynamic>> get entries =>
      Iterable.generate(data.length + 5, (index) {
        switch (index) {
          case 0:
            return MapEntry('type', type);
          case 1:
            return MapEntry('name', name);
          case 2:
            return MapEntry('mtime', mtime);
          case 3:
            return MapEntry('description', description);
          case 4:
            return MapEntry('color', color);
          default:
            final dataMapEntry = data.entries.elementAt(index + 5);
            return MapEntry(dataMapEntry.key, dataMapEntry.value);
        }
      });

  @override
  void forEach(void Function(String key, dynamic value) action) {
    action('type', type);
    action('name', name);
    action('mtime', mtime);
    action('description', description);
    action('color', color);
    data.forEach(action);
  }

  @override
  // TODO: implement isEmpty
  bool get isEmpty =>
      type == null &&
      name == null &&
      mtime == null &&
      description == null &&
      color == null &&
      data.isEmpty;

  @override
  // TODO: implement isNotEmpty
  bool get isNotEmpty => !isEmpty;

  @override
  // TODO: implement keys
  Iterable<String> get keys => [
        'type',
        'name',
        'mtime',
        'description',
        'color',
        ...data.keys
      ].map((e) => e);

  @override
  // TODO: implement length
  int get length => data.length + 5;

  @override
  Map<K2, V2> map<K2, V2>(
      MapEntry<K2, V2> Function(String key, dynamic value) convert) {
    return {
      'type': type,
      'name': name,
      'mtime': mtime,
      'description': description,
      'color': color,
      ...data
    }.map(convert);
  }

  @override
  void putIfAbsent(String key, Function() ifAbsent) {
    switch (key) {
      case 'type':
        type = ifAbsent();
        break;
      case 'name':
        name = ifAbsent();
        break;
      case 'mtime':
        mtime = ifAbsent();
        break;
      case 'description':
        description = ifAbsent();
        break;
      case 'color':
        color = ifAbsent();
        break;
      default:
        data.putIfAbsent(key, ifAbsent);
    }
  }

  @override
  void remove(Object? key) {
    switch (key) {
      case 'type':
        type = null;
        break;
      case 'name':
        name = null;
        break;
      case 'mtime':
        mtime = null;
        break;
      case 'description':
        description = null;
        break;
      case 'color':
        color = null;
        break;
      default:
        data.remove(key);
    }
  }

  @override
  void removeWhere(bool Function(String key, dynamic value) test) {
    type = test('type', type) ? null : type;
    name = test('name', name) ? null : name;
    mtime = test('mtime', mtime) ? null : mtime;
    description = test('description', description) ? null : description;
    color = test('color', color) ? null : color;
    data.removeWhere(test);
  }

  @override
  void update(String key, Function(dynamic value) update,
      {Function()? ifAbsent}) {
    switch (key) {
      case 'type':
        type = update(type);
        break;
      case 'name':
        name = update(name);
        break;
      case 'mtime':
        mtime = update(mtime);
        break;
      case 'description':
        description = update(description);
        break;
      case 'color':
        color = update(color);
        break;
      default:
        data.update(key, update, ifAbsent: ifAbsent);
    }
  }

  @override
  void updateAll(Function(String key, dynamic value) update) {
    type = update('type', type);
    name = update('name', name);
    mtime = update('mtime', mtime);
    description = update('description', description);
    color = update('color', color);
    data.updateAll(update);
  }

  @override
  // TODO: implement values
  Iterable get values =>
      [type, name, mtime, description, color, ...data.values].map((e) => e);
}

//  typedef ItemMetadata<T> = {
//   type?: string;
//   name?: string; // The name of the item, e.g. filename in case of files
//   mtime?: number; // The modification time
//
//   description?: string;
//   color?: string;
// } & T;

typedef ChunkJson = SumType<base64, Uint8List?>;

class CollectionItemRevisionJsonWrite {
  base64 uid;
  Uint8List meta;

  List<ChunkJson> chunks;
  bool deleted;

  CollectionItemRevisionJsonWrite({
    required this.uid,
    required this.meta,
    required this.chunks,
    required this.deleted,
  });
}

typedef CollectionItemRevisionJsonRead = CollectionItemRevisionJsonWrite;

class CollectionItemJsonWrite {
  base64 uid;
  int version;

  Uint8List? encryptionKey;
  CollectionItemRevisionJsonWrite content;

  String? etag;

  CollectionItemJsonWrite({
    required this.uid,
    required this.version,
    this.encryptionKey,
    required this.content,
    this.etag,
  });
}

typedef CollectionItemJsonRead = CollectionItemJsonWrite;

enum CollectionAccessLevel {
  ReadOnly, // = 0,
  Admin, // = 1,
  ReadWrite, // = 2,
}

class CollectionJsonWrite {
  Uint8List collectionKey;
  CollectionItemJsonWrite item;

  Uint8List collectionType;

  CollectionJsonWrite(
      {required this.collectionKey,
      required this.item,
      required this.collectionType});
}

class CollectionJsonRead extends CollectionJsonWrite {
  CollectionAccessLevel accessLevel;
  String? stoken; // FIXME: hack, we shouldn't expose it here...

  @override
  CollectionItemJsonRead item;

  CollectionJsonRead({
    required this.accessLevel,
    this.stoken,
    required this.item,
    required Uint8List collectionKey,
    required Uint8List collectionType,
  }) : super(
            item: item,
            collectionKey: collectionKey,
            collectionType: collectionType);
}

class SignedInvitationWrite {
  base64 uid;
  int version;
  String username;

  base64 collection;
  CollectionAccessLevel accessLevel;

  Uint8List signedEncryptionKey;

  SignedInvitationWrite({
    required this.uid,
    required this.version,
    required this.username,
    required this.collection,
    required this.accessLevel,
    required this.signedEncryptionKey,
  });
}

class SignedInvitationRead extends SignedInvitationWrite {
  String? fromUsername;
  Uint8List? fromPubkey;

  SignedInvitationRead({
    this.fromUsername,
    this.fromPubkey,
    required String uid,
    required int version,
    required CollectionAccessLevel accessLevel,
    required String collection,
    required Uint8List signedEncryptionKey,
    required String username,
  }) : super(
            uid: uid,
            version: version,
            accessLevel: accessLevel,
            collection: collection,
            signedEncryptionKey: signedEncryptionKey,
            username: username);
}

base64 genUidBase64() {
  return toBase64(utf8.decode(randomBytes(24)));
}

class MainCryptoManager extends CryptoManager {
  // final _Main = true; // So classes are different

  MainCryptoManager(Uint8List key, [int version = Constants.CURRENT_VERSION])
      : super(key, 'Main', version);

  LoginCryptoManager getLoginCryptoManager() {
    return LoginCryptoManager.keygen(asymKeySeed);
  }

  AccountCryptoManager getAccountCryptoManager(Uint8List privkey) {
    return AccountCryptoManager(privkey, version);
  }

  BoxCryptoManager getIdentityCryptoManager(Uint8List privkey) {
    return BoxCryptoManager.fromPrivkey(privkey);
  }
}

class AccountCryptoManager extends CryptoManager {
  final Account = true; // So classes are different
  final _colTypePadSize = 32;

  AccountCryptoManager(Uint8List key, [int version = Constants.CURRENT_VERSION])
      : super(key, 'Acct', version);

  Uint8List colTypeToUid(String colType) {
    return deterministicEncrypt(
        bufferPadFixed(fromString(colType), _colTypePadSize));
  }

  String colTypeFromUid(Uint8List colTypeUid) {
    return toString(
        bufferUnpadFixed(deterministicDecrypt(colTypeUid), _colTypePadSize));
  }
}

class MinimalCollectionCryptoManager extends CryptoManager {
  final Collection = true; // So classes are different

  MinimalCollectionCryptoManager(Uint8List key,
      [int version = Constants.CURRENT_VERSION])
      : super(key, 'Col', version);
}

class CollectionCryptoManager extends MinimalCollectionCryptoManager {
  final AccountCryptoManager _accountCryptoManager;

  AccountCryptoManager get accountCryptoManager => _accountCryptoManager;

  CollectionCryptoManager(this._accountCryptoManager, Uint8List key,
      [int version = Constants.CURRENT_VERSION])
      : super(key, version);
}

class CollectionItemCryptoManager extends CryptoManager {
  final CollectionItem = true; // So classes are different

  CollectionItemCryptoManager(Uint8List key,
      [int version = Constants.CURRENT_VERSION])
      : super(key, 'ColItem', version);
}

class StorageCryptoManager extends CryptoManager {
  final Storage = true; // So classes are different

  StorageCryptoManager(Uint8List key, [version = Constants.CURRENT_VERSION])
      : super(key, 'Stor', version);
}

MainCryptoManager getMainCryptoManager(
    Uint8List mainEncryptionKey, int version) {
  return MainCryptoManager(mainEncryptionKey, version);
}

class EncryptedRevision<CM extends CollectionItemCryptoManager> {
  late base64 uid;
  late Uint8List meta;
  late bool deleted;
  late List<SumType<base64, Uint8List?>> chunks;

  EncryptedRevision() : deleted = false;

  static Future<EncryptedRevision<CM>>
      create<CM extends CollectionItemCryptoManager>(CM cryptoManager,
          Uint8List additionalData, dynamic meta, Uint8List content) async {
    final ret = EncryptedRevision<CM>();
    ret.chunks = [];
    ret.setMeta(cryptoManager, additionalData, meta);
    await ret.setContent(cryptoManager, additionalData, content);

    return ret;
  }

  static EncryptedRevision<CM>
      deserialize<CM extends CollectionItemCryptoManager>(
          CollectionItemRevisionJsonRead json) {
    final uid = json.uid;
    final meta = json.meta;
    final chunks = json.chunks;
    final deleted = json.deleted;
    final ret = EncryptedRevision<CM>();
    ret.uid = uid;
    ret.meta = meta;
    ret.deleted = deleted;
    ret.chunks = chunks
        .map(
          (chunk) => SumType(chunk.one, chunk.two),
        )
        .toList();

    return ret;
  }

  CollectionItemRevisionJsonWrite serialize() {
    return CollectionItemRevisionJsonWrite(
      uid: uid,
      meta: meta,
      deleted: deleted,
      chunks: chunks.map((chunk) => SumType(chunk.one, chunk.two)).toList(),
    );
  }

  static EncryptedRevision<CM>
      cacheLoad<CM extends CollectionItemCryptoManager>(Uint8List cached_) {
    final cached = msgpackDecode(cached_) as List<dynamic>;

    final ret = EncryptedRevision<CM>();
    ret.uid = toBase64(cached[0]);
    ret.meta = cached[1];
    ret.deleted = cached[2];
    ret.chunks = cached[3].map((List<Uint8List> chunk) => [
          toBase64(utf8.decode(chunk[0])),
          chunk[1],
        ]);

    return ret;
  }

  Uint8List cacheSave(bool saveContent) {
    return msgpackEncode([
      fromBase64(uid),
      meta,
      deleted,
      ((saveContent)
          ? chunks.map((chunk) => [fromBase64(chunk.one), chunk.two])
          : chunks.map((chunk) => [fromBase64(chunk.one)])),
    ]);
  }

  bool verify(CM cryptoManager, Uint8List additionalData) {
    final adHash = _calculateAdHash(cryptoManager, additionalData);
    final mac = fromBase64(uid);

    try {
      cryptoManager.verify(meta, mac, adHash);
      return true;
    } catch (e) {
      throw IntegrityError('mac verification failed.');
    }
  }

  dynamic _calculateAdHash(CM cryptoManager, Uint8List additionalData) {
    final cryptoMac = cryptoManager.getCryptoMac();
    cryptoMac.update(Uint8List.fromList([(deleted) ? 1 : 0]));
    cryptoMac.updateWithLenPrefix(additionalData);

    // We hash the chunks separately so that the server can (in the future) return just the hash instead of the full
    // chunk list if requested - useful for asking for collection updates
    final chunksHash = cryptoManager.getCryptoMac(false);
    chunks.forEach((chunk) => chunksHash.update(fromBase64(chunk.one)));

    cryptoMac.update(chunksHash.finalize());

    return cryptoMac.finalize();
  }

  void setMeta(CM cryptoManager, Uint8List additionalData, dynamic meta) {
    final adHash = _calculateAdHash(cryptoManager, additionalData);

    final encContent = cryptoManager.encryptDetached(
        bufferPadSmall(msgpackEncode(meta)), adHash);

    this.meta = encContent[1];
    uid = toBase64(String.fromCharCodes(encContent[0]));
  }

  dynamic getMeta(CM cryptoManager, Uint8List additionalData) {
    final mac = fromBase64(uid);
    final adHash = _calculateAdHash(cryptoManager, additionalData);

    return msgpackDecode(
        bufferUnpad(cryptoManager.decryptDetached(meta, mac, adHash)));
  }

  Future<void> setContent(
      CM cryptoManager, Uint8List additionalData, Uint8List content) async {
    final meta = getMeta(cryptoManager, additionalData);

    var chunks = <SumType<base64, Uint8List>>[];

    const minChunk = 1 << 14;
    const maxChunk = 1 << 16;
    var chunkStart = 0;

// Only try chunking if our content is larger than the minimum chunk size
    if (content.length > minChunk) {
// FIXME: figure out what to do with mask - should it be configurable?
      final buzhash = cryptoManager.getChunker();
      const mask = (1 << 12) - 1;

      var pos = 0;
      while (pos < content.length) {
        buzhash.update(content[pos]);
        if (pos - chunkStart >= minChunk) {
          if ((pos - chunkStart >= maxChunk) || (buzhash.split(mask))) {
            final buf = content.sublist(chunkStart, pos);
            final hash = toBase64(utf8.decode(cryptoManager.calculateMac(buf)));
            chunks.add(SumType(hash, buf));
            chunkStart = pos;
          }
        }
        pos++;
      }
    }

    if (chunkStart < content.length) {
      final buf = content.sublist(chunkStart);
      final hash = toBase64(utf8.decode(cryptoManager.calculateMac(buf)));
      chunks.add(SumType(hash, buf));
    }

// Shuffle the items and save the ordering if we have more than one
    if (chunks.isNotEmpty) {
      final indices = shuffle(chunks);

      // Filter duplicates and construct the indice list.
      final uidIndices = <String, int>{};
      chunks = chunks.where((chunk) {
        final i = chunks.indexWhere((e) => e == chunk);
        final uid = chunk.one;
        final previousIndex = uidIndices[uid];
        if (previousIndex != null) {
          indices[i] = previousIndex;
          return false;
        } else {
          uidIndices[uid] = i;
          return true;
        }
      }).toList();

      // If we have more than one chunk we need to encode the mapping header in the last chunk
      if (indices.length > 1) {
        // We encode it in an array so we can extend it later on if needed
        final buf = msgpackEncode([indices]);
        final hash = toBase64(utf8.decode(cryptoManager.calculateMac(buf)));
        chunks.add(SumType(hash, buf));
      }
    }

// Encrypt all of the chunks
    this.chunks = chunks
        .map((chunk) =>
            SumType(chunk.one, cryptoManager.encrypt(bufferPad(chunk.two))))
        .toList();

    setMeta(cryptoManager, additionalData, meta);
  }

  Future<Uint8List> getContent(CM cryptoManager) async {
    var indices = <int>[0];
    var decryptedChunks = chunks.map((chunk) {
      if (chunk.two == null) {
        throw MissingContentError(
            'Missing content for item. Please download it using "downloadContent"');
      }

      final buf = bufferUnpad(cryptoManager.decrypt(chunk.two!));
      final hash = cryptoManager.calculateMac(buf);
      if (!memcmp(hash, fromBase64(chunk.one))) {
        throw IntegrityError(
            'The content\'s mac is different to the expected mac (${chunk.one})');
      }
      return buf;
    }).toList();

// If we have more than one chunk we have the mapping header in the last chunk
    if (chunks.length > 1) {
      final lastChunk =
          msgpackDecode(decryptedChunks.removeLast()) as List<List<int>>;
      indices = lastChunk[0];
    }

// We need to unshuffle the chunks
    if (indices.length > 1) {
      final sortedChunks = <Uint8List>[];
      for (final index in indices) {
        sortedChunks.add(decryptedChunks[index]);
      }

      return concatArrayBuffersArrays(sortedChunks);
    } else if (decryptedChunks.isNotEmpty) {
      return decryptedChunks[0];
    } else {
      return Uint8List.fromList([]);
    }
  }

  void delete(
      CM cryptoManager, Uint8List additionalData, bool preserveContent) {
    final meta = getMeta(cryptoManager, additionalData);

    if (!preserveContent) {
      chunks = [];
    }
    deleted = true;

    setMeta(cryptoManager, additionalData, meta);
  }

  EncryptedRevision<CM> clone() {
    final rev = EncryptedRevision<CM>();
    rev.uid = uid;
    rev.meta = meta;
    rev.chunks = chunks;
    rev.deleted = deleted;
    return rev;
  }
}

class EncryptedCollection {
  late Uint8List _collectionKey;
  Uint8List? _collectionType;
  late EncryptedCollectionItem item;

  late CollectionAccessLevel accessLevel;
  late String? stoken; // FIXME: hack, we shouldn't expose it here...

  static Future<EncryptedCollection> create<T>(
      AccountCryptoManager parentCryptoManager,
      String collectionTypeName,
      ItemMetadata/*<T>*/ meta,
      Uint8List content) async {
    final ret = EncryptedCollection();
    ret._collectionType = parentCryptoManager.colTypeToUid(collectionTypeName);
    ret._collectionKey = parentCryptoManager.encrypt(
        randomBytes(symmetricKeyLength), ret._collectionType);

    ret.accessLevel = CollectionAccessLevel.Admin;
    ret.stoken = null;

    final cryptoManager =
        ret.getCryptoManager(parentCryptoManager, Constants.CURRENT_VERSION);

    ret.item =
        await EncryptedCollectionItem.create(cryptoManager, meta, content);

    return ret;
  }

  static EncryptedCollection deserialize(CollectionJsonRead json) {
    final stoken = json.stoken;
    final accessLevel = json.accessLevel;
    final collectionType = json.collectionType;
    final collectionKey = json.collectionKey;
    final ret = EncryptedCollection();
    ret._collectionKey = collectionKey;

    ret.item = EncryptedCollectionItem.deserialize(json.item);
    ret._collectionType = collectionType;

    ret.accessLevel = accessLevel;
    ret.stoken = stoken;

    return ret;
  }

  CollectionJsonWrite serialize() {
    return CollectionJsonWrite(
      item: item.serialize(),
      collectionType: _collectionType!,
      collectionKey: _collectionKey,
    );
  }

  static EncryptedCollection cacheLoad(Uint8List cached_) {
    final cached = msgpackDecode(cached_) as List<dynamic>;

    final ret = EncryptedCollection();
    ret._collectionKey = cached[1];
    ret.accessLevel = cached[2];
    ret.stoken = cached[3];
    ret.item = EncryptedCollectionItem.cacheLoad(cached[4]);
    ret._collectionType = cached[5];

    return ret;
  }

  Uint8List cacheSave(bool saveContent) {
    return msgpackEncode([
      1, // Cache version format
      _collectionKey,
      accessLevel,
      stoken,

      item.cacheSave(saveContent),
      _collectionType,
    ]);
  }

  void markSaved() {
    item.markSaved();
  }

  bool verify(MinimalCollectionCryptoManager cryptoManager) {
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    return item.verify(itemCryptoManager);
  }

  void setMeta<T>(
      MinimalCollectionCryptoManager cryptoManager, ItemMetadata/*<T>*/ meta) {
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    item.setMeta(itemCryptoManager, meta);
  }

  ItemMetadata getMeta<T>(MinimalCollectionCryptoManager cryptoManager) {
    verify(cryptoManager);
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    return item.getMeta(itemCryptoManager);
  }

  Future<void> setContent(
      MinimalCollectionCryptoManager cryptoManager, Uint8List content) async {
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    return item.setContent(itemCryptoManager, content);
  }

  Future<Uint8List> getContent(
      MinimalCollectionCryptoManager cryptoManager) async {
    verify(cryptoManager);
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    return item.getContent(itemCryptoManager);
  }

  void delete(
      MinimalCollectionCryptoManager cryptoManager, bool preserveContent) {
    final itemCryptoManager = item.getCryptoManager(cryptoManager);
    item.delete(itemCryptoManager, preserveContent);
  }

  bool get isDeleted => item.isDeleted;

  base64 get uid => item.uid;

  base64 get etag => item.etag;

  String? get lastEtag => item.lastEtag;

  int get version => item.version;

  String getCollectionType(AccountCryptoManager parentCryptoManager) {
    // FIXME: remove this condition "collection-type-migration" is done
    if (_collectionType == null) {
      final cryptoManager = getCryptoManager(parentCryptoManager);
      final meta = getMeta(cryptoManager);
      return meta.type!;
    }
    return parentCryptoManager.colTypeFromUid(_collectionType!);
  }

  Future<SignedInvitationWrite> createInvitation(
      AccountCryptoManager parentCryptoManager,
      BoxCryptoManager identCryptoManager,
      String username,
      Uint8List pubkey,
      CollectionAccessLevel accessLevel) async {
    final uid = randomBytes(32);
    final encryptionKey = _getCollectionKey(parentCryptoManager);
    final collectiontypedef = getCollectionType(parentCryptoManager);
    final content = SignedInvitationContent(
        encryptionKey: encryptionKey, collectionType: collectiontypedef);
    final rawContent = bufferPadSmall(msgpackEncode(content));
    final signedEncryptionKey = identCryptoManager.encrypt(rawContent, pubkey);
    final ret = SignedInvitationWrite(
      version: Constants.CURRENT_VERSION,
      uid: toBase64(String.fromCharCodes(uid)),
      username: username,
      collection: this.uid,
      accessLevel: accessLevel,
      signedEncryptionKey: signedEncryptionKey,
    );

    return ret;
  }

  CollectionCryptoManager getCryptoManager(
      AccountCryptoManager parentCryptoManager,
      [int? version]) {
    final encryptionKey = _getCollectionKey(parentCryptoManager);

    return CollectionCryptoManager(
        parentCryptoManager, encryptionKey, version ?? this.version);
  }

  Uint8List _getCollectionKey(AccountCryptoManager parentCryptoManager) {
    // FIXME: remove the ?? null once "collection-type-migration" is done
    return parentCryptoManager
        .decrypt(_collectionKey, _collectionType)
        .sublist(0, symmetricKeyLength);
  }
}

class EncryptedCollectionItem {
  late base64 uid;
  late int version;
  late Uint8List? encryptionKey;
  late EncryptedRevision<CollectionItemCryptoManager> _content;

  late String? lastEtag;

  EncryptedCollectionItem();

  static Future<EncryptedCollectionItem> create(
      MinimalCollectionCryptoManager parentCryptoManager,
      ItemMetadata meta,
      Uint8List content) async {
    final ret = EncryptedCollectionItem();
    ret.uid = genUidBase64();
    ret.version = Constants.CURRENT_VERSION;
    ret.encryptionKey = null;

    ret.lastEtag = null;

    final cryptoManager = ret.getCryptoManager(parentCryptoManager);

    ret._content = await EncryptedRevision.create(
        cryptoManager, ret.getAdditionalMacData(), meta, content);

    return ret;
  }

  static EncryptedCollectionItem deserialize(CollectionItemJsonRead json) {
    final ret = EncryptedCollectionItem();
    ret.uid = json.uid;
    ret.version = json.version;
    ret.encryptionKey = json.encryptionKey;

    ret._content = EncryptedRevision.deserialize(json.content);

    ret.lastEtag = ret._content.uid;

    return ret;
  }

  CollectionItemJsonWrite serialize() {
    return CollectionItemJsonWrite(
      uid: uid,
      version: version,
      // encryptionKey: this.encryptionKey ?? undefined,
      etag: lastEtag,

      content: _content.serialize(),
    );
  }

  static EncryptedCollectionItem cacheLoad(Uint8List cached_) {
    final cached = msgpackDecode(cached_);

    final ret = EncryptedCollectionItem();
    ret.uid = toBase64(cached[1]);
    ret.version = cached[2];
    ret.encryptionKey = cached[3];
    ret.lastEtag = (cached[4]) ? toBase64(cached[4]) : null;

    ret._content = EncryptedRevision.cacheLoad(cached[5]);

    return ret;
  }

  Uint8List cacheSave(bool saveContent) {
    return msgpackEncode([
      1, // Cache version format
      fromBase64(uid),
      version,
      encryptionKey,
      lastEtag != null ? fromBase64(lastEtag!) : null,

      _content.cacheSave(saveContent),
    ]);
  }

  void markSaved() {
    lastEtag = _content.uid;
  }

  List<ChunkJson> getPendingChunks() {
    return _content.chunks;
  }

  List<ChunkJson> getMissingChunks() {
    return _content.chunks.where((sum) => sum.two == null).toList();
  }

  bool _isLocallyChanged() {
    return lastEtag != _content.uid;
  }

  bool verify(CollectionItemCryptoManager cryptoManager) {
    return _content.verify(cryptoManager, getAdditionalMacData());
  }

  void setMeta<T>(
      CollectionItemCryptoManager cryptoManager, ItemMetadata meta) {
    var rev = _content;
    if (!_isLocallyChanged()) {
      rev = _content.clone();
    }
    rev.setMeta(cryptoManager, getAdditionalMacData(), meta);

    _content = rev;
  }

  ItemMetadata getMeta<T>(CollectionItemCryptoManager cryptoManager) {
    verify(cryptoManager);
    return _content.getMeta(cryptoManager, getAdditionalMacData());
  }

  Future<void> setContent(
      CollectionItemCryptoManager cryptoManager, Uint8List content) async {
    var rev = _content;
    if (!_isLocallyChanged()) {
      rev = _content.clone();
    }
    await rev.setContent(cryptoManager, getAdditionalMacData(), content);

    _content = rev;
  }

  Future<Uint8List> getContent(
      CollectionItemCryptoManager cryptoManager) async {
    verify(cryptoManager);
    return _content.getContent(cryptoManager);
  }

  void delete(CollectionItemCryptoManager cryptoManager, bool preserveContent) {
    var rev = _content;
    if (!_isLocallyChanged()) {
      rev = _content.clone();
    }
    rev.delete(cryptoManager, getAdditionalMacData(), preserveContent);

    _content = rev;
  }

  bool get isDeleted => _content.deleted;

  base64 get etag => _content.uid;

  bool get isMissingContent => _content.chunks.any((sum) => sum.two == null);

  CollectionItemCryptoManager getCryptoManager(
      MinimalCollectionCryptoManager parentCryptoManager) {
    final encryptionKey = this.encryptionKey != null
        ? parentCryptoManager.decrypt(this.encryptionKey!)
        : parentCryptoManager.deriveSubkey(fromString(uid));

    return CollectionItemCryptoManager(encryptionKey, version);
  }

  MinimalCollectionCryptoManager getHierarchicalCryptoManager(
      MinimalCollectionCryptoManager parentCryptoManager) {
    final encryptionKey = this.encryptionKey != null
        ? parentCryptoManager.decrypt(this.encryptionKey!)
        : parentCryptoManager.deriveSubkey(fromString(uid));

    return MinimalCollectionCryptoManager(encryptionKey, version);
  }

  Uint8List getAdditionalMacData() {
    return fromString(uid);
  }
}
