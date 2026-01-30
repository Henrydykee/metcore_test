import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app_theme.dart';
import 'core/data/enums/type_enums.dart';
import 'core/data/network/network_service.dart';
import 'core/di/di_config.dart';
import 'core/platform/env_config.dart';
import 'features/notes/data/datasources/notes_local_datasource.dart';
import 'features/notes/data/datasources/notes_remote_datasource.dart';
import 'features/notes/data/models/note_model_adapter.dart';
import 'features/notes/data/repositories/notes_repository_impl.dart';
import 'features/notes/domain/repositories/notes_repository.dart';
import 'features/notes/presentation/providers/notes_providers.dart';
import 'features/notes/presentation/screens/notes_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());
  
  // Configure environment with base URL
  EnvConfig(
    flavor: Env.STAGING,
    values: EnvVar(baseUrl: 'http://localhost:8080/v1'),
  );
  
  // Initialize dependency injection (includes NetworkService)
  await initInjectors();
  
  // Initialize datasources
  final box = await NotesLocalDatasource.openBox();
  final local = NotesLocalDatasource(box);
  final remote = NotesRemoteDatasource(inject<NetworkService>());

  final NotesRepository repo = NotesRepositoryImpl(local, remote);

  runApp(
    ProviderScope(
      overrides: [
        notesRepositoryProvider.overrideWithValue(repo),
      ],
      child: const FieldNotesApp(),
    ),
  );
}

class FieldNotesApp extends StatelessWidget {
  const FieldNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Filed Notes',
      theme: AppTheme.light,
      home: const NotesListScreen(),
    );
  }
}
