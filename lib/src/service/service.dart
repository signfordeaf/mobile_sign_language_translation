import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_sign_language_translation/mobile_sign_language_translation.dart';
import 'package:mobile_sign_language_translation/src/model/sign_model.dart';
import 'package:mobile_sign_language_translation/src/service/http_exception.dart';

class ApiServices {
  CancelToken cancelToken = CancelToken();

  /// While the server is generating the video it returns `state: false`; the
  /// same GET is repeated until it is ready. Bounded to at most [_maxRetries]
  /// attempts, with [_retryDelay] between them.
  static const int _maxRetries = 30;
  static const Duration _retryDelay = Duration(milliseconds: 1000);

  Dio get dio => Dio(
        BaseOptions(
          baseUrl: SignForDeafManager().requestUrl ?? '',
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          sendTimeout: const Duration(seconds: 30),
          headers: {
            'Accept': 'application/json',
            'origin': SignForDeafManager().originUrl ?? '',
          },
        ),
      );

  Future<SignModel> getSignVideo({
    required String text,
    int retryCount = 0,
  }) async {
    var parameter = {
      's': text,
      'rk': SignForDeafManager().requestKey,
      'fdid': SignForDeafManager().fdid,
      'tid': SignForDeafManager().tid,
      'language': SignForDeafManager().language.apiCode,
      'url': SignForDeafManager().originUrl ?? '',
    };
    try {
      var response = await dio.request(
        '/Translate',
        options: Options(
          method: 'GET',
        ),
        queryParameters: parameter,
        cancelToken: cancelToken,
      );
      switch (response.statusCode) {
        case 200:
          final data = SignModel.fromJson(response.data);
          if (data.state == true) {
            return data;
          } else if (retryCount < _maxRetries) {
            await Future.delayed(_retryDelay);
            return await getSignVideo(text: text, retryCount: retryCount + 1);
          } else {
            // Timed out: the video never became ready.
            return SignModel();
          }
        case 400:
          return handleError(BadRequestException());
        case 401:
          return handleError(UnauthorizedException());
        case 403:
          return handleError(ForbiddenException());
        case 404:
          return handleError(NotFoundException());
        case 500:
          return handleError(ServerException());
        default:
          return handleError(UnknownException(response.statusCode ?? 0));
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        return SignModel(state: false, cid: 'cancelled');
      } else if (kReleaseMode) {
        debugPrint('Server error: The server encountered an internal error.');
        return SignModel();
      } else {
        rethrow;
      }
    }
  }

  void cancelRequest() {
    cancelToken.cancel('Request has been cancelled');
    cancelToken = CancelToken();
  }
}

SignModel handleError(Exception exception) {
  if (kReleaseMode) {
    debugPrint('Handled exception: $exception');
    return SignModel();
  } else {
    throw exception;
  }
}
