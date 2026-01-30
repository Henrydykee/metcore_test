
// ignore_for_file: unused_catch_stack

import 'dart:developer';
import '../../data/database/db_exceptions.dart';
import '../../data/network/network_exceptions.dart';
import '../error_helpers.dart';
import '../logger.dart';

Future<T> guardedApiCall<T>(Function run, {String? source, bool showNetworkError = false}) async {
  try {
    final val = await run() as T;
    return val;
  } on ApiResponseException catch (e, s) {
    log("ApiResponseException: ${e.exceptionMessage}");
    throw NetworkFailure(e.exceptionMessage.toString() != "" ? e.exceptionMessage.toString() : "Something went wrong, we are trying to fix it");
  } on NetworkConnectivityException catch (e, s) {
    log("NetworkConnectivityException: ${e.exceptionMessage}");
    throw NetworkFailure("Check your internet connection and try again");
  } catch (e, s) {
    log("Unexpected error: ${s.toString()}");
    throw NetworkFailure(showNetworkError ? e.toString() : "Something went wrong, we are trying to fix it");
  }
}


Future<T> guardedCacheAccess<T>(Function run, {String? source}) async {
  try {
    final val = await run() as T;
    return val;
  } catch (e, s) {
    log("---------${e.toString()}");
    logger.e("Exception source >>>>> $source");
    throw getCacheFailureFromDBFailure(
        DBFailure(
            "Sorry, error occurred while retrieving user data, please uninstall your app and reinstall. If this persist, contact support"),
        s);
  }
}
