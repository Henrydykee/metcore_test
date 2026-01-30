import 'network_exceptions.dart';

class NetworkServiceResponse {
  final NetworkResult? result;
  final dynamic data;
  final dynamic error;
  final Map<String, dynamic>? headers;

  NetworkServiceResponse({this.result, this.data, this.headers, this.error});
}

enum NetworkResult {
  FAILURE,
  SUCCESS,
  NO_INTERNET_CONNECTION,
  SERVER_ERROR,
  BAD_REQUEST,
  UNAUTHORISED,
  FORBIDDEN,
  NO_SUCH_ENDPOINT,
  METHOD_DISALLOWED,
  SERVER_TIMEOUT,
  TOO_MANY_REQUESTS,
  NOT_IMPLEMENTED
}

handleNetworkResponse(NetworkServiceResponse response) {
  if (response.result != NetworkResult.SUCCESS) {
    if (response.result == NetworkResult.FAILURE || response.result == NetworkResult.NO_INTERNET_CONNECTION) {
      throw NetworkConnectivityException(exceptionMessage: "${response.error}");
    }
    throw ApiResponseException(exceptionMessage: response.error as String, data: response.data);
  }
  return response.data;
}

