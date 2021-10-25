// import URI from "urijs";
//
// import * as Constants from "./Constants";
//
// import { deriveKey, concatArrayBuffers, BoxCryptoManager, ready } from "./Crypto";
// export { ready, getPrettyFingerprint, _setRnSodium, deriveKey, KeyDerivationDifficulty } from "./Crypto";
// import { ConflictError, UnauthorizedError } from "./Exceptions";
// export * from "./Exceptions";
// import { base64, fromBase64, toBase64, fromString, toString, randomBytes, symmetricKeyLength, msgpackEncode, msgpackDecode, bufferUnpad } from "./Helpers";
// export { base64, fromBase64, toBase64, randomBytes } from "./Helpers";
//
// import {
//   CollectionAccessLevel,
//   CollectionCryptoManager,
//   MinimalCollectionCryptoManager,
//   CollectionItemCryptoManager,
//   ItemMetadata,
//   EncryptedCollection,
//   EncryptedCollectionItem,
//   getMainCryptoManager,
//   StorageCryptoManager,
// } from "./EncryptedModels";
// export * from "./EncryptedModels"; // FIXME: cherry-pick what we export
// import {
//   Authenticator,
//   CollectionManagerOnline,
//   CollectionItemManagerOnline,
//   CollectionItemListResponse,
//   CollectionInvitationManagerOnline,
//   CollectionMemberManagerOnline,
//   FetchOptions,
//   ItemFetchOptions,
//   LoginResponseUser,
//   User,
//   MemberFetchOptions,
//   InvitationFetchOptions,
//   RevisionsFetchOptions,
//   WebSocketHandle,
// } from "./OnlineManagers";
// import { ProgrammingError } from "./Exceptions";
// export { User, CollectionMember, FetchOptions, ItemFetchOptions } from "./OnlineManagers";
//
// import { CURRENT_VERSION } from "./Constants";
// export { CURRENT_VERSION } from "./Constants";

import 'dart:convert';
import 'dart:typed_data';

import 'Constants.dart';
import 'Crypto.dart';
import 'EncryptedModels.dart';
import 'Exceptions.dart';
import 'Helpers.dart';
import 'OnlineManagers.dart';

class AccountData {
  int version;
  Uint8List key;
  LoginResponseUser user;
  String serverUrl;
  String? authToken;

  AccountData(
      {required this.version,
      required this.key,
      required this.user,
      required this.serverUrl,
      this.authToken});
}

class AccountDataStored {
  int version;
  Uint8List encryptedData;

  AccountDataStored({required this.version, required this.encryptedData});
}

class Account {
  Uint8List _mainKey;
  int _version;
  LoginResponseUser user;
  late String serverUrl;
  String? authToken;

  Account._(Uint8List mainEncryptionKey, int version, this.user)
      : _mainKey = mainEncryptionKey,
        _version = version,
        authToken = null;

  static Future<bool> isEtebaseServer(String serverUrl) async {
    final authenticator = Authenticator(serverUrl);
    return authenticator.isEtebase();
  }

  static Future<Account> signup(
      User user, String password, String? serverUrl) async {
    await ready;

    serverUrl = serverUrl ?? Constants.SERVER_URL;
    final authenticator = Authenticator(serverUrl);
    final version = Constants.CURRENT_VERSION;
    final salt = randomBytes(32);

    final mainKey = await deriveKey(salt, password);
    final mainCryptoManager = getMainCryptoManager(mainKey, version);
    final loginCryptoManager = mainCryptoManager.getLoginCryptoManager();

    final identityCryptoManager = BoxCryptoManager.keygen();

    final accountKey = randomBytes(symmetricKeyLength);
    final encryptedContent = mainCryptoManager
        .encrypt(concatArrayBuffers(accountKey, identityCryptoManager.privkey));

    final loginResponse = await authenticator.signup(
        user,
        salt,
        loginCryptoManager.pubkey,
        identityCryptoManager.pubkey,
        encryptedContent);

    final ret = Account._(mainKey, version, loginResponse.user);

    ret.authToken = loginResponse.token;
    ret.serverUrl = serverUrl;

    return ret;
  }

  static Future login(
      String username, String password, String? serverUrl) async {
    await ready;

    serverUrl = serverUrl ?? Constants.SERVER_URL;
    final authenticator = Authenticator(serverUrl);
    var loginChallenge;
    try {
      loginChallenge = await authenticator.getLoginChallenge(username);
    } catch (e) {
      if ((e is UnauthorizedError) && (e.content?.code == 'user_not_init')) {
        final user = User(username: username,  email: 'init@localhost');
        ;
        return signup(user, password, serverUrl);
      }

      rethrow;
    }

    final mainKey = await deriveKey(loginChallenge.salt, password);
    final mainCryptoManager =
        getMainCryptoManager(mainKey, loginChallenge.version);
    final loginCryptoManager = mainCryptoManager.getLoginCryptoManager();

    final response = msgpackEncode({
      'username': username,
      'challenge': loginChallenge.challenge,
      'host': Uri.parse(serverUrl).host,
      'action': 'login',
    });

    final loginResponse = await authenticator.login(
        response, loginCryptoManager.signDetached(response));

    final ret = Account._(mainKey, loginChallenge.version, loginResponse.user);

    ret.authToken = loginResponse.token;
    ret.serverUrl = serverUrl;

    return ret;
  }

  Future<void> fetchToken() async {
    final serverUrl = this.serverUrl;
    final authenticator = Authenticator(serverUrl);
    final username = user.username;
    final loginChallenge = await authenticator.getLoginChallenge(username);

    final mainKey = _mainKey;
    final mainCryptoManager =
        getMainCryptoManager(mainKey, loginChallenge.version);
    final loginCryptoManager = mainCryptoManager.getLoginCryptoManager();

    final response = msgpackEncode({
      'username': username,
      'challenge': loginChallenge.challenge,
      'host': Uri.parse(serverUrl).host,
      'action': 'login',
    });

    final loginResponse = await authenticator.login(
        response, loginCryptoManager.signDetached(response));

    authToken = loginResponse.token;
  }

  Future<void> logout() async {
    final authenticator = Authenticator(serverUrl);

    await authenticator.logout(authToken!);
    _version = -1;
    _mainKey = Uint8List(0);
    authToken = null;
  }

  Future<void> changePassword(String password) async {
    final serverUrl = this.serverUrl;
    final authenticator = Authenticator(serverUrl);
    final username = user.username;
    final loginChallenge = await authenticator.getLoginChallenge(username);

    final oldMainCryptoManager = getMainCryptoManager(_mainKey, _version);
    final content = oldMainCryptoManager.decrypt(user.encryptedContent);
    final oldLoginCryptoManager = oldMainCryptoManager.getLoginCryptoManager();

    final mainKey = await deriveKey(loginChallenge.salt, password);
    final mainCryptoManager = getMainCryptoManager(mainKey, _version);
    final loginCryptoManager = mainCryptoManager.getLoginCryptoManager();

    final encryptedContent = mainCryptoManager.encrypt(content);

    final response = msgpackEncode({
      'username': username,
      'challenge': loginChallenge.challenge,
      'host': Uri.parse(serverUrl).host,
      'action': 'changePassword',
      'loginPubkey': loginCryptoManager.pubkey,
      'encryptedContent': encryptedContent,
    });

    await authenticator.changePassword(
        authToken!, response, oldLoginCryptoManager.signDetached(response));

    _mainKey = mainKey;
    user.encryptedContent = encryptedContent;
  }

  Future<String> getDashboardUrl() async {
    final serverUrl = this.serverUrl;
    final authenticator = Authenticator(serverUrl);
    return await authenticator.getDashboardUrl(authToken!);
  }

  Future<base64> save([Uint8List? encryptionKey_]) async {
    final version = Constants.CURRENT_VERSION;
    final encryptionKey = encryptionKey_ ?? Uint8List(32);
    final cryptoManager = StorageCryptoManager(encryptionKey, version);

    final content = AccountData(
      user: user,
      authToken: authToken!,
      serverUrl: serverUrl,
      version: _version,
      key: cryptoManager.encrypt(_mainKey),
    );

    final ret = AccountDataStored(
      version: version,
      encryptedData: cryptoManager.encrypt(
          msgpackEncode(content), Uint8List.fromList([version])),
    );

    return toBase64(utf8.decode(msgpackEncode(ret)));
  }

  static Future restore(base64 accountDataStored_, [Uint8List? encryptionKey_]) async {
    await ready;

    final encryptionKey = encryptionKey_ ?? Uint8List(32);
    final accountDataStored =
        msgpackDecode(fromBase64(accountDataStored_)) as AccountDataStored;

    final cryptoManager =
        StorageCryptoManager(encryptionKey, accountDataStored.version);

    final accountData = msgpackDecode(cryptoManager.decrypt(
        accountDataStored.encryptedData,
        Uint8List.fromList([accountDataStored.version]))) as AccountData;

    final ret =
        Account._(cryptoManager.decrypt(accountData.key), accountData.version, accountData.user);
    ret.authToken = accountData.authToken;
    ret.serverUrl = accountData.serverUrl;

    return ret;
  }

  CollectionManager getCollectionManager() {
    return CollectionManager(this);
  }

  CollectionInvitationManager getInvitationManager() {
    return CollectionInvitationManager(this);
  }

  AccountCryptoManager _getCryptoManager() {
    // FIXME: cache this
    final mainCryptoManager = getMainCryptoManager(_mainKey, _version);
    final content = mainCryptoManager.decrypt(user.encryptedContent);
    return mainCryptoManager
        .getAccountCryptoManager(content.sublist(0, symmetricKeyLength));
  }

  BoxCryptoManager _getIdentityCryptoManager() {
    // FIXME: cache this
    final mainCryptoManager = getMainCryptoManager(_mainKey, _version);
    final content = mainCryptoManager.decrypt(user.encryptedContent);
    return mainCryptoManager
        .getIdentityCryptoManager(content.sublist(symmetricKeyLength));
  }
}

const defaultCacheOptions = {
  'saveContent': true,
};

class CollectionManager {
  final Account _etebase;
  final CollectionManagerOnline _onlineManager;

  CollectionManager(this._etebase)
      : _onlineManager =
            CollectionManagerOnline(AccountOnlineData.fromAccount(_etebase));

  Future<Collection> create<T>(
      String colType, ItemMetadata meta, dynamic content) async {
    final uInt8ListContent = content is Uint8List ? content : Uint8List.fromList(utf8.encode(content.toString()));
    final mainCryptoManager = _etebase._getCryptoManager();
    final encryptedCollection = await EncryptedCollection.create(
        mainCryptoManager, colType, meta, uInt8ListContent);
    return Collection(encryptedCollection.getCryptoManager(mainCryptoManager),
        encryptedCollection);
  }

  Future fetch(base64 colUid, [FetchOptions? options]) async {
    final mainCryptoManager = _etebase._getCryptoManager();
    final encryptedCollection = await _onlineManager.fetch(colUid, options);
    return Collection(encryptedCollection.getCryptoManager(mainCryptoManager),
        encryptedCollection);
  }

  Future<CollectionItemListResponse<Collection>> list(
      List<String> colTypes, [FetchOptions? options]) async {
    final mainCryptoManager = _etebase._getCryptoManager();
    final collectionTypes =
        colTypes.map((x) => mainCryptoManager.colTypeToUid(x));
    final ret = await _onlineManager.list(collectionTypes.toList(), options);
    return CollectionItemListResponse(
      stoken: ret.stoken,
      done: ret.done,
      data: ret.data
          .map((x) => Collection(x.getCryptoManager(mainCryptoManager), x))
          .toList(),
    );
  }

  Future upload(Collection collection, [FetchOptions? options]) async {
    final col = collection._encryptedCollection;
    // If we have a etag, it means we previously fetched it.
    if (col.lastEtag != null) {
      final itemOnlineManager = CollectionItemManagerOnline(
          AccountOnlineData.fromAccount(_etebase), col.uid);
      await itemOnlineManager.batch(
          [col.item],
          null,
          ItemFetchOptions(
              limit: options?.limit,
              prefetch: options?.prefetch,
              stoken: options?.stoken));
    } else {
      await _onlineManager.create(col, options);
    }
    col.markSaved();
  }

  Future transaction(Collection collection, [FetchOptions? options]) async {
    final col = collection._encryptedCollection;
    // If we have a etag, it means we previously fetched it.
    if (col.lastEtag != null) {
      final itemOnlineManager = CollectionItemManagerOnline(
          AccountOnlineData.fromAccount(_etebase), col.uid);
      await itemOnlineManager.transaction(
          [col.item],
          null,
          ItemFetchOptions(
            stoken: options?.stoken,
            prefetch: options?.prefetch,
            limit: options?.limit,
          ));
    } else {
      await _onlineManager.create(col, options);
    }
    col.markSaved();
  }

  Uint8List cacheSave(Collection collection,
      [Map options = defaultCacheOptions]) {
    return collection._encryptedCollection.cacheSave(options['saveContent']);
  }

  Collection cacheLoad(Uint8List cache) {
    final encCol = EncryptedCollection.cacheLoad(cache);
    final mainCryptoManager = _etebase._getCryptoManager();
    return Collection(encCol.getCryptoManager(mainCryptoManager), encCol);
  }

  ItemManager getItemManager(Collection col_) {
    final col = col_._encryptedCollection;
    final collectionCryptoManager =
        col.getCryptoManager(_etebase._getCryptoManager());
    return ItemManager(_etebase, collectionCryptoManager, col.uid);
  }

  CollectionMemberManager getMemberManager(Collection col) {
    return CollectionMemberManager(_etebase, this, col._encryptedCollection);
  }
}

class ItemManager {
  final MinimalCollectionCryptoManager _collectionCryptoManager;
  final CollectionItemManagerOnline _onlineManager;
  final String _collectionUid; // The uid of the collection this item belongs to

  ItemManager(
      Account etebase, this._collectionCryptoManager, this._collectionUid)
      : _onlineManager = CollectionItemManagerOnline(
            AccountOnlineData.fromAccount(etebase), _collectionUid);

  Future<Item> create<T>(ItemMetadata meta, dynamic content) async {
    final uInt8ListContent = content is Uint8List ? content : Uint8List.fromList(utf8.encode(content));
    final encryptedItem = await EncryptedCollectionItem.create(
        _collectionCryptoManager, meta, content);
    return Item(
      _collectionUid,
      encryptedItem.getCryptoManager(_collectionCryptoManager),
      encryptedItem,
    );
  }

  Future<Item> fetch(base64 itemUid, [ItemFetchOptions? options]) async {
    final encryptedItem = await _onlineManager.fetch(itemUid, options);
    return Item(
        _collectionUid,
        encryptedItem.getCryptoManager(_collectionCryptoManager),
        encryptedItem);
  }

  Future<CollectionItemListResponse<Item>> list(
      [ItemFetchOptions? options]) async {
    final ret = await _onlineManager.list(options);
    return CollectionItemListResponse(
      done: ret.done,
      stoken: ret.stoken,
      data: ret.data
          .map((x) => Item(
              _collectionUid, x.getCryptoManager(_collectionCryptoManager), x))
          .toList(),
    );
  }

  Future<IteratorListResponse<Item>> itemRevisions(Item item,
      [RevisionsFetchOptions? options]) async {
    final ret = await _onlineManager.itemRevisions(item.encryptedItem, options);
    return IteratorListResponse(
      done: ret.done,
      iterator: ret.iterator,
      data: ret.data
          .map((x) => Item(
              _collectionUid, x.getCryptoManager(_collectionCryptoManager), x))
          .toList(),
    );
  }

  // Prepare the items for upload and verify they belong to the right collection
  List<EncryptedCollectionItem>? _itemsPrepareForUpload([List<Item>? items]) {
    return items?.map((x) {
      if (x.collectionUid != _collectionUid) {
        throw ProgrammingError(
            'Uploading an item belonging to collection ${x.collectionUid} to another collection ($_collectionUid) is not allowed!');
      }
      return x.encryptedItem;
    }).toList();
  }

  Future<CollectionItemListResponse<Item>> fetchUpdates(List<Item> items,
      [ItemFetchOptions? options]) async {
    final ret = await _onlineManager.fetchUpdates(
        _itemsPrepareForUpload(items)!, options);
    return CollectionItemListResponse(
      stoken: ret.stoken,
      done: ret.done,
      data: ret.data
          .map((x) => Item(
              _collectionUid, x.getCryptoManager(_collectionCryptoManager), x))
          .toList(),
    );
  }

  Future<CollectionItemListResponse<Item>> fetchMulti(List<base64> items,
      [ItemFetchOptions? options]) async {
    final ret = await _onlineManager.fetchMulti(items, options);
    return CollectionItemListResponse(
      stoken: ret.stoken,
      done: ret.done,
      data: ret.data
          .map((x) => Item(
              _collectionUid, x.getCryptoManager(_collectionCryptoManager), x))
          .toList(),
    );
  }

  Future batch(List<Item> items,
      [List<Item>? deps, ItemFetchOptions? options]) async {
    await _onlineManager.batch(
        _itemsPrepareForUpload(items)!, _itemsPrepareForUpload(deps), options);
    items.forEach((item) => {item.encryptedItem.markSaved()});
  }

  Future transaction(List<Item> items,
      [List<Item>? deps, ItemFetchOptions? options]) async {
    await _onlineManager.transaction(
        _itemsPrepareForUpload(items)!, _itemsPrepareForUpload(deps), options);
    items.forEach((item) => {item.encryptedItem.markSaved()});
  }

  Future uploadContent(Item item) async {
    final encryptedItem = _itemsPrepareForUpload([item])![0];
    final pendingChunks = encryptedItem.getPendingChunks();
    for (final chunk in pendingChunks) {
      // FIXME: Upload multiple in parallel
      try {
        await _onlineManager.chunkUpload(encryptedItem, chunk);
      } catch (e) {
        if (e is ConflictError) {
          // Skip if we arleady have the chunk
          continue;
        }
        rethrow;
      }
    }
  }

  Future downloadContent(Item item) async {
    final encryptedItem = _itemsPrepareForUpload([item])![0];
    final missingChunks = encryptedItem.getMissingChunks();
    for (final chunk in missingChunks) {
      chunk.two ??=
          await _onlineManager.chunkDownload(encryptedItem, chunk.one);
    }
  }

  Future<WebSocketHandle> subscribeChanges(
      void Function(CollectionItemListResponse<Item> data) cb,
      [ItemFetchOptions? options]) async {
    return _onlineManager.subscribeChanges((ret) async {
      cb(CollectionItemListResponse(
        stoken: ret.stoken,
        done: ret.done,
        data: ret.data
            .map((x) => Item(_collectionUid,
                x.getCryptoManager(_collectionCryptoManager), x))
            .toList(),
      ));
    }, options);
  }

  Uint8List cacheSave(Item item, [options = defaultCacheOptions]) {
    return item.encryptedItem.cacheSave(options.saveContent);
  }

  Item cacheLoad(Uint8List cache) {
    final encItem = EncryptedCollectionItem.cacheLoad(cache);
    return Item(_collectionUid,
        encItem.getCryptoManager(_collectionCryptoManager), encItem);
  }
}

class SignedInvitationContent {
  Uint8List encryptionKey;
  String collectionType;

  SignedInvitationContent(
      {required this.encryptionKey, required this.collectionType});
}

class SignedInvitation {
  base64 uid;
  int version;
  String username;

  base64 collection;
  CollectionAccessLevel accessLevel;

  Uint8List signedEncryptionKey;
  String? fromUsername;
  Uint8List fromPubkey;

  SignedInvitation({
    required this.uid,
    required this.version,
    required this.username,
    required this.collection,
    required this.accessLevel,
    required this.signedEncryptionKey,
    this.fromUsername,
    required this.fromPubkey,
  });

  SignedInvitationRead toSignedInvitationRead() {
    return SignedInvitationRead(
      uid: uid,
      version: version,
      accessLevel: accessLevel,
      collection: collection,
      signedEncryptionKey: signedEncryptionKey,
      username: username,
    );
  }
}

class CollectionInvitationManager {
  final Account _etebase;
  final CollectionInvitationManagerOnline _onlineManager;

  CollectionInvitationManager(this._etebase)
      : _onlineManager = CollectionInvitationManagerOnline(
            AccountOnlineData.fromAccount(_etebase));

  Future listIncoming([InvitationFetchOptions? options]) async {
    return await _onlineManager.listIncoming(options);
  }

  Future listOutgoing([InvitationFetchOptions? options]) async {
    return await _onlineManager.listOutgoing(options);
  }

  Future accept(SignedInvitation invitation) async {
    final mainCryptoManager = _etebase._getCryptoManager();
    final identCryptoManager = _etebase._getIdentityCryptoManager();
    final content = msgpackDecode(bufferUnpad(identCryptoManager.decrypt(
            invitation.signedEncryptionKey, invitation.fromPubkey)))
        as SignedInvitationContent;
    final colTypeUid = mainCryptoManager.colTypeToUid(content.collectionType);
    final encryptedEncryptionKey =
        mainCryptoManager.encrypt(content.encryptionKey, colTypeUid);
    return _onlineManager.accept(invitation.toSignedInvitationRead(),
        colTypeUid, encryptedEncryptionKey);
  }

  Future reject(SignedInvitation invitation) async {
    return _onlineManager.reject(invitation.toSignedInvitationRead());
  }

  Future fetchUserProfile(String username) async {
    return await _onlineManager.fetchUserProfile(username);
  }

  Future<void> invite(Collection col, String username, Uint8List pubkey,
      CollectionAccessLevel accessLevel) async {
    final mainCryptoManager = _etebase._getCryptoManager();
    final identCryptoManager = _etebase._getIdentityCryptoManager();
    final invitation = await col._encryptedCollection.createInvitation(
        mainCryptoManager, identCryptoManager, username, pubkey, accessLevel);
    await _onlineManager.invite(invitation);
  }

  Future disinvite(SignedInvitation invitation) async {
    return _onlineManager.disinvite(invitation.toSignedInvitationRead());
  }

  dynamic get pubkey {
    final identCryptoManager = _etebase._getIdentityCryptoManager();
    return identCryptoManager.pubkey;
  }
}

class CollectionMemberManager {
  final Account _etebase;
  final CollectionMemberManagerOnline _onlineManager;

  CollectionMemberManager(this._etebase, CollectionManager _collectionManager,
      EncryptedCollection encryptedCollection)
      : _onlineManager = CollectionMemberManagerOnline(
            AccountOnlineData(_etebase.serverUrl, _etebase.authToken),
            encryptedCollection.uid);

  Future list([MemberFetchOptions? options]) async {
    return _onlineManager.list(options);
  }

  Future remove(String username) async {
    return _onlineManager.remove(username);
  }

  Future<void> leave() async {
    await _onlineManager.leave();
  }

  Future modifyAccessLevel(
      String username, CollectionAccessLevel accessLevel) async {
    return _onlineManager.modifyAccessLevel(username, accessLevel);
  }
}

enum OutputFormat {
  Uint8Array,
  String,
}

class Collection {
  final CollectionCryptoManager _cryptoManager;
  final EncryptedCollection _encryptedCollection;

  Collection(this._cryptoManager, this._encryptedCollection);

  bool verify() {
    return _encryptedCollection.verify(_cryptoManager);
  }

  void setMeta<T>(ItemMetadata meta) {
    _encryptedCollection.setMeta(_cryptoManager, meta);
  }

  ItemMetadata getMeta<T>() {
    return _encryptedCollection.getMeta(_cryptoManager);
  }

  Future<void> setContent(dynamic content) async {
    final uInt8ListContent = content is Uint8List ? content : Uint8List.fromList(utf8.encode(content.toString()));
    await _encryptedCollection.setContent(_cryptoManager, uInt8ListContent);
  }

  Future<Object> getContent(
      [OutputFormat outputFormat = OutputFormat.Uint8Array]) async {
    final ret = await _encryptedCollection.getContent(_cryptoManager);
    switch (outputFormat) {
      case OutputFormat.Uint8Array:
        return ret;
      case OutputFormat.String:
        return toString(ret);
      default:
        throw Exception('Bad output format');
    }
  }

  void delete([preserveContent = false]) {
    _encryptedCollection.delete(_cryptoManager, preserveContent);
  }

  base64 get uid => _encryptedCollection.uid;

  base64 get etag => _encryptedCollection.etag;

  bool get isDeleted => _encryptedCollection.isDeleted;

  String? get stoken => _encryptedCollection.stoken;

  CollectionAccessLevel get accessLevel => _encryptedCollection.accessLevel;

  String getCollectionType() {
    return _encryptedCollection
        .getCollectionType(_cryptoManager.accountCryptoManager);
  }

  Item get item {
    final encryptedItem = _encryptedCollection.item;
    return Item(
        uid, encryptedItem.getCryptoManager(_cryptoManager), encryptedItem);
  }
}

class Item {
  final CollectionItemCryptoManager _cryptoManager;
  final EncryptedCollectionItem encryptedItem;
  final String collectionUid; // The uid of the collection this item belongs to

  Item(this.collectionUid, this._cryptoManager, this.encryptedItem);

  bool verify() {
    return encryptedItem.verify(_cryptoManager);
  }

  void setMeta<T>(ItemMetadata meta) {
    encryptedItem.setMeta(_cryptoManager, meta);
  }

  ItemMetadata getMeta<T>() {
    return encryptedItem.getMeta(_cryptoManager);
  }

  Future<void> setContent(dynamic content) async {
    final uInt8ListContent = content is Uint8List ? content : Uint8List.fromList(utf8.encode(content.toString()));
    await encryptedItem.setContent(_cryptoManager, uInt8ListContent);
  }

  Future<Object> getContent(
      [OutputFormat outputFormat = OutputFormat.Uint8Array]) async {
    final ret = await encryptedItem.getContent(_cryptoManager);
    switch (outputFormat) {
      case OutputFormat.Uint8Array:
        return ret;
      case OutputFormat.String:
        return toString(ret);
      default:
        throw Exception('Bad output format');
    }
  }

  void delete([preserveContent = false]) {
    encryptedItem.delete(_cryptoManager, preserveContent);
  }

  base64 get uid => encryptedItem.uid;

  base64 get etag => encryptedItem.etag;

  bool get isDeleted => encryptedItem.isDeleted;

  bool get isMissingContent => encryptedItem.isMissingContent;

  Item clone() {
    return Item(collectionUid, _cryptoManager,
        EncryptedCollectionItem.deserialize(encryptedItem.serialize()));
  }
}
