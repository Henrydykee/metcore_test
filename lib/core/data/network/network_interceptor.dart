import 'package:dio/dio.dart';
import '../../di/di_config.dart';
import '../../platform/storage/secured_storage.dart';
import '../../platform/string_constants.dart';
import 'network_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

class NetworkInterceptor extends InterceptorsWrapper {
  NetworkConfig? networkConfigInterface;
  DeviceInfoPlugin? deviceInfo;

  NetworkInterceptor({this.networkConfigInterface, this.deviceInfo});

  String _getOSType() {
    if (Platform.isAndroid) return "Android";
    if (Platform.isIOS) return "iOS";
    if (Platform.isMacOS) return "macOS";
    return "Unknown";
  }
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    var authToken = await inject<SecuredStorage>().get(key: SecureStorageStrings.TOKEN) ?? "";
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final headers = {
      "Content-Type": "application/json",
     "Authorization": "Bearer ${authToken}",
      "build_number": packageInfo.buildNumber,
      "Accept": "application/json",
      "os_type": _getOSType(),
      "os_version": Platform.operatingSystemVersion.toString(),

    };

    if (skipToken(options.path)) {
      headers.remove("Authorization");
    }



    networkConfigInterface = NetworkConfigImpl(headers: headers);

    options.headers.addAll(networkConfigInterface!.headers!);
    return super.onRequest(options, handler);
  }

  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    return super.onError(err, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    return super.onResponse(response, handler);
  }
}

bool skipToken(String path) {
  return [
  ].contains(path);
}
