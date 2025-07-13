import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/services/analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../sessions/domain/session_state.dart';
import '../../sessions/domain/session_providers.dart';
import '../../sessions/presentation/session_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = AnalyticsService();
    final currentUser = ref.watch(currentUserProvider);
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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

            // Test Session Feature Section
            Consumer(
              builder: (context, ref, child) {
                final activeSession = ref.watch(
                  activeSessionProvider('test_checklist'),
                );

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '🧪 Test Session Feature',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Test the new session management system with sample checklist items',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Show active session info if available
                        if (activeSession != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.pause_circle,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Session in Progress',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                      Text(
                                        '${activeSession.completedItems} completed, ${activeSession.skippedItems} skipped',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _resumeTestSession(
                                    context,
                                    activeSession,
                                  ),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Resume Session'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _startTestSession(
                                    context,
                                    forceNew: true,
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Start New'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          ElevatedButton.icon(
                            onPressed: () => _startTestSession(context),
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start Test Session'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Checklists section
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
                    // TODO: Navigate to create checklist
                    await analytics.logCustomEvent(
                      name: 'create_checklist_clicked',
                      parameters: {'source': 'header_button'},
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: Text(tr('create_new')),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for checklists list
            Expanded(
              child: Center(
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
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr('create_first_checklist'),
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Navigate to create checklist
                      },
                      icon: const Icon(Icons.add),
                      label: Text(tr('create_checklist')),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create checklist
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _startTestSession(BuildContext context, {bool forceNew = false}) {
    // Create sample checklist items for testing
    final testItems = [
      ChecklistItem(
        id: 'item_1',
        text: 'Check engine oil level',
        status: ItemStatus.pending,
      ),
      ChecklistItem(
        id: 'item_2',
        text: 'Inspect brake fluid',
        status: ItemStatus.pending,
      ),
      ChecklistItem(
        id: 'item_3',
        text: 'Test windshield wipers',
        status: ItemStatus.pending,
      ),
      ChecklistItem(
        id: 'item_4',
        text: 'Check tire pressure',
        status: ItemStatus.pending,
      ),
      ChecklistItem(
        id: 'item_5',
        text: 'Verify all lights are working',
        status: ItemStatus.pending,
      ),
    ];

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          checklistId: 'test_checklist',
          items: testItems,
          forceNewSession: forceNew,
        ),
      ),
    );
  }

  void _resumeTestSession(BuildContext context, SessionState activeSession) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionScreen(
          checklistId: activeSession.checklistId,
          items: activeSession.items,
        ),
      ),
    );
  }
}
