const sessionStorageKey = 'YA0cMVJ9Q_SKYJCvKNni9y13vf62rEIq8M6kjtT14b4';

abstract class USER {
  String get username;

  String get email;

  String get password;

  String get pubkey;

  String get encryptedContent;

  String get loginPubkey;

  String get key;

  String get salt;

  String get storedSession;
}

class USER1 implements USER {
  @override
  String get username => 'test_user';

  @override
  String get email => 'test@localhost';

  @override
  String get password => 'SomePassword';

  @override
  String get pubkey => 'CXNdzeU6FgHz9ei64wJbKDhHc0fkoJ1p_c8zGuFeuGA';

  @override
  String get encryptedContent =>
      'wjRGC2jhqYdtF7lO1aS2I5r8gaWx4mZR19_lMZeoNZVU3HbBTqlFC5zZkN-NOO-4cDPZk2xk27GspPLHkOH59-Jk5fAY5hKFT8Vdp0jSgBvKOww-zXXlKfzhkjrReyUSsBwra_NAxGg';

  @override
  String get loginPubkey => 'A9K94qEAqMm_yrt0wXKwG6H7DDimFIxaRqCpKRrOSuI';

  @override
  String get key => 'Eq9b_rdbzeiU3P4sg5qN24KXbNgy8GgCeC74nFF99hI';

  @override
  String get salt => '6y7jUaojtLq6FISBWPjwXTeiYk5cTiz1oe6HVNGvn2E';

  @override
  String get storedSession =>
      'gqd2ZXJzaW9uAa1lbmNyeXB0ZWREYXRhxQGmmvZjsltGTbmbHECPtUBlTgICvtJHKHp246hnKKiDeJL90CrIOPzjRW6mQMDX0SnQ8S32YEVLS2Ji5jzVfZOkyWzePAeSZmDpUxZd8N5WJ0BiuMKauG9UvXzdAGgVAVH9YA3dzPbAZUtpoU2W94eqbupPCEUsjraLnLFW9g2UVrh35z4OW9QoC_0vgzqigpWySkTdJ_FjmQqalbuQF9CaTFJcngMnBy7uos4tKw53RawDQ_EdwuRQLJrVGP-9zQKzyi-Y5X_8eWImGcjHYZvLbN6O0uDxEDfcg0dQGaBB7YV94akSKIjPRHebvXYoPSjI-r0YkA9Q_-tiaGxSwIFq-uVgWzOX9tq4dXsVP-2QffhV8Bx1hUHTHOyd6TCfEqQ3nWWaLsqA9yAoDg-XAPXHVffFwJ5b3accJU_Y5H8_w6PmbBdrVFyN7lP6JB6yGBDs3gpT4osNwet1rRR_ueERr1ThSZcqdCwjfhOTZq0p5R3SAnzAnUJo0LUUBkuzNGeMCSlIPJgE4HjOWXgLUYxZOlbDIN6yHp4SGIiAepSGOUrcjmRCQaA';
}
// final user1EncryptedContent =Uint8List.fromList([
//   55,
//   200,
//   174,
//   254,
//   167,
//   88,
//   232,
//   172,
//   243,
//   4,
//   198,
//   129,
//   150,
//   2,
//   1,
//   70,
//   59,
//   176,
//   228,
//   39,
//   48,
//   152,
//   162,
//   16,
//   103,
//   66,
//   126,
//   22,
//   221,
//   88,
//   157,
//   225,
//   193,
//   229,
//   180,
//   19,
//   26,
//   229,
//   46,
//   13,
//   218,
//   197,
//   133,
//   129,
//   89,
//   236,
//   230,
//   143,
//   253,
//   11,
//   250,
//   136,
//   191,
//   16,
//   6,
//   72,
//   86,
//   64,
//   191,
//   130,
//   174,
//   55,
//   26,
//   89,
//   103,
//   101,
//   217,
//   152,
//   49,
//   53,
//   168,
//   84,
//   238,
//   186,
//   214,
//   10,
//   53,
//   168,
//   221,
//   44,
//   217,
//   98,
//   158,
//   245,
//   80,
//   125,
//   232,
//   19,
//   57,
//   155,
//   0,
//   118,
//   60,
//   209,
//   86,
//   220,
//   50,
//   10,
//   133,
//   6,
//   214,
//   236,
//   204,
//   104
// ]);
// class USER {
//   static final username = 'test_user_1';
//   static final email = 'test_user_1@email.com';
//   static final password = 'test_user_1';
//   static final pubkey = Uint8List.fromList([
//     41,
//     81,
//     247,
//     45,
//     97,
//     179,
//     160,
//     27,
//     121,
//     36,
//     91,
//     253,
//     157,
//     115,
//     180,
//     168,
//     201,
//     114,
//     142,
//     12,
//     13,
//     147,
//     12,
//     99,
//     245,
//     69,
//     236,
//     99,
//     234,
//     196,
//     133,
//     118
//   ]);
//   static final encryptedContent = user1EncryptedContent;
//   static final loginPubkey = Uint8List.fromList([
//     41,
//     81,
//     247,
//     45,
//     97,
//     179,
//     160,
//     27,
//     121,
//     36,
//     91,
//     253,
//     157,
//     115,
//     180,
//     168,
//     201,
//     114,
//     142,
//     12,
//     13,
//     147,
//     12,
//     99,
//     245,
//     69,
//     236,
//     99,
//     234,
//     196,
//     133,
//     118
//   ]);
//       static final key = Uint8List.fromList([
//     60,
//     189,
//     206,
//     94,
//     241,
//     190,
//     141,
//     240,
//     18,
//     235,
//     189,
//     194,
//     118,
//     128,
//     199,
//     219,
//     20,
//     206,
//     218,
//     156,
//     78,
//     19,
//     188,
//     221,
//     203,
//     37,
//     151,
//     210,
//     59,
//     117,
//     26,
//     155
//   ]);
//   static final salt = Uint8List.fromList([ 236,  82, 135, 199,  53,   7, 80, 249,
//     156,  37,  36,  60, 233, 120, 34, 173,
//     188, 193, 215, 212, 182, 162, 77,  43,
//     136,  37, 133, 141, 231, 252, 38, 235
//   ]);
//   static final storedSession = msgpackEncode({
//     'version': Constants.CURRENT_VERSION,
//     'encryptedData': user1EncryptedContent,
//   });
// }

class USER2 implements USER {
  @override
  String get username => 'test_user2';

  @override
  String get email => 'test2@localhost';

  @override
  String get password => 'SomePassword';

  @override
  String get pubkey => 'QOZOIEUx2aSnEvrubiHxQ8Tf2UBw6eLea778H0-Bp3g';

  @override
  String get encryptedContent =>
      'aomaCuUO5cYXPPxo7SdnvXqBUyqfgx-Hz9YK87e2R7CsfoxzQi1MJGLOfol7S2xXFUmIfSeQLr2Tq4BUBIkitHipDefmr73TP9gV3n-unORW0Vzw0zwpv2I8Aftf2O__DlGk9WfN_NA';

  @override
  String get loginPubkey => 'h6tXrc783wSW3-TfnI5qg1teJbN5bQRcDE1fjZQ9Y08';

  @override
  String get key => 'AWXkhEFuf_vKquq-vTgHoYRu9NXr0z4ZeScwaLSgoT4';

  @override
  String get salt => 'xXfZM3DEiBNqL0pjfGgZSbTU82w9eD1UXUd54LuwMrU';

  @override
  String get storedSession =>
      'gqd2ZXJzaW9uAa1lbmNyeXB0ZWREYXRhxQGozXNEXNXVzqw02Kh0aasRFAQiqxRxsNidJM1oHx0ng0GhNOTZ_jhdGEAx3SF1DTip3jFj_y9T6lqMrKS7vd5qjAcHWgueUExYNAHu6Mugx75lYiJbXhIX58KdFpqIZt49PX7rrD7ObyDikYnNFHRhO3TN_hhhOROahVNQCdtZurNsSnziHNgPAUZz_UIPBjDu0G5DHIPRaL4CQ0AaaiqJ-B4yURm-ygBmjV-m8jw8JA7KTPdwqY4Oe_dhdu3iQAZreRnI2R6eHybf2RjTXcLqKjIEMiFL7yR61pNV0p3hAtm8I3L8rX0BhpxrxmfdOrWyba4hJIGXxhFim8K-w5UrU8n21bGTij-xArXpIonT1GCd3YBJrgEH65sym0ED4n4gUiMqL3JT81II1ttlcywuSWHEH5wN6JPI59APe3aLQinDKe-cH2-4HHQJ5hRoJVzJiugLLnHAUJxbLOLv2QCpIpuSRhB0zCmZMTeq8KK5ZyrsanEZdSNf_UkD6_58TkdVba7f_l3LOSAA5-NsQeehpkf80t2xccVN7hyKEHNvZyDsX8VieKpAZQ';
}
