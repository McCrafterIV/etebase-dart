import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'Exceptions.dart';

enum HttpMethod { get, post, patch, put, delete }

class RequestInit {
  HttpMethod? method;
  Map<String, String>? headers;
  Object? body;

  RequestInit({this.method, this.body, this.headers});
}

class Response {
  String type;
  int status;
  bool ok;
  String statusText;
  Uint8List body;

  Response({
    required this.type,
    required this.status,
    required this.ok,
    required this.statusText,
    required this.body,
  });
}

Future<Response> request(String url, RequestInit? options) async {
  try {
    http.Response response;
    if (options?.method == HttpMethod.post) {
      response =
          await http.post(Uri.parse(url), headers: {...?options?.headers});
    } else if (options?.method == HttpMethod.put) {
      response =
          await http.put(Uri.parse(url), headers: {...?options?.headers});
    } else if (options?.method == HttpMethod.patch) {
      response =
          await http.patch(Uri.parse(url), headers: {...?options?.headers});
    } else if (options?.method == HttpMethod.delete) {
      response =
          await http.delete(Uri.parse(url), headers: {...?options?.headers});
    } else {
      response =
          await http.get(Uri.parse(url), headers: {...?options?.headers});
    }

    return Response(
        type: 'default',
        status: response.statusCode,
        ok: response.statusCode >= 200 && response.statusCode < 300,
        statusText: response.statusCode.toString(),
        body: response.bodyBytes);
  } catch (e) {
    throw NetworkError('Network request failed!');
  }
}
