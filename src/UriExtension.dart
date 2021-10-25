extension UriExtension on Uri {
  Uri clone() => replace();

  Uri normalize() {
    return normalizePath();
  }

  dynamic segment([dynamic parameter, String? parameter2]) {
    if (parameter == null) {
      return pathSegments;
    }

    if (parameter is int) {
      if (parameter2 is String) {
        if (parameter2 == '') {
          return replace(pathSegments: pathSegments..removeAt(parameter));
        }
        return replace(
            pathSegments: pathSegments
              ..replaceRange(parameter, parameter, [parameter2]));
      }
      return pathSegments[parameter];
    }

    if (parameter is List<String>) {
      return replace(pathSegments: parameter);
    }

    if (parameter is String) {
      return replace(pathSegments: pathSegments..add(parameter));
    }

    return this;
  }

  dynamic search([dynamic parameter]) {
    if (parameter == null) {
      return query;
    }

    if (parameter is Map<String, dynamic>) {
      return replace(queryParameters: parameter);
    }
  }
}
