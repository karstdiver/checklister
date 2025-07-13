import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/providers/providers.dart';
import '../../../shared/widgets/logout_dialog.dart';
import '../../../core/providers/settings_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(currentUserProvider);
        final authState = ref.watch(authStateProvider);
        final navigationNotifier = ref.read(
          navigationNotifierProvider.notifier,
        );
        final authNotifier = ref.read(authNotifierProvider.notifier);

        // Watch the current locale to trigger rebuilds when language changes
        final currentLocale = context.locale;

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('settings')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: ListView(
            children: [
              // Debug info
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auth Status: ${authState.status}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (currentUser != null)
                      Text(
                        'User: ${currentUser.uid}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),

              // User Info Section
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('account'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Text(
                              currentUser?.email?.isNotEmpty == true
                                  ? currentUser!.email!
                                        .substring(0, 1)
                                        .toUpperCase()
                                  : 'U',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentUser?.email ?? tr('anonymous'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  'User ID: ${currentUser?.uid ?? 'N/A'}',
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
                    ],
                  ),
                ),
              ),

              // Settings Options
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(tr('profile')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(tr('notifications')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Navigate to notifications settings
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.language),
                      title: Text(tr('language')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.pushNamed(context, '/language');
                      },
                    ),
                  ],
                ),
              ),

              // Theme selection section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Theme',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Center(
                child: Platform.isIOS
                    ? CupertinoSegmentedControl<ThemeMode>(
                        groupValue: ref.watch(settingsProvider).themeMode,
                        children: const {
                          ThemeMode.system: Text('System'),
                          ThemeMode.light: Text('Light'),
                          ThemeMode.dark: Text('Dark'),
                        },
                        onValueChanged: (mode) {
                          ref
                              .read(settingsProvider.notifier)
                              .setThemeMode(mode);
                        },
                      )
                    : DropdownButton<ThemeMode>(
                        value: ref.watch(settingsProvider).themeMode,
                        items: const [
                          DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.light,
                            child: Text('Light'),
                          ),
                          DropdownMenuItem(
                            value: ThemeMode.dark,
                            child: Text('Dark'),
                          ),
                        ],
                        onChanged: (mode) {
                          if (mode != null) {
                            ref
                                .read(settingsProvider.notifier)
                                .setThemeMode(mode);
                          }
                        },
                      ),
              ),

              const SizedBox(height: 16),

              // Account Actions
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.help, color: Colors.blue),
                      title: Text(tr('help')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => navigationNotifier.navigateToHelp(),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.info, color: Colors.blue),
                      title: Text(tr('about')),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () => navigationNotifier.navigateToAbout(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Logout Section
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    tr('logout'),
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () async {
                    await LogoutDialog.show(context, authNotifier, ref);
                  },
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }
}
