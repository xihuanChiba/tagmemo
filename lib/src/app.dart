import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_service.dart';
import 'repositories/note_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

class TagMemoApp extends StatefulWidget {
  const TagMemoApp({super.key, required this.repository});

  final NoteRepository repository;

  @override
  State<TagMemoApp> createState() => _TagMemoAppState();
}

class _TagMemoAppState extends State<TagMemoApp> {
  final _authService = AuthService();
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = _authService.authChanges?.listen((state) {
      if (state.event == AuthChangeEvent.signedIn ||
          state.event == AuthChangeEvent.tokenRefreshed) {
        unawaited(widget.repository.sync(silent: true));
      }
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    widget.repository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TagMemo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: HomeScreen(
        repository: widget.repository,
        authService: _authService,
      ),
    );
  }
}
