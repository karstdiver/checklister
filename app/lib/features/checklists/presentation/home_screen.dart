import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/services/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../sessions/domain/session_state.dart' as sessions;
import '../../sessions/domain/session_providers.dart';
import '../../sessions/presentation/session_screen.dart';
import '../../sessions/data/session_repository.dart';
import '../domain/checklist_providers.dart';
import '../domain/checklist.dart';
import 'widgets/checklist_card.dart';
import 'checklist_editor_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      Future.microtask(
        () => ref
            .read(checklistNotifierProvider.notifier)
            .loadUserChecklists(currentUser.uid),
      );
    }
  }

  Widget _buildWelcomeText(User? currentUser) {
    if (currentUser == null) {
      print('No currentUser, using anonymous');
      return Text(
        tr('welcome_user', args: [tr('anonymous')]),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        String displayName = currentUser.email ?? tr('anonymous');
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          print('Firestore user doc: ${data.toString()}');
          if (data['displayName'] != null &&
              data['displayName'].toString().isNotEmpty) {
            print('Using Firestore displayName: ${data['displayName']}');
            displayName = data['displayName'];
          } else if (currentUser.displayName != null &&
              currentUser.displayName!.isNotEmpty) {
            print('Using Auth displayName: ${currentUser.displayName}');
            displayName = currentUser.displayName!;
          } else {
            print('Using email: ${currentUser.email}');
          }
        } else if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          print(
            'No Firestore doc or displayName, using Auth displayName: ${currentUser.displayName}',
          );
          displayName = currentUser.displayName!;
        } else {
          print(
            'No Firestore or Auth displayName, using email: ${currentUser.email}',
          );
        }
        return Text(
          tr('welcome_user', args: [displayName]),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService();
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final checklistsAsync = ref.watch(checklistNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('home')),
        actions: [
          // User menu
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/profile');
                  break;
                case 'settings':
                  Navigator.pushNamed(context, '/settings');
                  break;
                case 'logout':
                  await LogoutDialog.show(context, authNotifier, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 8),
                    Text(tr('profile')),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 8),
                    Text(tr('settings')),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    Text(tr('logout')),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(
                  //currentUser?.email?.substring(0, 1).toUpperCase() ?? 'U',
                  currentUser?.email?.isNotEmpty == true
                      ? currentUser!.email!.substring(0, 1).toUpperCase()
                      : 'U',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Debug info
            Text(
              'Auth Status: ${authState.status}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (currentUser != null)
              Text(
                'User: ${currentUser.uid}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            const SizedBox(height: 16),

            // Welcome message
            _buildWelcomeText(currentUser),
            const SizedBox(height: 24),

            // Checklists section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tr('my_checklists'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await analytics.logCustomEvent(
                          name: 'create_checklist_clicked',
                          parameters: {'source': 'header_button'},
                        );
                        _navigateToCreateChecklist(context);
                      },
                      icon: const Icon(Icons.add),
                      label: Text(tr('create_new')),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                checklistsAsync.when(
                  data: (checklists) {
                    if (checklists.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.checklist_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              tr('no_checklists_yet'),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              tr('create_first_checklist'),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _navigateToCreateChecklist(context),
                              icon: const Icon(Icons.add),
                              label: Text(tr('create_checklist')),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: checklists.length,
                      itemBuilder: (context, index) {
                        final checklist = checklists[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ChecklistCard(
                            checklist: checklist,
                            onTap: () =>
                                _navigateToChecklist(context, checklist),
                            onEdit: () =>
                                _navigateToEditChecklist(context, checklist),
                            onDelete: () =>
                                _deleteChecklist(context, checklist),
                            onDuplicate: () =>
                                _duplicateChecklist(context, checklist),
                            onShare: () => _shareChecklist(context, checklist),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('error_loading_checklists'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (currentUser != null) {
                              ref
                                  .read(checklistNotifierProvider.notifier)
                                  .loadUserChecklists(currentUser.uid);
                            }
                          },
                          child: Text(tr('retry')),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateChecklist(context),
        child: const Icon(Icons.add),
      ),
    );
  } //,

  //);
}

// Checklist CRUD methods
void _navigateToCreateChecklist(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ChecklistEditorScreen()),
  );
}

void _navigateToChecklist(BuildContext context, Checklist checklist) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('error_user_not_authenticated')),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  // Check if there's an active session for this checklist
  final sessionNotifier = ProviderScope.containerOf(
    context,
  ).read(sessionNotifierProvider.notifier);
  final activeSession = await sessionNotifier.getActiveSession(
    currentUser.uid,
    checklist.id,
  );

  print('🔍 Checking for active session for checklist: ${checklist.id}');
  print('🔍 Active session found: ${activeSession != null}');
  if (activeSession != null) {
    print('🔍 Session status: ${activeSession.status}');
    print('🔍 Session ID: ${activeSession.sessionId}');
    print(
      '🔍 Completed items: ${activeSession.completedItems}/${activeSession.totalItems}',
    );
  }

  if (activeSession != null &&
      (activeSession.status == sessions.SessionStatus.inProgress ||
          activeSession.status == sessions.SessionStatus.paused)) {
    // Show dialog to choose between resume or new session
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tr('session_in_progress')),
        content: Text(
          tr(
            'session_in_progress_message',
            args: [
              checklist.title,
              activeSession.completedItems.toString(),
              activeSession.totalItems.toString(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('resume'),
            child: Text(tr('resume_session')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop('new'),
            child: Text(tr('start_new_session')),
          ),
        ],
      ),
    );

    if (choice == 'resume') {
      // Resume existing session
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SessionScreen(
            checklistId: checklist.id,
            checklistTitle: checklist.title,
            items: activeSession.items,
            forceNewSession: false,
          ),
        ),
      );
    } else if (choice == 'new') {
      // Start new session
      _startNewChecklistSession(context, checklist, startNewIfActive: true);
    }
  } else {
    // No active session, start new one directly
    _startNewChecklistSession(context, checklist);
  }
}

void _startNewChecklistSession(
  BuildContext context,
  Checklist checklist, {
  bool startNewIfActive = false,
}) {
  // Convert checklist items to sessions domain ChecklistItem
  final sessionItems = checklist.items
      .map(
        (item) => sessions.ChecklistItem(
          id: item.id,
          text: item.text,
          imageUrl: item.imageUrl,
          status: sessions.ItemStatus.pending,
          completedAt: null,
          skippedAt: null,
          notes: item.notes,
        ),
      )
      .toList();

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => SessionScreen(
        checklistId: checklist.id,
        checklistTitle: checklist.title,
        items: sessionItems,
        forceNewSession: false, // Let the SessionScreen handle session logic
        startNewIfActive: startNewIfActive,
      ),
    ),
  );
}

void _navigateToEditChecklist(BuildContext context, Checklist checklist) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ChecklistEditorScreen(checklist: checklist),
    ),
  );
}

Future<void> _deleteChecklist(BuildContext context, Checklist checklist) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(tr('delete_checklist')),
      content: Text(
        tr('delete_checklist_confirmation', args: [checklist.title]),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(tr('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text(tr('delete')),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    final notifier = ProviderScope.containerOf(
      context,
    ).read(checklistNotifierProvider.notifier);
    final success = await notifier.deleteChecklist(checklist.id);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('checklist_deleted')),
          backgroundColor: Colors.green,
        ),
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr('error_deleting_checklist')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _duplicateChecklist(
  BuildContext context,
  Checklist checklist,
) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('error_user_not_authenticated')),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final notifier = ProviderScope.containerOf(
    context,
  ).read(checklistNotifierProvider.notifier);
  final duplicatedChecklist = await notifier.duplicateChecklist(
    checklist.id,
    currentUser.uid,
  );

  if (duplicatedChecklist != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('checklist_duplicated')),
        backgroundColor: Colors.green,
      ),
    );
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(tr('error_duplicating_checklist')),
        backgroundColor: Colors.red,
      ),
    );
  }
}

void _shareChecklist(BuildContext context, Checklist checklist) {
  // TODO: Implement sharing functionality
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Sharing checklist: ${checklist.title}')),
  );
}

//}
