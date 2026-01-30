import 'dart:developer';

import 'package:dio/dio.dart';

import 'network_service_response.dart';

/// Thrown on unhandled API exceptions
class ApiResponseException implements Exception {
  String? exceptionMessage;
  dynamic data;

  ApiResponseException({this.exceptionMessage, this.data});

  @override
  String toString() => '{exceptionMessage: $exceptionMessage, data: $data}';
}

class NetworkConnectivityException implements Exception {
  String? exceptionMessage = "No internet connectivity";
  NetworkConnectivityException({this.exceptionMessage});

  @override
  String toString() => '{exception: $exceptionMessage}';
}


NetworkServiceResponse handleException(DioException e, StackTrace trace) {
  if (e.response != null) {
    dynamic errorData = {"error": e};
    String errorMessage = "Looks like something is wrong, we are working to fix it";

    // Log the response data to check its structure
    log('Response data: ${e.response?.data}');

    if (e.response!.data is Map) {
      // Handle the case where the data is a Map
      errorMessage = e.response?.data["message"] ?? errorMessage;
    } else if (e.response!.data is String) {
      // Handle the case where the data is a String
      errorMessage = e.response?.data ?? errorMessage;
    }

    if (e.response!.statusCode! >= 500) {
      return NetworkServiceResponse(
        result: NetworkResult.SERVER_ERROR,
        data: errorData,
        error: errorMessage,
      );
    }
    if (e.response!.statusCode! == 401) {
      return NetworkServiceResponse(
        result: NetworkResult.UNAUTHORISED,
        data: errorData,
        error: errorMessage,
      );
    } else {
      return NetworkServiceResponse(
        data: errorData,
        error: errorMessage,
      );
    }
  } else {
    return NetworkServiceResponse(
      result: NetworkResult.FAILURE,
      data: {"error": e.message},
      error: e.message,
    );
  }
}


final errorCodes = {"ERROR_CODE": "Custom message"};
