class HttpException implements Exception {
  final int statusCode;
  final String message;

  HttpException(this.statusCode, this.message);

  @override
  String toString() => 'HttpException($statusCode): $message';
}

class BadRequestException extends HttpException {
  BadRequestException()
      : super(
          400,
          'Bad request: The server could not understand the request due to invalid syntax.',
        );
}

class UnauthorizedException extends HttpException {
  UnauthorizedException()
      : super(
          401,
          'Unauthorized: Authentication is required and has failed or has not yet been provided.',
        );
}

class ForbiddenException extends HttpException {
  ForbiddenException()
      : super(
          403,
          'Forbidden: The server understood the request, but it refuses to authorize it.',
        );
}

class NotFoundException extends HttpException {
  NotFoundException()
      : super(
          404,
          'Not found: The requested resource could not be found on the server.',
        );
}

class ServerException extends HttpException {
  ServerException()
      : super(
          500,
          'Server error: The server encountered an internal error and was unable to complete the request.',
        );
}

class UnknownException extends HttpException {
  UnknownException(int statusCode)
      : super(
          statusCode,
          'Unexpected error: An unexpected error occurred with status code $statusCode.',
        );
}
