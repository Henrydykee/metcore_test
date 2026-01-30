import 'package:dio/dio.dart';

import '../../platform/env_config.dart';
import '../../utils/logger.dart';
import 'network_config.dart';
import 'network_exceptions.dart';
import 'network_interceptor.dart';
import 'network_service.dart';
import 'network_service_response.dart';

class NetworkServiceImpl implements NetworkService {
  static var networkSetupOptions = BaseOptions(
    connectTimeout: const Duration(seconds: 3000),
    followRedirects: true,
    baseUrl: EnvConfig.instance!.values!.baseUrl,
  );

  NetworkConfig? _networkConfiguration;
  final Dio _dio = Dio(networkSetupOptions);

  NetworkServiceImpl({
    NetworkConfig? networkConfiguration,
    NetworkInterceptor? interceptor,
  }) {
    try {
      _networkConfiguration = networkConfiguration!;
      registerInterceptor(interceptor!);
    } catch (e) {
      logger.e("Error while registering interceptors");
    }
  }

  registerInterceptor(NetworkInterceptor? interceptor) {
    if (interceptor == null) {
      throw Exception(
        "Interceptor cannot be null",
      );
    }
    if (_dio.interceptors.contains(interceptor)) return;
    _dio.interceptors.add(interceptor);
  }

  registerInterceptors(List<NetworkInterceptor>? interceptors) {
    if (interceptors == null) {
      throw Exception(
        "Interceptors cannot be null",
      );
    }

    for (var interceptor in interceptors) {
      if (!_dio.interceptors.contains(interceptor)) {
        _dio.interceptors.add(interceptor);
      }
    }
  }

  @override
  Future<NetworkServiceResponse> get(String url,
      {Map<String, dynamic>? queryParameters}) async {
    Response response;
    try {
      response = await _dio.get(
        url,
        options: Options(headers: _networkConfiguration!.headers),
        queryParameters: queryParameters,
      );

      return NetworkServiceResponse(
          result: NetworkResult.SUCCESS, data: response.data);
    } on DioException catch (e, trace) {
      logger.e(e);
      return handleException(e, trace);
    }
  }

  @override
  Future<NetworkServiceResponse> post(String url, {Map<String, dynamic>? body, Map<String, dynamic>? queryParameters}) async {
    Response response;
    try {
      response = await _dio.post(
        url,
        options: Options(headers: _networkConfiguration!.headers),
        queryParameters: queryParameters,
        data: body,
      );

      return NetworkServiceResponse(
        result: NetworkResult.SUCCESS,
        data: response.data,
      );
    } on DioException catch (e, trace) {
      logger.e(e,stackTrace: trace);
      return handleException(e, trace);
    }
  }

  @override
  Future<NetworkServiceResponse> delete(String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response;
    try {
      response = await _dio.delete(
        url,
        options: Options(headers: _networkConfiguration!.headers),
        queryParameters: queryParameters,
        data: body,
      );
      return NetworkServiceResponse(
        result: NetworkResult.SUCCESS,
        data: response.data,
      );
    } on DioException catch (e, trace) {
      logger.e(e);
      return handleException(e, trace);
    }
  }

  @override
  Future<NetworkServiceResponse> patch(String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response;
    try {
      response = await _dio.patch(
        url,
        options: Options(headers: _networkConfiguration!.headers),
        queryParameters: queryParameters,
        data: body,
      );

      return NetworkServiceResponse(
        result: NetworkResult.SUCCESS,
        data: response.data,
      );
    } on DioException catch (e, trace) {
      logger.e(e);
      return handleException(e, trace);
    }
  }

  @override
  Future<NetworkServiceResponse> put(String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  }) async {
    Response response;
    try {
      response = await _dio.put(
        url,
        options: Options(headers: _networkConfiguration!.headers),
        queryParameters: queryParameters,
        data: body,
      );
      return NetworkServiceResponse(
        result: NetworkResult.SUCCESS,
        data: response.data,
      );
    } on DioException catch (e, trace) {
      logger.e(e.message);
      return handleException(e, trace);
    }
  }

}
