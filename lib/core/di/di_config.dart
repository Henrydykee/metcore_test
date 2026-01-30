import 'package:get_it/get_it.dart';
import 'core_di.dart';

GetIt inject = GetIt.instance;

/// Registration of service dependencies with  service locator GetIt
///
/// Add any such dependency here
Future<void> initInjectors() async {
  // await Firebase.initializeApp();
  await coreInjector();
  
}
