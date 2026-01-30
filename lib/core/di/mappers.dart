import 'package:dart_mappable/dart_mappable.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/home/data/models/home_data_model.dart';
 setupMappers()   {
    MapperContainer.globals.use(UserModelMapper.ensureInitialized());
    MapperContainer.globals.use(HomeDataModelMapper.ensureInitialized());


}