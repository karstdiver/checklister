import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/services/analytics_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

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
                  // TODO: Navigate to profile
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
            Text(
              tr('welcome_user', args: [currentUser?.email ?? tr('anonymous')]),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
}
