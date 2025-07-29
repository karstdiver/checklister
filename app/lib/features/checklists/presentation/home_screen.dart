import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/services/translation_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../sessions/domain/session_state.dart' as sessions;
import '../../sessions/domain/session_providers.dart';
import '../../sessions/presentation/session_screen.dart';
import '../domain/checklist_providers.dart';
import '../../achievements/domain/achievement_providers.dart';
import 'widgets/checklist_card.dart';

import 'checklist_editor_screen.dart';
import '../../../core/widgets/tier_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../auth/domain/profile_provider.dart';
import '../../auth/presentation/login_screen.dart';

final connectivityProvider = StreamProvider<ConnectivityResult>((ref) async* {
  final initial = await Connectivity().checkConnectivity();
  yield initial;
  yield* Connectivity().onConnectivityChanged;
});

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load checklists for the current user on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final userId = currentUser.uid;
        final connectivity = ref.read(connectivityProvider).asData?.value;
        print(
          '[DEBUG] HomeScreen: Initial load for userId=$userId, connectivity=$connectivity',
        );

        // Load profile
        ref
            .read(profileNotifierProvider.notifier)
            .loadProfile(userId, connectivity: connectivity);

        // Load checklists
        ref
            .read(checklistNotifierProvider.notifier)
            .loadUserChecklists(userId, connectivity: connectivity);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Always listen for user changes and reload checklists with the latest connectivity
    ref.listen<User?>(currentUserProvider, (prev, next) {
      // If the user has changed (different UID or null), clear and reload
      if (prev?.uid != next?.uid) {
        final userId = next?.uid ?? 'anonymous';
        final connectivity = ref.read(connectivityProvider).asData?.value;
        print(
          '[DEBUG] HomeScreen: Auth state changed, clearing and loading checklists for userId=$userId',
        );
        print(
          '[DEBUG] HomeScreen: prev user: ${prev?.uid}, next user: ${next?.uid}',
        );
        print(
          '[DEBUG] HomeScreen: next user isAnonymous: ${next?.isAnonymous}',
        );
        print(
          '[DEBUG] HomeScreen: prev user isAnonymous: ${prev?.isAnonymous}',
        );

        // Immediately clear the state to prevent showing stale data
        ref.read(checklistNotifierProvider.notifier).clear();

        // Clear any active sessions from the previous user
        ref.read(sessionNotifierProvider.notifier).clearSession();

        // Clear achievements from the previous user
        ref.read(achievementNotifierProvider.notifier).clearAllAchievements();

        // Load profile for the new user
        if (next != null) {
          ref
              .read(profileNotifierProvider.notifier)
              .loadProfile(next.uid, connectivity: connectivity);
        }

        // Load checklists for the new user
        print(
          '[DEBUG] HomeScreen: About to load checklists with connectivity=$connectivity',
        );

        // Just pass the connectivity value (can be null, our simplified logic handles it)
        ref
            .read(checklistNotifierProvider.notifier)
            .loadUserChecklists(userId, connectivity: connectivity);
      } else {
        print(
          '[DEBUG] HomeScreen: User UID unchanged, skipping reload (prev: ${prev?.uid}, next: ${next?.uid})',
        );
      }
    });

    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    final currentUser = ref.watch(currentUserProvider);
    final authNotifier = ref.read(authNotifierProvider.notifier);
    final checklistsAsync = ref.watch(checklistNotifierProvider);
    final privileges = ref.watch(privilegeProvider);

    if (privileges == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Consumer(
      builder: (context, ref, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('home')),
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
                    case 'admin_panel':
                      Navigator.pushNamed(context, '/account/settings');
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
                        Text(TranslationService.translate('profile')),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'settings',
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(TranslationService.translate('settings')),
                      ],
                    ),
                  ),
                  // Admin Panel Option
                  if (ref.watch(privilegeProvider)?.canAccessAdminPanel == true)
                    PopupMenuItem(
                      value: 'admin_panel',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.admin_panel_settings,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(TranslationService.translate('admin_panel')),
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
                        Text(TranslationService.translate('logout')),
                      ],
                    ),
                  ),
                ],
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Text(
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
                // Welcome section
                _buildWelcomeText(currentUser),
                const SizedBox(height: 8),
                _buildTierIndicator(ref),
                const SizedBox(height: 16),

                // Sign-up encouragement for anonymous users
                SignupEncouragement(
                  title: 'Unlock More Features',
                  message:
                      'Create a free account to save your checklists, edit them later, and track your progress!',
                  featureName: 'Save • Edit • Track Progress',
                  onSignupPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            const LoginScreen(initialSignUpMode: true),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // My Checklists section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      TranslationService.translate('my_checklists'),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChecklistEditorScreen(),
                          ),
                        );
                      },
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Create new checklist card
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.add_circle_outline, size: 32),
                    title: Text(
                      TranslationService.translate('create_new'),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      TranslationService.translate('create_checklist'),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ChecklistEditorScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Checklists list
                checklistsAsync.when(
                  data: (checklists) {
                    // Use the latest connectivity state in the UI
                    final connectivity = ref.watch(connectivityProvider);
                    final isOffline =
                        connectivity.asData?.value == ConnectivityResult.none;
                    final isUnknown = connectivity.asData == null;

                    if (checklists.isEmpty) {
                      if (isOffline || isUnknown) {
                        return Column(
                          children: [
                            const Icon(
                              Icons.cloud_off,
                              size: 64,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No checklists available offline.',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect to the internet to sync your checklists.',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        );
                      }
                      print(
                        '[DEBUG] HomeScreen: Showing normal empty state widget',
                      );
                      return Column(
                        children: [
                          const Icon(
                            Icons.checklist_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            TranslationService.translate('no_checklists_yet'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            TranslationService.translate(
                              'create_first_checklist',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChecklistEditorScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add),
                            label: Text(
                              TranslationService.translate('create_checklist'),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      children: checklists.map((checklist) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ChecklistCard(
                            checklist: checklist,
                            onTap: () {
                              // Check if there's an active session
                              final activeSession = ref.read(
                                sessionNotifierProvider,
                              );
                              if (activeSession != null &&
                                  activeSession.checklistId == checklist.id) {
                                // Show dialog to resume or start new session
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      TranslationService.translate(
                                        'session_in_progress',
                                      ),
                                    ),
                                    content: Text(
                                      TranslationService.translate(
                                        'session_already_in_progress',
                                        [checklist.title],
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          TranslationService.translate(
                                            'cancel',
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          ref
                                              .read(
                                                sessionNotifierProvider
                                                    .notifier,
                                              )
                                              .clearSession();
                                          Navigator.pop(context);
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SessionScreen(
                                                checklistId: checklist.id,
                                                checklistTitle: checklist.title,
                                                items: checklist.items
                                                    .map(
                                                      (item) =>
                                                          sessions.ChecklistItem(
                                                            id: item.id,
                                                            text: item.text,
                                                            imageUrl:
                                                                item.imageUrl,
                                                            status: sessions
                                                                .ItemStatus
                                                                .pending,
                                                            completedAt: null,
                                                            skippedAt: null,
                                                            notes: item.notes,
                                                          ),
                                                    )
                                                    .toList(),
                                                totalChecklistItems:
                                                    checklist.items.length,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          TranslationService.translate(
                                            'resume_session',
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          ref
                                              .read(
                                                sessionNotifierProvider
                                                    .notifier,
                                              )
                                              .clearSession();
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SessionScreen(
                                                checklistId: checklist.id,
                                                checklistTitle: checklist.title,
                                                startNewIfActive:
                                                    true, // Force start new session
                                                items: checklist.items
                                                    .map(
                                                      (item) =>
                                                          sessions.ChecklistItem(
                                                            id: item.id,
                                                            text: item.text,
                                                            imageUrl:
                                                                item.imageUrl,
                                                            status: sessions
                                                                .ItemStatus
                                                                .pending,
                                                            completedAt: null,
                                                            skippedAt: null,
                                                            notes: item.notes,
                                                          ),
                                                    )
                                                    .toList(),
                                                totalChecklistItems:
                                                    checklist.items.length,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          TranslationService.translate(
                                            'start_new_session',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              } else {
                                // Start new session
                                ref
                                    .read(sessionNotifierProvider.notifier)
                                    .clearSession();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SessionScreen(
                                      checklistId: checklist.id,
                                      checklistTitle: checklist.title,
                                      // Debug print for checklist items
                                      // ignore: avoid_print
                                      items: (() {
                                        return checklist.items
                                            .map(
                                              (item) => sessions.ChecklistItem(
                                                id: item.id,
                                                text: item.text,
                                                imageUrl: item.imageUrl,
                                                status:
                                                    sessions.ItemStatus.pending,
                                                completedAt: null,
                                                skippedAt: null,
                                                notes: item.notes,
                                              ),
                                            )
                                            .toList();
                                      })(),
                                      totalChecklistItems:
                                          checklist.items.length,
                                    ),
                                  ),
                                );
                              }
                            },
                            onEdit: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChecklistEditorScreen(
                                    checklist: checklist,
                                  ),
                                ),
                              );
                            },
                            onDuplicate: () async {
                              try {
                                if (currentUser != null) {
                                  await ref
                                      .read(checklistNotifierProvider.notifier)
                                      .duplicateChecklist(
                                        checklist.id,
                                        currentUser.uid,
                                      );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TranslationService.translate(
                                            'checklist_duplicated',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        TranslationService.translate(
                                          'error_duplicating_checklist',
                                        ),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            },
                            onDelete: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    TranslationService.translate(
                                      'delete_checklist',
                                    ),
                                  ),
                                  content: Text(
                                    TranslationService.translate(
                                      'delete_checklist_confirmation',
                                      [checklist.title],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: Text(
                                        TranslationService.translate('cancel'),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        TranslationService.translate('delete'),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (confirmed == true) {
                                try {
                                  await ref
                                      .read(checklistNotifierProvider.notifier)
                                      .deleteChecklist(checklist.id);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TranslationService.translate(
                                            'checklist_deleted',
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          TranslationService.translate(
                                            'error_deleting_checklist',
                                          ),
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            onShare: () {
                              // Share functionality
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) {
                    print('[DEBUG] HomeScreen: checklistsAsync error: $error');
                    return Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          TranslationService.translate(
                            'error_loading_checklists',
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final currentUser =
                                FirebaseAuth.instance.currentUser;
                            final userId = currentUser?.uid ?? 'anonymous';
                            final connectivity = ref
                                .read(connectivityProvider)
                                .asData
                                ?.value;
                            ref
                                .read(checklistNotifierProvider.notifier)
                                .loadUserChecklists(
                                  userId,
                                  connectivity: connectivity,
                                );
                          },
                          child: Text(TranslationService.translate('retry')),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeText(User? currentUser) {
    if (currentUser == null) {
      return Text(
        TranslationService.translate('welcome_user', [
          TranslationService.translate('anonymous'),
        ]),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }

    // Use profile provider for display name
    final profile = ref.watch(profileDataProvider);
    final displayName =
        profile?.displayNameOrEmail ??
        currentUser.displayName ??
        currentUser.email ??
        TranslationService.translate('anonymous');

    return Text(
      TranslationService.translate('welcome_user', [displayName]),
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTierIndicator(WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;
    return TierIndicator(tier: currentTier);
  }
}
