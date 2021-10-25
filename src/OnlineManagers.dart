import 'dart:io';
import 'dart:typed_data';

import 'EncryptedModels.dart';
import 'Etebase.dart';
import 'Exceptions.dart';
import 'Helpers.dart';
import 'Request.dart';
import 'UriExtension.dart';

// import request from "./Request";
// import WebSocket from "isomorphic-ws";
// import ReconnectingWebSocket from "reconnecting-websocket";

// import URI from "urijs";

// export { deriveKey, ready } from "./Crypto";
// import { HttpError, UnauthorizedError, PermissionDeniedError, ConflictError, NetworkError, ProgrammingError, NotFoundError, TemporaryServerError, ServerError } from "./Exceptions";
// export * from "./Exceptions";
// import { base64, msgpackEncode, msgpackDecode, toString } from "./Helpers";

// import
// import 'Exceptions.dart';
// import 'Request.dart';{
//   CollectionAccessLevel,
//   CollectionJsonRead,
//   CollectionItemJsonRead,
//   EncryptedCollection,
//   EncryptedCollectionItem,
//   SignedInvitationRead,
//   SignedInvitationWrite,
//   CollectionItemRevisionJsonRead,
//   ChunkJson,
// } from "./EncryptedModels";

class User {
  String username;
  String email;

  User({required this.username, required this.email});
}

class LoginResponseUser extends User {
  Uint8List pubkey;
  Uint8List encryptedContent;

  LoginResponseUser(
      {required String username,
      required String email,
      required this.pubkey,
      required this.encryptedContent})
      : super(username: username, email: email);
}

class UserProfile {
  Uint8List pubkey;

  UserProfile({required this.pubkey});
}

class LoginChallange {
  Uint8List challenge;
  Uint8List salt;
  int version;

  LoginChallange(
      {required this.challenge, required this.salt, required this.version});
}

class LoginChallangeResponse {
  Uint8List challenge;
  String host;

  LoginChallangeResponse({required this.challenge, required this.host});
}

class LoginResponse {
  String token;
  LoginResponseUser user;

  LoginResponse(this.token, this.user);
}

class ListResponse<T> {
  List<T> data;
  bool done;

  ListResponse(this.data, this.done);
}

class CollectionItemListResponse<T> extends ListResponse<T> {
  String stoken;

  CollectionItemListResponse(
      {required this.stoken, required List<T> data, required bool done})
      : super(data, done);
}

class CollectionListResponse<T> extends CollectionItemListResponse<T> {
  List<RemovedCollection>? removedMemberships;

  CollectionListResponse(
      {this.removedMemberships,
      required String stoken,
      required List<T> data,
      required bool done})
      : super(stoken: stoken, data: data, done: done);
}

class IteratorListResponse<T> extends ListResponse<T> {
  String iterator;

  IteratorListResponse({required this.iterator, required data, required done})
      : super(data, done);
}

typedef CollectionMemberListResponse<T> = IteratorListResponse<T>;

typedef CollectionInvitationListResponse<T> = IteratorListResponse<T>;

class RemovedCollection {
  base64 uid;

  RemovedCollection({required this.uid});
}

class CollectionMember {
  String username;
  CollectionAccessLevel accessLevel;

  CollectionMember({required this.username, required this.accessLevel});
}

class AcceptedInvitation {
  Uint8List encryptionKey;

  AcceptedInvitation({required this.encryptionKey});
}

enum PrefetchOption {
  Auto,
  Medium,
}

class ListFetchOptions {
  int? limit;

  ListFetchOptions({this.limit});
}

class FetchOptions extends ListFetchOptions {
  String? stoken;
  PrefetchOption? prefetch;

  FetchOptions({this.stoken, this.prefetch, limit}) : super(limit: limit);
}

class ItemFetchOptions extends FetchOptions {
  bool? withCollection;

  ItemFetchOptions({this.withCollection, stoken, prefetch, limit})
      : super(stoken: stoken, prefetch: prefetch, limit: limit);
}

class IteratorFetchOptions extends ListFetchOptions {
  String? iterator;

  IteratorFetchOptions({this.iterator, limit}) : super(limit: limit);
}

class IteratorItemFetchOptions {
  ItemFetchOptions? itemFetchOptions;
  IteratorFetchOptions? iteratorFetchOptions;

  IteratorItemFetchOptions({this.itemFetchOptions, this.iteratorFetchOptions});
}

typedef MemberFetchOptions = IteratorFetchOptions;

typedef InvitationFetchOptions = IteratorFetchOptions;

class RevisionsFetchOptions extends IteratorFetchOptions {
  PrefetchOption? prefetch;

  RevisionsFetchOptions({this.prefetch, iterator, limit})
      : super(iterator: iterator, limit: limit);
}

class WebSocketTicketRequest {
  String collection;

  WebSocketTicketRequest(this.collection);
}

class WebSocketTicketResponse {
  String ticket;

  WebSocketTicketResponse(this.ticket);
}

class AccountOnlineData {
  String serverUrl;
  String? authToken;

  AccountOnlineData(this.serverUrl, this.authToken);

  factory AccountOnlineData.fromAccount(Account account){
    return AccountOnlineData(account.serverUrl, account.authToken);
  }
}

Uri urlExtend(Uri baseUrlIn, List<String> segments) {
  var baseUrl = baseUrlIn.clone();
  for (final segment in segments) {
    baseUrl.segment(segment);
  }
  baseUrl.segment('');
  return baseUrl.normalize();
}

class BaseNetwork {
  Uri apiBase;

  BaseNetwork(this.apiBase);

  Future<T> newCall<T>(
      [List<String> segments = const [],
      RequestInit? extra,
      Uri? apiBaseIn]) async {
    extra ??= RequestInit();
    apiBaseIn ??= this.apiBase;

    final apiBase = urlExtend(apiBaseIn, segments);

    extra.headers = {'Accept': 'application/msgpack', ...?extra.headers};

    Response response;
    try {
      response = await request(apiBase.toString(), extra);
    } catch (e) {
      throw NetworkError(e.toString());
    }

    final body = response.body;
    var data;
    String? strError;

    try {
      data = msgpackDecode(body);
    } catch (e) {
      data = Uint8List.fromList(body);
      try {
        strError = data.toString();
      } catch (e) {
        // Ignore
      }
    }

    if (response.ok) {
      return data;
    } else {
      final content = data['detail'] ?? data['non_field_errors'] ?? strError;
      switch (response.status) {
        case 401:
          throw UnauthorizedError(content, data);
        case 403:
          throw PermissionDeniedError(content);
        case 404:
          throw NotFoundError(content);
        case 409:
          throw ConflictError(content);
        case 502:
        case 503:
        case 504:
          throw TemporaryServerError(response.status, content, data);
        default:
          {
            if ((response.status >= 500) && (response.status <= 599)) {
              throw ServerError(response.status, content, data);
            } else {
              throw HttpError(response.status, content, data);
            }
          }
      }
    }
  }
}

class Authenticator extends BaseNetwork {
  Authenticator(String apiBase) : super(Uri.parse(apiBase)) {
    this.apiBase = urlExtend(this.apiBase, ['api', 'v1', 'authentication']);
  }

  Future<bool> isEtebase() async {
    try {
      await newCall(['is_etebase']);
      return true;
    } catch (e) {
      if (e is NotFoundError) {
        return false;
      }
      rethrow;
    }
  }

  Future<LoginResponse> signup(User user, Uint8List salt, Uint8List loginPubkey,
      Uint8List pubkey, Uint8List encryptedContent) async {
    user = User(
      username: user.username,
      email: user.email,
    );

    final extra = RequestInit(
        method: HttpMethod.post,
        headers: {
          'Content-Type': 'application/msgpack',
        },
        body: msgpackEncode({
          'user': user,
          'salt': salt,
          'loginPubkey': loginPubkey,
          'pubkey': pubkey,
          'encryptedContent': encryptedContent,
        }));

    return newCall<LoginResponse>(['signup'], extra);
  }

  Future<LoginChallange> getLoginChallenge(String username) async {
    final extra = RequestInit(
        method: HttpMethod.post,
        headers: {
          'Content-Type': 'application/msgpack',
        },
        body: msgpackEncode({username}));

    return newCall<LoginChallange>(['login_challenge'], extra);
  }

  Future<LoginResponse> login(Uint8List response, Uint8List signature) async {
    final extra = RequestInit(
        method: HttpMethod.post,
        headers: {
          'Content-Type': 'application/msgpack',
        },
        body: msgpackEncode({
          response: response,
          signature: signature,
        }));

    return newCall<LoginResponse>(['login'], extra);
  }

  Future<void> logout(String authToken) async {
    final extra = RequestInit(method: HttpMethod.post, headers: {
      'Content-Type': 'application/msgpack',
      'Authorization': 'Token ' + authToken,
    });

    return newCall(['logout'], extra);
  }

  Future<void> changePassword(
      String authToken, Uint8List response, Uint8List signature) async {
    final extra = RequestInit(
        method: HttpMethod.post,
        headers: {
          'Content-Type': 'application/msgpack',
          'Authorization': 'Token ' + authToken,
        },
        body: msgpackEncode({
          response: response,
          signature: signature,
        }));

    await newCall(['change_password'], extra);
  }

  Future<String> getDashboardUrl(String authToken) async {
    final extra = RequestInit(method: HttpMethod.post, headers: {
      'Content-Type': 'application/msgpack',
      'Authorization': 'Token ' + authToken,
    });
    final ret = await newCall(['dashboard_url'], extra);
    return ret['url'];
  }
}

class BaseManager extends BaseNetwork {
  AccountOnlineData etebase;

  BaseManager(this.etebase, List<String> segments)
      : super(Uri.parse(etebase.serverUrl)) {
    apiBase = urlExtend(apiBase, ['api', 'v1', ...segments]);
  }

  @override
  Future<T> newCall<T>(
      [List<String>? segments, RequestInit? extra, Uri? apiBase]) async {
    extra ??= RequestInit();
    apiBase ??= this.apiBase;

    extra.headers = {
      'Content-Type': 'application/msgpack',
      'Authorization': 'Token ' + (etebase.authToken ?? ''),
      ...?extra.headers,
    };

    return super.newCall(segments ?? [], extra, apiBase);
  }

  dynamic urlFromFetchOptions(IteratorItemFetchOptions? options) {
    if (options == null) {
      return apiBase;
    }

    return apiBase.clone().search({
      'stoken': options.itemFetchOptions?.stoken,
      'iterator': options.iteratorFetchOptions?.iterator,
      'limit': (options.itemFetchOptions?.limit != null &&
              (options.itemFetchOptions!.limit! > 0))
          ? options.itemFetchOptions?.limit
          : null,
      'withCollection': options.itemFetchOptions?.withCollection,
      'prefetch': true,
    });
  }
}

class CollectionManagerOnline extends BaseManager {
  CollectionManagerOnline(AccountOnlineData etebase)
      : super(etebase, ['collection']);

  Future<EncryptedCollection> fetch(
      String colUid, FetchOptions? options) async {
    final apiBase = urlFromFetchOptions(IteratorItemFetchOptions(
        itemFetchOptions: ItemFetchOptions(
      limit: options?.limit,
      prefetch: options?.prefetch,
      stoken: options?.stoken,
    )));

    final json =
        await newCall<CollectionJsonRead>([colUid], RequestInit(), apiBase);
    return EncryptedCollection.deserialize(json);
  }

  Future<CollectionListResponse<EncryptedCollection>> list(
      List<Uint8List> collectionTypes,
      [FetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(IteratorItemFetchOptions(
        itemFetchOptions: ItemFetchOptions(
      limit: options?.limit,
      prefetch: options?.prefetch,
      stoken: options?.stoken,
    )));

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode({collectionTypes}),
    );

    final json = await newCall<CollectionListResponse<CollectionJsonRead>>(
        ['list_multi'], extra, apiBase);
    return CollectionListResponse<EncryptedCollection>(
      removedMemberships: json.removedMemberships,
      stoken: json.stoken,
      data:
          json.data.map((val) => EncryptedCollection.deserialize(val)).toList(),
      done: json.done,
    );
  }

  Future<Object> create(EncryptedCollection collection,
      [FetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(IteratorItemFetchOptions(
        itemFetchOptions: ItemFetchOptions(
      limit: options?.limit,
      prefetch: options?.prefetch,
      stoken: options?.stoken,
    )));

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode(collection.serialize()),
    );

    return newCall([], extra, apiBase);
  }
}

class CollectionItemManagerOnline extends BaseManager {
  CollectionItemManagerOnline(AccountOnlineData etebase, String colUid)
      : super(etebase, ['collection', colUid, 'item']);

  Future<EncryptedCollectionItem> fetch(String itemUid,
      [ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    final json =
        await newCall<CollectionItemJsonRead>([itemUid], null, apiBase);
    return EncryptedCollectionItem.deserialize(json);
  }

  Future<CollectionItemListResponse<EncryptedCollectionItem>> list(
      ItemFetchOptions? options) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    final json =
        await newCall<CollectionItemListResponse<CollectionItemJsonRead>>(
            null, null, apiBase);
    return CollectionItemListResponse(
      stoken: json.stoken,
      data: json.data
          .map((val) => EncryptedCollectionItem.deserialize(val))
          .toList(),
      done: json.done,
    );
  }

  Future<IteratorListResponse<EncryptedCollectionItem>> itemRevisions(
      EncryptedCollectionItem item, RevisionsFetchOptions? options) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(iteratorFetchOptions: options));

    final serializedItem = item.serialize();

    final json =
        await newCall<IteratorListResponse<CollectionItemRevisionJsonRead>>(
            [item.uid, 'revision'], null, apiBase);
    return IteratorListResponse(
      iterator: json.iterator,
      data: json.data.map(
        (val) => EncryptedCollectionItem.deserialize(
          CollectionItemJsonWrite(
            uid: serializedItem.uid,
            encryptionKey: serializedItem.encryptionKey,
            version: serializedItem.version,
            etag: val.uid,
            // We give revisions their old etag
            content: val,
          ),
        ),
      ),
      done: json.done,
    );
  }

  Future<Object> create(EncryptedCollectionItem item) async {
    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode(item.serialize()),
    );

    return newCall(null, extra);
  }

  Future<CollectionItemListResponse<EncryptedCollectionItem>> fetchUpdates(
      List<EncryptedCollectionItem> items,
      [ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));
    // We only use stoken if available
    final wantEtag = !(options?.stoken != null);

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode(items.map(
          (x) => ({'uid': x.uid, 'etag': ((wantEtag) ? x.lastEtag : null)}))),
    );

    final json =
        await newCall<CollectionItemListResponse<CollectionItemJsonRead>>(
            ['fetch_updates'], extra, apiBase);
    final data = json.data;
    return CollectionItemListResponse(
      stoken: json.stoken,
      done: json.done,
      data:
          data.map((val) => EncryptedCollectionItem.deserialize(val)).toList(),
    );
  }

  Future<CollectionItemListResponse<EncryptedCollectionItem>> fetchMulti(
      List<base64> items,
      [ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode(items.map((x) => ({'uid': x}))),
    );

    final json =
        await newCall<CollectionItemListResponse<CollectionItemJsonRead>>(
            ['fetch_updates'], extra, apiBase);
    final data = json.data;
    return CollectionItemListResponse(
      stoken: json.stoken,
      done: json.done,
      data:
          data.map((val) => EncryptedCollectionItem.deserialize(val)).toList(),
    );
  }

  Future<Object> batch(List<EncryptedCollectionItem> items,
      [List<EncryptedCollectionItem>? deps, ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode({
        items: items.map((x) => x.serialize()),
        deps: deps?.map((x) => ({'uid': x.uid, 'etag': x.lastEtag})),
      }),
    );

    return newCall(['batch'], extra, apiBase);
  }

  Future<Object> transaction(List<EncryptedCollectionItem> items,
      [List<EncryptedCollectionItem>? deps, ItemFetchOptions? options]) {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode({
        items: items.map((x) => x.serialize()),
        deps: deps?.map((x) => ({'uid': x.uid, 'etag': x.lastEtag})),
      }),
    );

    return newCall(['transaction'], extra, apiBase);
  }

  Future<Object> chunkUpload(EncryptedCollectionItem item, ChunkJson chunk,
      [ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    if (chunk.two == null) {
      throw ProgrammingError('Tried uploading a missing chunk.');
    }

    final extra = RequestInit(
      method: HttpMethod.put,
      headers: {
        'Content-Type': 'application/octet-stream',
      },
      body: chunk.two,
    );

    return newCall([item.uid, 'chunk', chunk.one], extra, apiBase);
  }

  Future<Uint8List> chunkDownload(EncryptedCollectionItem item, base64 chunkUid,
      [ItemFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(itemFetchOptions: options));

    return newCall([item.uid, 'chunk', chunkUid, 'download'], null, apiBase);
  }

  Future<WebSocketHandle> subscribeChanges(
      void Function(CollectionItemListResponse<EncryptedCollectionItem> data)
          cb,
      ItemFetchOptions? options_) async {
    final options = ItemFetchOptions(
        stoken: options_?.stoken,
        prefetch: options_?.prefetch,
        limit: options_?.limit,
        withCollection: options_?.withCollection);

    final getUrlOptions = () async {
      final extra = RequestInit(
        method: HttpMethod.post,
      );
      final ret = await newCall<WebSocketTicketResponse>(
          ['subscription-ticket'], extra, null);
      return WebSocketUrlOptions(
        ticket: ret.ticket,
        fetchOptions: options,
      );
    };

    final wsOnlineManager = WebSocketManagerOnline(etebase, getUrlOptions);
    return wsOnlineManager.subscribe((raw) {
      final response = msgpackDecode(raw)
          as CollectionItemListResponse<CollectionItemJsonRead>;
      // Update the stoken we fetch by when reconnecting every time we get data
      options.stoken = response.stoken;

      cb(CollectionItemListResponse(
        stoken: response.stoken,
        done: response.done,
        data: response.data
            .map((val) => EncryptedCollectionItem.deserialize(val))
            .toList(),
      ));
    });
  }
}

class CollectionInvitationManagerOnline extends BaseManager {
  CollectionInvitationManagerOnline(AccountOnlineData etebase)
      : super(etebase, ['invitation']);

  Future<CollectionInvitationListResponse<SignedInvitationRead>> listIncoming(
      [InvitationFetchOptions? options]) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(iteratorFetchOptions: options));

    final json =
        await newCall<CollectionInvitationListResponse<SignedInvitationRead>>(
            ['incoming'], null, apiBase);
    return CollectionInvitationListResponse(
      done: json.done,
      iterator: json.iterator,
      data: json.data.map((val) => val),
    );
  }

  Future<CollectionInvitationListResponse<SignedInvitationRead>> listOutgoing(
      InvitationFetchOptions? options) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(iteratorFetchOptions: options));

    final json =
        await newCall<CollectionInvitationListResponse<SignedInvitationRead>>(
            ['outgoing'], null, apiBase);
    return CollectionInvitationListResponse(
      done: json.done,
      iterator: json.iterator,
      data: json.data.map((val) => val).toList(),
    );
  }

  Future<Object> accept(SignedInvitationRead invitation,
      Uint8List collectionType, Uint8List encryptionKey) {
    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode({
        collectionType,
        encryptionKey,
      }),
    );

    return newCall(['incoming', invitation.uid, 'accept'], extra);
  }

  Future<Object> reject(SignedInvitationRead invitation) async {
    final extra = RequestInit(
      method: HttpMethod.delete,
    );

    return newCall(['incoming', invitation.uid], extra);
  }

  Future<UserProfile> fetchUserProfile(String username) async {
    final apiBase = this.apiBase.clone().search({
      username: username,
    });

    return newCall(['outgoing', 'fetch_user_profile'], null, apiBase);
  }

  Future<Object> invite(SignedInvitationWrite invitation) async {
    final extra = RequestInit(
      method: HttpMethod.post,
      body: msgpackEncode(invitation),
    );

    return newCall(['outgoing'], extra);
  }

  Future<Object> disinvite(SignedInvitationRead invitation) {
    final extra = RequestInit(
      method: HttpMethod.delete,
    );

    return newCall(['outgoing', invitation.uid], extra);
  }
}

class CollectionMemberManagerOnline extends BaseManager {
  CollectionMemberManagerOnline(AccountOnlineData etebase, String colUid)
      : super(etebase, ['collection', colUid, 'member']);

  Future<CollectionMemberListResponse<CollectionMember>> list(
      MemberFetchOptions? options) async {
    final apiBase = urlFromFetchOptions(
        IteratorItemFetchOptions(iteratorFetchOptions: options));

    return newCall<CollectionMemberListResponse<CollectionMember>>(
        null, null, apiBase);
  }

  Future<Object> remove(String username) async {
    final extra = RequestInit(
      method: HttpMethod.delete,
    );

    return newCall([username], extra);
  }

  Future<Object> leave() async {
    final extra = RequestInit(
      method: HttpMethod.post,
    );

    return newCall(['leave'], extra);
  }

  Future<Object> modifyAccessLevel(
      String username, CollectionAccessLevel accessLevel) async {
    final extra = RequestInit(
      method: HttpMethod.patch,
      body: msgpackEncode({
        accessLevel,
      }),
    );

    return newCall([username], extra);
  }
}

typedef WebSocketCbType = void Function(Uint8List message);

class WebSocketHandle {
  WebSocket? _rws;
  bool connected = false;

  Future connect(String url, WebSocketCbType cb) async {
    try {
      _rws = await WebSocket.connect(url);
      connected = true;

      _rws!.listen((event) {
        cb(event);
      })
        ..onDone(() {
          connected = false;
        })
        ..onError((e) {
          connected = false;
        });
    } catch (e) {}
  }

  Future<void> unsubscribe() async {
    await _rws?.close();
  }
}

class WebSocketUrlOptions {
  String ticket;
  FetchOptions? fetchOptions;

  WebSocketUrlOptions({required this.ticket, this.fetchOptions});
}

class WebSocketManagerOnline extends BaseManager {
  final Future<WebSocketUrlOptions> Function() _getUrlOptions;

  WebSocketManagerOnline(AccountOnlineData etebase, this._getUrlOptions)
      : super(etebase, ['ws']);

  Future<WebSocketHandle> subscribe(WebSocketCbType cb) async {
    final protocol = (this.apiBase.scheme == 'https') ? 'wss' : 'ws';

    final options = await _getUrlOptions();
    final apiBase = urlFromFetchOptions(IteratorItemFetchOptions(
            itemFetchOptions: ItemFetchOptions(
                prefetch: options.fetchOptions?.prefetch,
                limit: options.fetchOptions?.limit,
                stoken: options.fetchOptions?.stoken)))
        .protocol(protocol);
    final url = urlExtend(apiBase, [options.ticket]).toString();

    final websocketHandle = WebSocketHandle();
    await websocketHandle.connect(url, cb);
    return websocketHandle;
  }
}
