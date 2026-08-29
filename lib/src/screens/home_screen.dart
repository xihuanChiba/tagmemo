import 'package:flutter/material.dart';

import '../auth/auth_service.dart';
import '../auth/cloud_config.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';
import '../widgets/note_card.dart';
import 'edit_note_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.repository,
    required this.authService,
  });

  final NoteRepository repository;
  final AuthService authService;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _title {
    if (widget.repository.selectedLabel != null) {
      return widget.repository.selectedLabel!;
    }
    return switch (widget.repository.section) {
      NoteSection.notes => 'TagMemo',
      NoteSection.archive => 'アーカイブ',
      NoteSection.trash => 'ゴミ箱',
    };
  }

  Future<void> _openEditor([Note? note]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => EditNoteScreen(
          repository: widget.repository,
          note: note,
        ),
      ),
    );
  }

  Future<void> _showAccount() async {
    if (!CloudConfig.enabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('現在はオフライン版です。Supabase設定後にGoogle同期を利用できます。'),
        ),
      );
      return;
    }
    final user = widget.authService.user;
    if (user == null) {
      try {
        await widget.authService.signInWithGoogle();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Googleログインを開始できませんでした。')),
        );
      }
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('同期アカウント'),
        content: Text(user.email ?? 'Googleアカウントでログイン中'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('閉じる'),
          ),
          FilledButton.tonal(
            onPressed: () async {
              await widget.authService.signOut();
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('ログアウト'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.repository,
      builder: (context, _) {
        final notes = widget.repository.visibleNotes;
        return Scaffold(
          drawer: _NavigationDrawer(
            repository: widget.repository,
            accountEmail: widget.authService.user?.email,
            onAccountTap: _showAccount,
          ),
          appBar: AppBar(
            title: Text(_title),
            actions: [
              if (widget.repository.isSyncing)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                IconButton(
                  tooltip: '同期',
                  onPressed: () async {
                    await widget.repository.sync();
                    if (!context.mounted) return;
                    final message = widget.repository.syncMessage;
                    if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                ),
              IconButton(
                tooltip: widget.authService.user?.email ?? 'Googleアカウント',
                onPressed: _showAccount,
                icon: Icon(
                  widget.authService.user == null
                      ? Icons.account_circle_outlined
                      : Icons.account_circle,
                ),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(66),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: SearchBar(
                  controller: _search,
                  hintText: 'メモを検索',
                  leading: const Icon(Icons.search),
                  trailing: [
                    if (_search.text.isNotEmpty)
                      IconButton(
                        tooltip: '検索を消去',
                        onPressed: () {
                          _search.clear();
                          widget.repository.setQuery('');
                          setState(() {});
                        },
                        icon: const Icon(Icons.close),
                      ),
                  ],
                  onChanged: (value) {
                    widget.repository.setQuery(value);
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
          body: notes.isEmpty
              ? _EmptyState(section: widget.repository.section)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final columns = width >= 1100
                        ? 4
                        : width >= 760
                            ? 3
                            : width >= 520
                                ? 2
                                : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: columns == 1 ? 1.9 : 1.15,
                      ),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return NoteCard(
                          note: note,
                          onTap: () {
                            if (note.isDeleted) {
                              _confirmRestore(note);
                            } else {
                              _openEditor(note);
                            }
                          },
                          onPin: () {
                            if (note.isDeleted) {
                              _confirmRestore(note);
                            } else {
                              widget.repository.togglePinned(note);
                            }
                          },
                        );
                      },
                    );
                  },
                ),
          floatingActionButton: widget.repository.section == NoteSection.trash
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _openEditor(),
                  icon: const Icon(Icons.add),
                  label: const Text('メモ'),
                ),
        );
      },
    );
  }

  Future<void> _confirmRestore(Note note) async {
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('メモを復元しますか？'),
        content: Text(note.title.isEmpty ? '無題' : note.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('復元'),
          ),
        ],
      ),
    );
    if (restore == true) await widget.repository.restore(note);
  }
}

class _NavigationDrawer extends StatelessWidget {
  const _NavigationDrawer({
    required this.repository,
    required this.accountEmail,
    required this.onAccountTap,
  });

  final NoteRepository repository;
  final String? accountEmail;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    void closeThen(VoidCallback action) {
      Navigator.pop(context);
      action();
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.note_alt_outlined)),
              title: const Text('TagMemo'),
              subtitle: Text(accountEmail ?? 'オフラインで利用中'),
              onTap: () => closeThen(onAccountTap),
            ),
            const Divider(),
            ListTile(
              selected: repository.section == NoteSection.notes &&
                  repository.selectedLabel == null,
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('メモ'),
              onTap: () => closeThen(
                () => repository.showSection(NoteSection.notes),
              ),
            ),
            for (final label in repository.labels)
              ListTile(
                selected: repository.selectedLabel == label,
                leading: const Icon(Icons.label_outline),
                title: Text(label),
                onTap: () => closeThen(() => repository.selectLabel(label)),
              ),
            const Divider(),
            ListTile(
              selected: repository.section == NoteSection.archive,
              leading: const Icon(Icons.archive_outlined),
              title: const Text('アーカイブ'),
              onTap: () => closeThen(
                () => repository.showSection(NoteSection.archive),
              ),
            ),
            ListTile(
              selected: repository.section == NoteSection.trash,
              leading: const Icon(Icons.delete_outline),
              title: const Text('ゴミ箱'),
              onTap: () => closeThen(
                () => repository.showSection(NoteSection.trash),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.section});

  final NoteSection section;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (section) {
      NoteSection.notes => (Icons.note_add_outlined, '右下のボタンからメモを作成できます'),
      NoteSection.archive => (Icons.archive_outlined, 'アーカイブしたメモはありません'),
      NoteSection.trash => (Icons.delete_outline, 'ゴミ箱は空です'),
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 12),
          Text(text),
        ],
      ),
    );
  }
}
