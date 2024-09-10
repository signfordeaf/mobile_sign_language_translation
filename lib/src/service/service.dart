import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_sign_language_translation/signfordeaf.dart';
import 'package:mobile_sign_language_translation/src/model/sign_model.dart';
import 'package:mobile_sign_language_translation/src/service/http_exception.dart';

class ApiServices {
  CancelToken cancelToken = CancelToken();

  var dio = Dio(
    BaseOptions(
      baseUrl: SignForDeafManager().requestUrl ?? '',
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  );

  Future<SignModel> getSignVideo({
    required String text,
  }) async {
    var parameter = {
      's': text,
      'rk': SignForDeafManager().requestKey,
      'fdid': '16',
      'tid': '23',
      'language': '1',
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
          } else {
            await Future.delayed(const Duration(milliseconds: 1000));
            return await getSignVideo(text: text);
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
