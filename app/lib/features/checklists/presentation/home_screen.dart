import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/services/translation_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../sessions/domain/session_state.dart' as sessions;
import '../../sessions/domain/session_providers.dart';
import '../../sessions/presentation/session_screen.dart';
import '../domain/checklist_providers.dart';
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
      return Text(
        TranslationService.translate('welcome_user', [
          TranslationService.translate('anonymous'),
        ]),
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
    }
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get(),
      builder: (context, snapshot) {
        String displayName =
            currentUser.email ?? TranslationService.translate('anonymous');
        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() as Map<String, dynamic>;
          if (data['displayName'] != null &&
              data['displayName'].toString().isNotEmpty) {
            displayName = data['displayName'];
          } else if (currentUser.displayName != null &&
              currentUser.displayName!.isNotEmpty) {
            displayName = currentUser.displayName!;
          }
        } else if (currentUser.displayName != null &&
            currentUser.displayName!.isNotEmpty) {
          displayName = currentUser.displayName!;
        }
        return Text(
          TranslationService.translate('welcome_user', [displayName]),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        );
      },
    );
  }

  Widget _buildTierIndicator(WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTierColor(currentTier),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTierIcon(currentTier), color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            _getTierDisplayName(currentTier),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTierColor(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return Colors.grey;
      case UserTier.free:
        return Colors.blue;
      case UserTier.premium:
        return Colors.purple;
      case UserTier.pro:
        return Colors.orange;
    }
  }

  IconData _getTierIcon(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return Icons.person_outline;
      case UserTier.free:
        return Icons.star_outline;
      case UserTier.premium:
        return Icons.star;
      case UserTier.pro:
        return Icons.star_rounded;
    }
  }

  String _getTierDisplayName(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return 'Anonymous';
      case UserTier.free:
        return 'Free';
      case UserTier.premium:
        return 'Premium';
      case UserTier.pro:
        return 'Pro';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the translation provider to trigger rebuilds when language changes
        ref.watch(translationProvider);

        final currentUser = ref.watch(currentUserProvider);
        final authNotifier = ref.read(authNotifierProvider.notifier);
        final checklistsAsync = ref.watch(checklistNotifierProvider);

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
                    if (checklists.isEmpty) {
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
                            if (currentUser != null) {
                              ref
                                  .read(checklistNotifierProvider.notifier)
                                  .loadUserChecklists(currentUser.uid);
                            }
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
}
