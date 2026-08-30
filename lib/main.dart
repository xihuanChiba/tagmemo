import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/auth/cloud_config.dart';
import 'src/repositories/note_repository.dart';
import 'src/storage/local_database.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TagMemoBootstrap());
}

class TagMemoBootstrap extends StatefulWidget {
  const TagMemoBootstrap({super.key});

  @override
  State<TagMemoBootstrap> createState() => _TagMemoBootstrapState();
}

class _TagMemoBootstrapState extends State<TagMemoBootstrap> {
  late Future<NoteRepository> _startup = _initialize();

  Future<NoteRepository> _initialize() async {
    await CloudConfig.initialize();
    final repository = NoteRepository(LocalDatabase());
    try {
      await repository.initialize();
      return repository;
    } catch (_) {
      repository.dispose();
      rethrow;
    }
  }

  void _retry() {
    setState(() => _startup = _initialize());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NoteRepository>(
      future: _startup,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return TagMemoApp(repository: snapshot.requireData);
        }

        return MaterialApp(
          title: 'TagMemo',
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: snapshot.hasError
                      ? _StartupError(
                          error: snapshot.error,
                          onRetry: _retry,
                        )
                      : const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 20),
                            Text('メモを準備しています…'),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline, size: 48),
        const SizedBox(height: 16),
        Text(
          '起動の準備に失敗しました',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        const Text(
          '端末内のメモを読み込めませんでした。再試行しても直らない場合は、下の内容をお知らせください。',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SelectableText(
          error?.toString() ?? '不明なエラー',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('再試行'),
        ),
      ],
    );
  }
}
