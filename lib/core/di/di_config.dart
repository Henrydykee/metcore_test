import 'package:get_it/get_it.dart';
import 'core_di.dart';

GetIt inject = GetIt.instance;

Future<void> initInjectors() async {
  await coreInjector();
}
