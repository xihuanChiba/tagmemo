import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/auth/cloud_config.dart';
import 'src/repositories/note_repository.dart';
import 'src/storage/local_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudConfig.initialize();
  final repository = NoteRepository(LocalDatabase());
  await repository.initialize();
  runApp(TagMemoApp(repository: repository));
}
