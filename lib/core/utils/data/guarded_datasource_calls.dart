
// ignore_for_file: unused_catch_stack

import 'dart:developer';
import '../../data/database/db_exceptions.dart';
import '../../data/network/network_exceptions.dart';
import '../error_helpers.dart';
import '../logger.dart';

/// Make an API call that internally handles exceptions. Throws a [NetworkFailure].
///
/// This is intended to always be used for ALL remoteDatasurce calls in the repository layer.
/// This means there'll be no need for API-related try-catch blocks in the repository layer.
///
/// The named [*Msg] params may be used to customise the error message depending
/// on the error type. For example, `notFoundMsg` can be set to "User not found",
/// which is descriptive enough to be sent to the Presentation layer for use in
/// a [UIError].
/// Also, you can set `anyMsg` to force all error messages no matter the type to
/// one custom message.
Future<T> guardedApiCall<T>(Function run, {String? source, bool showNetworkError = false}) async {
  try {
    final val = await run() as T;
    return val;
  } on ApiResponseException catch (e, s) {
    // This exception should now carry the correct error message from the server
    log("ApiResponseException: ${e.exceptionMessage}");

    // If the message from the API is available, display it; otherwise, fallback to the default message
    throw new NetworkFailure( e.exceptionMessage.toString() != "" ? e.exceptionMessage.toString() : "Something went wrong, we are trying to fix it");
  } on NetworkConnectivityException catch (e, s) {
    // Handle no internet connection errors
    log("NetworkConnectivityException: ${e.exceptionMessage}");
    throw NetworkFailure("Check your internet connection and try again");
  } catch (e, s) {
    // Catch any other errors
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
