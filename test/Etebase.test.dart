// import request from "./Request";
//
// import * as Etebase from "./Etebase";
//
// import { USER, USER2, sessionStorageKey } from "./TestConstants";
//
// import { Authenticator, PrefetchOption } from "./OnlineManagers";
// import { fromBase64, fromString, msgpackEncode, msgpackDecode, randomBytesDeterministic, toBase64 } from "./Helpers";

import 'dart:typed_data';

import 'package:test/test.dart';

import '../src/Crypto.dart';
import '../src/EncryptedModels.dart';
import '../src/Etebase.dart';
import '../src/Exceptions.dart';
import '../src/Helpers.dart';
import '../src/OnlineManagers.dart';
import '../src/Request.dart';
import '../src/TestConstants.dart';

final testApiBase = String.fromEnvironment('ETEBASE_TEST_API_URL',
    defaultValue: 'http://localhost:8033');

late Account etebase;

const colType = 'some.coltype';

Future<void> verifyCollection<T>(
    Collection col, ItemMetadata<T> meta, Uint8List content) async {
  col.verify();
  final decryptedMeta = col.getMeta();
  expect(decryptedMeta, equals(meta));
  final decryptedContent = await col.getContent();
  expect(toBase64(decryptedContent), equals(toBase64(content)));
}

Future<void> verifyItem<T>(
    Item item, ItemMetadata<T> meta, Uint8List content) async {
  item.verify();
  final decryptedMeta = item.getMeta();
  expect(decryptedMeta, equals(meta));
  final decryptedContent = await item.getContent();
  expect(toBase64(decryptedContent), equals(toBase64(content)));
}

Future<Account> prepareUserForTest(USER user) async {
  final response = await request(
      testApiBase + '/api/v1/test/authentication/reset/',
      RequestInit(
        method: HttpMethod.post,
        headers: {
          'Accept': 'application/msgpack',
          'Content-Type': 'application/msgpack',
        },
        body: msgpackEncode({
          'user': {
            'username': user.username,
            'email': user.email,
          },
          'salt': fromBase64(user.salt),
          'loginPubkey': fromBase64(user.loginPubkey),
          'encryptedContent': fromBase64(user.encryptedContent),
          'pubkey': fromBase64(user.pubkey),
        }),
      ));

  if (!response.ok) {
    throw Exception(response.statusText);
  }

  final etebase =
      await Account.restore(user.storedSession, fromBase64(sessionStorageKey));
  etebase.serverUrl = testApiBase;
  await etebase.fetchToken();

  return etebase;
}

void main() {
  setUpAll(() async {
    await ready;

    for (final user in [USER1(), USER2()]) {
      try {
        final authenticator = Authenticator(testApiBase);
        await authenticator.signup(
            User(username: user.username, email: user.email),
            fromBase64(user.salt),
            fromBase64(user.loginPubkey),
            fromBase64(user.pubkey),
            fromBase64(user.encryptedContent));
      } catch (e) {
        //
      }
    }
  });

  setUp(() async {
    await ready;

    etebase = await prepareUserForTest(USER1());
  });

  tearDown(() async {
    await etebase.logout();
  });

  test('Check server is etebase', () async {
    expect(await Account.isEtebaseServer(testApiBase), isTrue);
    expect(await Account.isEtebaseServer(testApiBase + '/api/'), isFalse);
    expect(
        Account.isEtebaseServer('http://doesnotexist'), throwsA(isA<Error>()));
    expect(
        await Account.login(
            USER2().username, USER2().password, testApiBase + '/api/'),
        throwsA(isA<NotFoundError>()));
  });

  test('Getting dashboard url', () async {
    String? url;
    try {
      url = await etebase.getDashboardUrl();
    } catch (e) {
      expect(e, equals(HttpError));
      expect((e as HttpError).content?.code, equals('not_supported'));
    }
    if (url != null) {
      expect(url, isTrue);
    }
  });

  test('Simple collection handling', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final content = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, meta, content);
    expect(col.getCollectionType(), equals(colType));
    await verifyCollection(col, meta, content);

    final meta2 = ItemMetadata(
      name: 'Calendar2',
      description: 'Someone',
      color: '#000000',
    );
    col.setMeta(meta2);

    await verifyCollection(col, meta2, content);
    expect(meta, isNot(equals(col.getMeta())));

    expect(col.isDeleted, isFalse);
    col.delete(true);
    expect(col.isDeleted, isTrue);
    await verifyCollection(col, meta2, content);
  });

  test('Simple item handling', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await verifyItem(item, meta, content);

    final meta2 = ItemMetadata(
      type: 'ITEMTYPE',
      data: {
        'someval': 'someval',
      },
    );
    item.setMeta(meta2);

    await verifyItem(item, meta2, content);
    expect(meta, isNot(equals(col.getMeta())));

    expect(item.isDeleted, isFalse);
    item.delete(true);
    expect(item.isDeleted, isTrue);
    await verifyItem(item, meta2, content);
  });

  test('Content formats', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final content = 'Hello';
    final col = await collectionManager.create(colType, meta, content);
    {
      final decryptedContent = await col.getContent(OutputFormat.String);
      expect(decryptedContent, equals(content));

      final decryptedContentUint = await col.getContent();
      expect(decryptedContentUint, equals(fromString(content)));
    }

    final itemManager = collectionManager.getItemManager(col);

    final metaItem = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content2 = 'Hello2';

    final item = await itemManager.create(metaItem, content2);
    {
      final decryptedContent = await item.getContent(OutputFormat.String);
      expect(decryptedContent, equals(content2));

      final decryptedContentUint = await item.getContent();
      expect(decryptedContentUint, equals(fromString(content2)));
    }
  });

  test('Simple collection sync', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final content = Uint8List.fromList([1, 2, 3, 5]);
    var col = await collectionManager.create(colType, meta, content);
    await verifyCollection(col, meta, content);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(0));
    }

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], meta, content);
    }

    {
      col = await collectionManager.fetch(col.uid);
      final collections = await collectionManager
          .list([colType], FetchOptions(stoken: col.stoken));
      expect(collections.data.length, equals(0));
    }

    final colOld = await collectionManager.fetch(col.uid);

    final meta2 = ItemMetadata(
      name: 'Calendar2',
      description: 'Someone',
      color: '#000000',
    );
    col.setMeta(meta2);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], meta2, content);
    }

    {
      final collections = await collectionManager
          .list([colType], FetchOptions(stoken: col.stoken));
      expect(collections.data.length, equals(1));
    }

    // Fail uploading because of an old stoken/etag
    {
      final content2 = Uint8List.fromList([7, 2, 3, 5]);
      await colOld.setContent(content2);

      expect(await collectionManager.transaction(colOld),
          throwsA(isA<ConflictError>()));

      expect(
          await collectionManager.upload(
              colOld, FetchOptions(stoken: colOld.stoken)),
          throwsA(isA<ConflictError>()));
    }

    final content2 = Uint8List.fromList([7, 2, 3, 5]);
    await col.setContent(content2);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], meta2, content2);
    }

    // Try uploadign the same collection twice as new
    col = await collectionManager.create(colType, meta, content);
    final cachedCollection = collectionManager.cacheSave(col);
    final colCopy = collectionManager.cacheLoad(cachedCollection);
    await colCopy.setContent(
        'Something else'); // Just so it has a different revision uid
    await collectionManager.upload(col);
    expect(
        await collectionManager.upload(colCopy), throwsA(isA<ConflictError>()));
  });

  test('Collection types', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final content = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, meta, content);
    await verifyCollection(col, meta, content);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(0));
    }

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], meta, content);
    }

    {
      final collections = await collectionManager.list(['bad.coltype']);
      expect(collections.data.length, equals(0));
    }

    {
      final collections =
          await collectionManager.list(['bad.coltype', colType, 'anotherbad']);
      expect(collections.data.length, equals(1));
    }

    {
      final collections =
          await collectionManager.list(['bad.coltype', 'anotherbad']);
      expect(collections.data.length, equals(0));
    }
  });

  test('Simple item sync', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await verifyItem(item, meta, content);

    await itemManager.batch([item]);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
      await verifyItem(items.data[0], meta, content);
    }

    final meta2 = ItemMetadata(
      type: 'ITEMTYPE',
      data: {
        'someval': 'someval',
      },
    );
    item.setMeta(meta2);

    await itemManager.batch([item]);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
      await verifyItem(items.data[0], meta2, content);
    }

    final content2 = Uint8List.fromList([7, 2, 3, 5]);
    await item.setContent(content2);

    await itemManager.batch([item]);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
      await verifyItem(items.data[0], meta2, content2);
    }
  });

  test('Item re-uploaded revisions', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final col = await collectionManager.create(colType, colMeta, '');
    await collectionManager.upload(col);

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );

    final item = await itemManager.create(meta, '');

    await itemManager.batch([item]);
    // Adding the same item twice should work
    await itemManager.batch([item]);

    final itemOld = item.clone();

    await item.setContent('Test');
    await itemManager.batch([item]);

    expect(await itemManager.batch([itemOld]), throwsA(isA<HttpError>()));
  });

  test('Collection as item', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    // Verify withCollection works
    {
      var items = await itemManager.list();
      expect(items.data.length, equals(0));
      items = await itemManager.list(ItemFetchOptions(withCollection: true));
      expect(items.data.length, equals(1));
      await verifyItem(items.data[0], colMeta, colContent);
    }

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await verifyItem(item, meta, content);

    await itemManager.batch([item]);

    {
      var items = await itemManager.list();
      expect(items.data.length, equals(1));
      items = await itemManager.list(ItemFetchOptions(withCollection: true));
      expect(items.data.length, equals(2));
      await verifyItem(items.data[0], colMeta, colContent);
    }

    final colItemOld = await itemManager.fetch(col.uid);

    // Manipulate the collection with batch/transaction
    await col.setContent('test');

    await itemManager.batch([col.item]);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], colMeta, fromString('test'));
    }

    await col.setContent('test2');

    await itemManager.transaction([col.item]);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
      await verifyCollection(collections.data[0], colMeta, fromString('test2'));
    }

    {
      final updates = await itemManager.fetchUpdates([colItemOld, item]);
      expect(updates.data.length, equals(1));
      await verifyItem(updates.data[0], colMeta, fromString('test2'));
    }
  });

// Verify we prevent users from trying to use the wrong items in the API
  test('Item multiple collections', () async {
    final collectionManager = etebase.getCollectionManager();

    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    final colMeta2 = ItemMetadata(
      name: 'Calendar 2',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent2 = Uint8List.fromList([]);
    final col2 = await collectionManager.create(colType, colMeta2, colContent2);

    await collectionManager.upload(col2);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(2));
    }

    final itemManager = collectionManager.getItemManager(col);
    final itemManager2 = collectionManager.getItemManager(col2);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await verifyItem(item, meta, content);

    // With the bad item as the main
    await itemManager.batch([item]);
    expect(await itemManager2.batch([item]), throwsA(isA<ProgrammingError>()));
    expect(await itemManager2.transaction([item]),
        throwsA(isA<ProgrammingError>()));

    // With the bad item as a dep
    final item2 = await itemManager2.create(meta, 'col2');
    expect(await itemManager2.batch([item2], [item]),
        throwsA(isA<ProgrammingError>()));
    expect(await itemManager2.transaction([item2], [item]),
        throwsA(isA<ProgrammingError>()));
    await itemManager2.batch([item2]);

    await itemManager.fetchUpdates([item]);
    expect(await itemManager.fetchUpdates([item, item2]),
        throwsA(isA<ProgrammingError>()));

    // Verify we also set it correctly when fetched
    {
      final items = await itemManager.list();
      final itemFetched = items.data[0];
      expect(item.collectionUid, equals(itemFetched.collectionUid));
    }
    {
      final itemFetched = await itemManager.fetch(item.uid);
      expect(item.collectionUid, equals(itemFetched.collectionUid));
    }
  });

  test('Collection and item deletion', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);
    await verifyCollection(col, colMeta, colContent);

    await collectionManager.upload(col);

    final collections = await collectionManager.list([colType]);

    final itemManager = collectionManager.getItemManager(col);
    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await verifyItem(item, meta, content);

    await itemManager.batch([item]);

    final items = await itemManager.list();
    expect(items.data.length, equals(1));

    item.delete(true);
    await itemManager.batch([item]);

    {
      final items2 =
          await itemManager.list(ItemFetchOptions(stoken: items.stoken));
      expect(items2.data.length, equals(1));

      final item2 = items2.data[0];

      await verifyItem(item2, meta, content);
      expect(item2.isDeleted, isTrue);
    }

    col.delete(true);
    await collectionManager.upload(col);

    {
      final collections2 = await collectionManager
          .list([colType], FetchOptions(stoken: collections.stoken));
      expect(collections2.data.length, equals(1));

      final col2 = collections2.data[0];

      await verifyCollection(col2, colMeta, colContent);
      expect(col2.isDeleted, isTrue);
    }
  });

  test('Empty content', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final content = Uint8List.fromList([]);
    var col = await collectionManager.create(colType, meta, content);
    await verifyCollection(col, meta, content);
    await collectionManager.upload(col);

    {
      col = await collectionManager.fetch(col.uid);
      await verifyCollection(col, meta, content);
    }

    final itemManager = collectionManager.getItemManager(col);

    final itemMeta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final item = await itemManager.create(itemMeta, content);

    await itemManager.transaction([item]);

    {
      final items = await itemManager.list();
      final itemFetched = items.data[0];
      await verifyItem(itemFetched, itemMeta, content);
    }
  });

  test('List response correctness', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    final collections = await collectionManager.list([colType]);
    expect(collections.data.length, equals(1));

    final itemManager = collectionManager.getItemManager(col);

    final items = <Item>[];

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(
        type: 'ITEMTYPE',
        data: {
          'someval': 'someval',
          i.toString(): i,
        },
      );
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.batch(items);

    {
      var items = await itemManager.list();
      expect(items.data.length, equals(5));
      expect(items.done, isTrue);
      items = await itemManager.list(ItemFetchOptions(limit: 5));
      expect(items.done, isTrue);
    }

    String? stoken;
    for (var i = 0; i < 3; i++) {
      final items =
          await itemManager.list(ItemFetchOptions(limit: 2, stoken: stoken));
      expect(items.done, equals(i == 2));
      stoken = items.stoken;
    }

    // Also check collections
    {
      for (var i = 0; i < 4; i++) {
        final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
        final col2 = await collectionManager.create(colType, colMeta, content2);
        await collectionManager.upload(col2);
      }
    }

    {
      var collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(5));
      expect(collections.done, isTrue);
      collections =
          await collectionManager.list([colType], FetchOptions(limit: 5));
      expect(collections.done, isTrue);
    }

    stoken = null;
    for (var i = 0; i < 3; i++) {
      final collections = await collectionManager
          .list([colType], FetchOptions(limit: 2, stoken: stoken));
      expect(collections.done, equals(i == 2));
      stoken = collections.stoken;
    }
  });

  test('Item transactions', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);

    final deps = <Item>[item];

    await itemManager.transaction(deps);
    final itemOld = await itemManager.fetch(item.uid);

    final items = <Item>[];

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
    }

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(
          type: 'ITEMTYPE', data: {'someval': 'someval', i.toString(): i});
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.transaction(items, deps);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(6));
    }

    {
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      item.setMeta(meta3);
    }

    await itemManager.transaction([item], items);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(6));
    }

    {
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      item.setMeta(meta3);

      // Old in the deps
      expect(await itemManager.transaction([item], [...items, itemOld]),
          throwsA(isA<ConflictError>()));

      final itemOld2 = itemOld.clone();

      await itemManager.transaction([item]);

      itemOld2.setMeta(meta3);

      // Old stoken in the item itself
      expect(await itemManager.transaction([itemOld2]),
          throwsA(isA<ConflictError>()));
    }

    {
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      final item2 = await itemManager.fetch(items[0].uid);
      item2.setMeta(meta3);

      final itemOld2 = itemOld.clone();
      itemOld2.setMeta(meta3);

      // Part of the transaction is bad, and part is good
      expect(await itemManager.transaction([item2, itemOld2]),
          throwsA(isA<ConflictError>()));

      // Verify it hasn't changed after the transaction above failed
      final item2Fetch = await itemManager.fetch(item2.uid);
      expect(item2Fetch.getMeta(), isNot(equals(item2.getMeta())));
    }

    {
      // Global stoken test
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      item.setMeta(meta3);

      final newCol = await collectionManager.fetch(col.uid);
      final stoken = newCol.stoken;
      final badEtag = col.etag;

      expect(
          await itemManager
              .transaction([item], null, ItemFetchOptions(stoken: badEtag)),
          throwsA(isA<ConflictError>()));

      await itemManager
          .transaction([item], null, ItemFetchOptions(stoken: stoken));
    }
  });

  test('Item batch stoken', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);

    await itemManager.batch([item]);

    final items = <Item>[];

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
    }

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(type: 'ITEMTYPE', data: {
        'someval': 'someval',
        i.toString(): i,
      });
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.batch(items);

    {
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      final item2 = item.clone();

      item2.setMeta(meta3);
      await itemManager.batch([item2]);

      meta3.data['someval'] = 'some3';
      item.setMeta(meta3);

      // Old stoken in the item itself should work for batch and fail for transaction or batch with deps
      expect(
          await itemManager.transaction([item]), throwsA(isA<ConflictError>()));
      expect(await itemManager.batch([item], [item]),
          throwsA(isA<ConflictError>()));
      await itemManager.batch([item]);
    }

    {
      // Global stoken test
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      item.setMeta(meta3);

      final newCol = await collectionManager.fetch(col.uid);
      final stoken = newCol.stoken;
      final badEtag = col.etag;

      expect(
          await itemManager
              .batch([item], null, ItemFetchOptions(stoken: badEtag)),
          throwsA(isA<ConflictError>()));

      await itemManager.batch([item], null, ItemFetchOptions(stoken: stoken));
    }
  });

  test('Item fetch updates', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);

    await itemManager.batch([item]);

    final items = <Item>[];

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(1));
    }

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(type: 'ITEMTYPE', data: {
        'someval': 'someval',
        i.toString(): i,
      });
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.batch(items);

    {
      final items = await itemManager.list();
      expect(items.data.length, equals(6));
    }

    // Fetch multi
    {
      var items2 =
          await itemManager.fetchMulti(items.map((x) => x.uid).toList());
      expect(items2.data.length, equals(5));

      items2 = await itemManager
          .fetchMulti(['L4QQdlkCDJ9ySmrGD5fM0DsFo08MnWel', items[0].uid]);
      // Only 1 because only one of the items exists
      expect(items2.data.length, equals(1));
    }

    String? stoken;

    {
      final newCol = await collectionManager.fetch(col.uid);
      stoken = newCol.stoken;
    }

    {
      var updates = await itemManager.fetchUpdates(items);
      expect(updates.data.length, equals(0));

      updates = await itemManager.fetchUpdates(
          items, ItemFetchOptions(stoken: stoken));
      expect(updates.data.length, equals(0));
    }

    {
      final meta3 = ItemMetadata(
          data: {...meta.data, 'someval': 'some2'},
          color: meta.color,
          description: meta.description,
          mtime: meta.mtime,
          name: meta.name,
          type: meta.type);
      final item2 = items[0].clone();

      item2.setMeta(meta3);
      await itemManager.batch([item2]);
    }

    {
      var updates = await itemManager.fetchUpdates(items);
      expect(updates.data.length, equals(1));

      updates = await itemManager.fetchUpdates(
          items, ItemFetchOptions(stoken: stoken));
      expect(updates.data.length, equals(1));
    }

    {
      final item2 = await itemManager.fetch(items[0].uid);
      var updates = await itemManager.fetchUpdates([item2]);
      expect(updates.data.length, equals(0));

      updates = await itemManager
          .fetchUpdates([item2], ItemFetchOptions(stoken: stoken));
      expect(updates.data.length, equals(1));
    }

    {
      final newCol = await collectionManager.fetch(col.uid);
      stoken = newCol.stoken;
    }

    {
      final updates = await itemManager.fetchUpdates(
          items, ItemFetchOptions(stoken: stoken));
      expect(updates.data.length, equals(0));
    }
  });

  test('Item revisions', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final col = await collectionManager.create(colType, colMeta, '');
    await collectionManager.upload(col);

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );

    final item = await itemManager.create(meta, '');

    for (var i = 0; i < 5; i++) {
      final content = Uint8List.fromList([1, 2, i]);
      await item.setContent(content);

      await itemManager.batch([item]);
    }

    await item.setContent('Latest');
    await itemManager.batch([item]);

    {
      var revisions = await itemManager.itemRevisions(
          item, RevisionsFetchOptions(iterator: item.etag));
      expect(revisions.data.length, equals(5));
      expect(revisions.done, isTrue);
      revisions = await itemManager.itemRevisions(
          item, RevisionsFetchOptions(iterator: item.etag, limit: 5));
      expect(revisions.done, isTrue);

      for (var i = 0; i < 5; i++) {
        final content = Uint8List.fromList([1, 2, i]);
        // The revisions are ordered newest to oldest
        final rev = revisions.data[4 - i];

        expect(await rev.getContent(), equals(content));
      }
    }

    // Iterate through revisions
    {
      String? iterator = item.etag;
      for (var i = 0; i < 2; i++) {
        final revisions = await itemManager.itemRevisions(
            item, RevisionsFetchOptions(limit: 2, iterator: iterator));
        expect(revisions.done, equals(i == 2));
        iterator = revisions.iterator;
      }
    }
  });

  test('Collection invitations', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final items = <Item>[];

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(
          type: 'ITEMTYPE', data: {'someval': 'someval', i.toString(): i});
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.batch(items);

    final collectionInvitationManager = etebase.getInvitationManager();

    final etebase2 = await prepareUserForTest(USER2());
    final collectionManager2 = etebase2.getCollectionManager();
    final collectionInvitationManager2 = etebase2.getInvitationManager();

    final user2Profile =
        await collectionInvitationManager.fetchUserProfile(USER2().username);

    {
      // Also make sure we can invite by email
      final user2Profile2 =
          await collectionInvitationManager.fetchUserProfile(USER2().email);
      expect(user2Profile2.pubkey, equals(user2Profile2.pubkey));
    }

    // Should be verified by user1 off-band
    final user2pubkey = collectionInvitationManager2.pubkey;
    expect(user2Profile.pubkey, equals(user2pubkey));
    // Off-band verification:
    expect(getPrettyFingerprint(user2Profile.pubkey),
        equals(getPrettyFingerprint(user2pubkey)));

    await collectionInvitationManager.invite(col, USER2().username,
        user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

    var invitations = await collectionInvitationManager2.listIncoming();
    expect(invitations.data.length, equals(1));
    expect(invitations.data[0].fromUsername, equals(USER1().username));

    await collectionInvitationManager2.reject(invitations.data[0]);

    {
      final collections = await collectionManager2.list([colType]);
      expect(collections.data.length, equals(0));
    }

    {
      final invitations = await collectionInvitationManager2.listIncoming();
      expect(invitations.data.length, equals(0));
    }

    // Invite and then disinvite
    await collectionInvitationManager.invite(col, USER2().username,
        user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

    invitations = await collectionInvitationManager2.listIncoming();
    expect(invitations.data.length, equals(1));

    await collectionInvitationManager.disinvite(invitations.data[0]);

    {
      final collections = await collectionManager2.list([colType]);
      expect(collections.data.length, equals(0));
    }

    {
      final invitations = await collectionInvitationManager2.listIncoming();
      expect(invitations.data.length, equals(0));
    }

    // Invite again, this time use email, and this time accept
    await collectionInvitationManager.invite(col, USER2().email,
        user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

    invitations = await collectionInvitationManager2.listIncoming();
    expect(invitations.data.length, equals(1));

    String? stoken;
    {
      final newCol = await collectionManager.fetch(col.uid);
      stoken = newCol.stoken;
    }

    // Should be verified by user2 off-band
    final user1pubkey = collectionInvitationManager.pubkey;
    expect(invitations.data[0].fromPubkey, equals(user1pubkey));

    await collectionInvitationManager2.accept(invitations.data[0]);

    {
      final collections = await collectionManager2.list([colType]);
      expect(collections.data.length, equals(1));

      collections.data[0].getMeta();
      expect(collections.data[0].getCollectionType(), equals(colType));
    }

    {
      final invitations = await collectionInvitationManager2.listIncoming();
      expect(invitations.data.length, equals(0));
    }

    final col2 = await collectionManager2.fetch(col.uid);
    final collectionMemberManager2 = collectionManager2.getMemberManager(col2);

    await collectionMemberManager2.leave();

    {
      final collections = await collectionManager2
          .list([colType], FetchOptions(stoken: stoken));
      expect(collections.data.length, equals(0));
      // TODO: fix
      // expect(collections.removedMemberships?.length, equals(1));
    }

    // Add again
    await collectionInvitationManager.invite(col, USER2().username,
        user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

    invitations = await collectionInvitationManager2.listIncoming();
    expect(invitations.data.length, equals(1));
    await collectionInvitationManager2.accept(invitations.data[0]);

    {
      final newCol = await collectionManager.fetch(col.uid);
      expect(stoken, isNot(equals(newCol.stoken)));

      final collections = await collectionManager2
          .list([colType], FetchOptions(stoken: stoken));
      expect(collections.data.length, equals(1));
      expect(collections.data[0].uid, equals(col.uid));
      // TODO: fix
      // expect(collections.removedMemberships).not.toBeDefined();
    }

    // Remove
    {
      final newCol = await collectionManager.fetch(col.uid);
      expect(stoken, isNot(equals(newCol.stoken)));

      final collectionMemberManager = collectionManager.getMemberManager(col);
      await collectionMemberManager.remove(USER2().username);

      final collections = await collectionManager2
          .list([colType], FetchOptions(stoken: stoken));
      expect(collections.data.length, equals(0));
      // TODO: fix
      // expect(collections.removedMemberships?.length).toBe(1);

      stoken = newCol.stoken;
    }

    {
      final collections = await collectionManager2
          .list([colType], FetchOptions(stoken: stoken));
      expect(collections.data.length, equals(0));
      // TODO: fix
      // expect(collections.removedMemberships?.length).toBe(1);
    }

    await etebase2.logout();
  });

  test('Iterating invitations', () async {
    final etebase2 = await prepareUserForTest(USER2());
    final collectionManager = etebase.getCollectionManager();

    final collectionInvitationManager = etebase.getInvitationManager();
    final user2Profile =
        await collectionInvitationManager.fetchUserProfile(USER2().username);

    final collections = [];

    for (var i = 0; i < 3; i++) {
      final colMeta = ItemMetadata(
        name: 'Calendar $i',
      );

      final col = await collectionManager.create(colType, colMeta, '');

      await collectionManager.upload(col);
      await collectionInvitationManager.invite(col, USER2().username,
          user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

      collections.add(col);
    }

    final collectionInvitationManager2 = etebase2.getInvitationManager();

    // Check incoming
    {
      final invitations = await collectionInvitationManager2.listIncoming();
      expect(invitations.data.length, equals(3));
    }

    {
      String? iterator;
      for (var i = 0; i < 2; i++) {
        final invitations = await collectionInvitationManager2
            .listIncoming(IteratorFetchOptions(limit: 2, iterator: iterator));
        expect(invitations.done, equals(i == 1));
        iterator = invitations.iterator;
      }
    }

    // Check outgoing
    {
      final invitations = await collectionInvitationManager.listOutgoing();
      expect(invitations.data.length, equals(3));
    }

    {
      String? iterator;
      for (var i = 0; i < 2; i++) {
        final invitations = await collectionInvitationManager
            .listOutgoing(IteratorFetchOptions(limit: 2, iterator: iterator));
        expect(invitations.done, equals(i == 1));
        iterator = invitations.iterator;
      }
    }

    await etebase2.logout();
  });

  test('Collection access level', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager.create(colType, colMeta, colContent);

    await collectionManager.upload(col);

    {
      final collections = await collectionManager.list([colType]);
      expect(collections.data.length, equals(1));
    }

    final itemManager = collectionManager.getItemManager(col);

    final items = <Item>[];

    for (var i = 0; i < 5; i++) {
      final meta2 = ItemMetadata(type: 'ITEMTYPE', data: {
        'someval': 'someval',
        i.toString(): i,
      });
      final content2 = Uint8List.fromList([i, 7, 2, 3, 5]);
      final item2 = await itemManager.create(meta2, content2);
      items.add(item2);
    }

    await itemManager.batch(items);

    final collectionMemberManager = collectionManager.getMemberManager(col);
    final collectionInvitationManager = etebase.getInvitationManager();

    final etebase2 = await prepareUserForTest(USER2());
    final collectionManager2 = etebase2.getCollectionManager();

    final user2Profile =
        await collectionInvitationManager.fetchUserProfile(USER2().username);

    await collectionInvitationManager.invite(col, USER2().username,
        user2Profile.pubkey, CollectionAccessLevel.ReadWrite);

    final collectionInvitationManager2 = etebase2.getInvitationManager();

    final invitations = await collectionInvitationManager2.listIncoming();
    expect(invitations.data.length, equals(1));

    await collectionInvitationManager2.accept(invitations.data[0]);

    final col2 = await collectionManager2.fetch(col.uid);
    final itemManager2 = collectionManager2.getItemManager(col2);

    // Item creation: success
    {
      final members = await collectionMemberManager.list();
      expect(members.data.length, equals(2));
      for (final member in members.data) {
        if (member.username == USER2().username) {
          expect(member.accessLevel, equals(CollectionAccessLevel.ReadWrite));
        }
      }

      final meta = ItemMetadata(
        type: 'ITEMTYPE2',
      );
      final content = Uint8List.fromList([1, 2, 3, 6]);

      final item = await itemManager2.create(meta, content);
      await itemManager2.batch([item]);
    }

    await collectionMemberManager.modifyAccessLevel(
        USER2().username, CollectionAccessLevel.ReadOnly);

    // Item creation: fail
    {
      final members = await collectionMemberManager.list();
      expect(members.data.length, equals(2));
      for (final member in members.data) {
        if (member.username == USER2().username) {
          expect(member.accessLevel, equals(CollectionAccessLevel.ReadOnly));
        }
      }

      final meta = ItemMetadata(
        type: 'ITEMTYPE3',
      );
      final content = Uint8List.fromList([1, 2, 3, 6]);

      final item = await itemManager2.create(meta, content);
      expect(await itemManager2.batch([item]),
          throwsA(isA<PermissionDeniedError>()));
    }

    await collectionMemberManager.modifyAccessLevel(
        USER2().username, CollectionAccessLevel.Admin);

    // Item creation: success
    {
      final members = await collectionMemberManager.list();
      expect(members.data.length, equals(2));
      for (const member in members.data) {
        if (member.username == USER2().username) {
          expect(member.accessLevel, equals(CollectionAccessLevel.Admin));
        }
      }

      final meta = ItemMetadata(
        type: 'ITEMTYPE3',
      );
      final content = Uint8List.fromList([1, 2, 3, 6]);

      final item = await itemManager2.create(meta, content);
      await itemManager2.batch([item]);
    }

    // Iterate members
    {
      final members =
          await collectionMemberManager.list(IteratorFetchOptions(limit: 1));
      expect(members.data.length, equals(1));
      final members2 = await collectionMemberManager
          .list(IteratorFetchOptions(limit: 1, iterator: members.iterator));
      expect(members2.data.length, equals(1));
      // Verify we got two different usersnames
      expect(
          members.data[0].username, isNot(equals(members2.data[0].username)));

      final membersDone = await collectionMemberManager.list();
      expect(membersDone.done, isTrue);
    }

    await etebase2.logout();
  });

  test('Session store and restore', () async {
    final collectionManager = etebase.getCollectionManager();
    final meta = ItemMetadata(
      name: 'Calendar',
    );

    final col = await collectionManager.create(colType, meta, 'test');
    await collectionManager.upload(col);

    // Verify we can store and restore without an encryption key
    {
      final saved = await etebase.save();
      final etebase2 = await Account.restore(saved);

      // Verify we can access the data
      final collectionManager2 = etebase2.getCollectionManager();
      final collections = await collectionManager2.list([colType]);
      expect(collections.data.length, equals(1));
      expect(await collections.data[0].getContent(OutputFormat.String),
          equals('test'));
    }

    // Verify we can store and restore with an encryption key
    {
      final encryptionKey = randomBytes(32);
      final saved = await etebase.save(encryptionKey);
      // Fail without an encryption key
      // FIXME: Test for the correct error value
      // await expect(Etebase.Account.restore(saved)).rejects.toBeTruthy();
      final etebase2 = await Account.restore(saved, encryptionKey);

      // Verify we can access the data
      final collectionManager2 = etebase2.getCollectionManager();
      final collections = await collectionManager2.list([colType]);
      expect(collections.data.length, equals(1));
      expect(await collections.data[0].getContent(OutputFormat.String),
          equals('test'));
    }
  });

  test('Cache collections and items', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
    );

    final col = await collectionManager.create(colType, colMeta, 'test');
    await collectionManager.upload(col);

    final itemManager = collectionManager.getItemManager(col);

    final meta = ItemMetadata(
      type: 'ITEMTYPE',
    );
    final content = Uint8List.fromList([1, 2, 3, 6]);

    final item = await itemManager.create(meta, content);
    await itemManager.batch([item]);

    final optionsArray = [
      {'saveContent': true},
      {'saveContent': false},
    ];
    for (final options in optionsArray) {
      final savedCachedCollection = collectionManager.cacheSave(col, options);
      final cachedCollection =
          collectionManager.cacheLoad(savedCachedCollection);

      expect(col.uid, equals(cachedCollection.uid));
      expect(col.etag, equals(cachedCollection.etag));
      expect(col.getMeta(), equals(cachedCollection.getMeta()));

      final savedCachedItem = itemManager.cacheSave(item, options);
      final cachedItem = itemManager.cacheLoad(savedCachedItem);

      expect(item.uid, equals(cachedItem.uid));
      expect(item.etag, equals(cachedItem.etag));
      expect(item.getMeta(), equals(cachedItem.getMeta()));
    }

    // Verify content
    {
      final options = {'saveContent': true};
      final savedCachedItem = itemManager.cacheSave(item, options);
      final cachedItem = itemManager.cacheLoad(savedCachedItem);

      expect(await item.getContent(), equals(await cachedItem.getContent()));
    }
  });

  test('Chunk pre-upload and download-missing', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
    );

    final col = await collectionManager.create(colType, colMeta, '');
    await collectionManager.upload(col);

    final itemManager = collectionManager.getItemManager(col);
    final meta = ItemMetadata(
      type: 'itemtype',
    );
    final content = 'Something';
    final item = await itemManager.create(meta, content);
    expect(item.isMissingContent, isNot(isTrue));
    await itemManager.uploadContent(item);
    // Verify we don't fail even when already uploaded
    await itemManager.uploadContent(item);
    await itemManager.batch([item]);

    {
      final item2 = await itemManager.fetch(
          item.uid, ItemFetchOptions(prefetch: PrefetchOption.Medium));
      final meta2 = item2.getMeta();
      expect(meta2, equals(meta));
      // We can't get the content of partial item
      expect(await item2.getContent(), throwsA(isA<MissingContentError>()));
      expect(item2.isMissingContent, isTrue);
      // Fetch the content and then try to get it
      await itemManager.downloadContent(item2);
      expect(item2.isMissingContent, isNot(isTrue));
      expect(await item2.getContent(OutputFormat.String), equals(content));
    }
  });

  test('Chunking large data', () async {
    final collectionManager = etebase.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
    );

    final buf = randomBytesDeterministic(
        120 * 1024, Uint8List(32)); // 120kb of psuedorandom data
    final col = await collectionManager.create(colType, colMeta, '');
    final itemManager = collectionManager.getItemManager(col);
    final item = await itemManager.create(ItemMetadata(), buf);
    await verifyItem(item, ItemMetadata(), buf);

    Future<List<String>> itemGetChunkUids(Item it) async {
      // XXX: hack - get the chunk uids from the cached saving
      final cachedItem =
          msgpackDecode(itemManager.cacheSave(it, {'saveContent': false}));
      final cachedRevision = (msgpackDecode(cachedItem[cachedItem.length - 1]));
      final cachedChunks = cachedRevision[cachedRevision.length - 1];
      return cachedChunks.map((x) => toBase64(x[0]));
    }

    final uidSet = <String>{};

    // Get the first chunks and init uidSet
    {
      final chunkUids = await itemGetChunkUids(item);
      expect(chunkUids.length, equals(8));

      chunkUids.forEach((x) => uidSet.add(x));
    }

    // Bite a chunk off the new buffer
    final biteStart = 10000;
    final biteSize = 210;
    final newBuf = Uint8List(buf.length - biteSize);
    newBuf.setAll(0, buf.sublist(0, biteStart));
    newBuf.setAll(biteStart, buf.sublist(biteStart + biteSize));

    newBuf[39000] = 0;
    newBuf[39001] = 1;
    newBuf[39002] = 2;
    newBuf[39003] = 3;
    newBuf[39004] = 4;

    await item.setContent(newBuf);
    await verifyItem(item, ItemMetadata(), newBuf);

    // Verify how much has changed
    {
      final chunkUids = await itemGetChunkUids(item);
      expect(chunkUids.length, equals(8));

      var reused = 0;

      chunkUids.forEach((x) => {
            if (uidSet.contains(x)) {reused++}
          });

      expect(reused, equals(5));
    }
  });

  test('Login and password change', () async {
    final anotherPassword = 'AnotherPassword';
    final etebase2 =
        await Account.login(USER2().username, USER2().password, testApiBase);

    final collectionManager2 = etebase2.getCollectionManager();
    final colMeta = ItemMetadata(
      name: 'Calendar',
      description: 'Mine',
      color: '#ffffff',
    );

    final colContent = Uint8List.fromList([1, 2, 3, 5]);
    final col = await collectionManager2.create(colType, colMeta, colContent);

    await collectionManager2.upload(col);

    await etebase2.changePassword(anotherPassword);

    {
      // Verify we can still access the data
      final collections = await collectionManager2.list([colType]);
      expect(colMeta, equals(collections.data[0].getMeta()));
    }

    await etebase2.logout();

    expect(await Account.login(USER2().username, USER2().password, testApiBase),
        throwsA(isA<UnauthorizedError>()));

    final etebase3 =
        await Account.login(USER2().username, anotherPassword, testApiBase);

    final collectionManager3 = etebase3.getCollectionManager();

    {
      // Verify we can still access the data
      final collections = await collectionManager3.list([colType]);
      expect(colMeta, equals(collections.data[0].getMeta()));
    }

    await etebase3.changePassword(USER2().password);

    await etebase3.logout();

    // Login via email
    final etebase4 =
        await Account.login(USER2().email, USER2().password, testApiBase);
    await etebase4.logout();
  });
}
