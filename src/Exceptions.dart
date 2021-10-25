class ExtendableError extends Error {
  String message;
  String name;
  ExtendableError(this.message) : name = 'ExtendableError';
}

abstract class HttpFieldErrors {
  String code;
  String detail;
  String? field;
  HttpFieldErrors(this.code, this.detail, this.field);
}

abstract class HttpErrorContent {
  String? code;
  String? detail;
  List<HttpFieldErrors>? errors;
  HttpErrorContent(this.code, this.detail, this.errors);
}

class HttpError extends ExtendableError {
  int status;
  HttpErrorContent? content;

  HttpError(this.status, String message, this.content)
      : super('$status $message') {
    name = 'HTTPError';

    status = status;
    content = content;
  }
}

class NetworkError extends ExtendableError {
  NetworkError(String message) : super(message) {
    name = 'NetworkError';
  }
}

class IntegrityError extends ExtendableError {
  IntegrityError(String message) : super(message) {
    name = 'IntegrityError';
  }
}

class MissingContentError extends ExtendableError {
  MissingContentError(String message) : super(message) {
    name = 'MissingContentError';
  }
}

class UnauthorizedError extends ExtendableError {
  HttpErrorContent? content;
  UnauthorizedError(String message, this.content) : super(message) {
    name = 'UnauthorizedError';
  }
}

class PermissionDeniedError extends ExtendableError {
  PermissionDeniedError(String message) : super(message) {
    name = 'PermissionDeniedError';
  }
}

class ConflictError extends ExtendableError {
  ConflictError(String message) : super(message) {
    name = 'ConflictError';
  }
}

class NotFoundError extends ExtendableError {
  NotFoundError(String message) : super(message) {
    name = 'NotFoundError';
  }
}

class TemporaryServerError extends HttpError {
  TemporaryServerError(int status, String message, HttpErrorContent? content)
      : super(status, message, content) {
    name = 'TemporaryServerError';
  }
}

class ServerError extends HttpError {
  ServerError(int status, String message, HttpErrorContent? content)
      : super(status, message, content) {
    name = 'ServerError';
  }
}

class ProgrammingError extends ExtendableError {
  ProgrammingError(String message) : super(message) {
    name = 'ProgrammingError';
  }
}
