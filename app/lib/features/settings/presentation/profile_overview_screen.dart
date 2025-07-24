import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/providers/providers.dart';
import '../../../core/navigation/navigation_notifier.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../features/auth/presentation/widgets/profile_image_picker.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../core/widgets/anonymous_profile_encouragement.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../auth/domain/profile_provider.dart';
import '../../auth/domain/profile_state.dart';
import '../../auth/data/profile_cache_model.dart';
import 'account_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'upgrade_screen.dart';

// Connectivity provider for this screen
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) async* {
  yield await Connectivity().checkConnectivity();
  await for (final result in Connectivity().onConnectivityChanged) {
    yield result;
  }
});

class ProfileOverviewScreen extends ConsumerStatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  ConsumerState<ProfileOverviewScreen> createState() =>
      _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends ConsumerState<ProfileOverviewScreen> {
  @override
  void initState() {
    super.initState();
    // Don't auto-load profile to avoid infinite loops
  }

  Future<void> _loadProfile() async {
    print('[DEBUG] ProfileOverviewScreen: _loadProfile called');
    final currentUser = ref.read(currentUserProvider);
    print('[DEBUG] ProfileOverviewScreen: currentUser = ${currentUser?.uid}');
    if (currentUser != null) {
      final connectivity = ref.read(connectivityProvider).asData?.value;
      print('[DEBUG] ProfileOverviewScreen: connectivity = $connectivity');
      ref
          .read(profileNotifierProvider.notifier)
          .loadProfile(currentUser.uid, connectivity: connectivity);
    } else {
      print('[DEBUG] ProfileOverviewScreen: No current user');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(currentUserProvider);
        final profileState = ref.watch(profileStateProvider);
        final navigationNotifier = ref.read(
          navigationNotifierProvider.notifier,
        );

        // Show encouragement screen for anonymous users
        if (currentUser == null || currentUser.isAnonymous) {
          return AnonymousProfileEncouragement();
        }

        // Load profile if not already loaded and not loading
        if (profileState.isInitial && currentUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _loadProfile();
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('profile')),
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
            ),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/profile/edit');
                },
                icon: const Icon(Icons.edit),
              ),
            ],
          ),
          body: profileState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : profileState.hasError
              ? _buildErrorWidget(profileState.errorMessage ?? 'Unknown error')
              : profileState.profile == null
              ? _buildSimpleProfileContent(currentUser, navigationNotifier)
              : _buildProfileContent(
                  currentUser,
                  navigationNotifier,
                  profileState,
                ),
        );
      },
    );
  }

  Widget _buildErrorWidget(String errorMessage) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Use a simple callback to avoid potential rebuild loops
              Future.microtask(() => _loadProfile());
            },
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleProfileContent(
    User? currentUser,
    NavigationNotifier navigationNotifier,
  ) {
    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Simple Profile Header
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: currentUser?.photoURL != null
                        ? NetworkImage(currentUser!.photoURL!)
                        : null,
                    child: currentUser?.photoURL == null
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    currentUser?.displayName ?? currentUser?.email ?? 'User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Loading profile data...',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Simple Actions
          AppCard(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Account Settings'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pushNamed(context, '/account/settings');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help),
                  title: const Text('Help & Support'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => navigationNotifier.navigateToHelp(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    User? currentUser,
    NavigationNotifier navigationNotifier,
    ProfileState profileState,
  ) {
    final profile = profileState.profile;
    print(
      '[DEBUG] ProfileOverviewScreen: Building profile content, profile = ${profile?.uid}',
    );

    if (profile == null) {
      return const Center(child: Text('Profile not available'));
    }

    final stats = profile.stats;
    final preferences = profile.preferences;

    return RefreshIndicator(
      onRefresh: _loadProfile,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Profile Header
          _buildProfileHeader(currentUser, profile),
          const SizedBox(height: 16),

          // Profile Actions
          _buildProfileActions(navigationNotifier),
          const SizedBox(height: 16),

          // Advanced Features
          _buildAdvancedFeatures(navigationNotifier),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? currentUser, ProfileCacheModel? profile) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            ProfilePicturesGuard(
              child: ProfileImagePicker(
                currentImageUrl:
                    profile?.profileImageUrlOrPhotoURL ?? currentUser?.photoURL,
                size: 80,
                onImageChanged: () {
                  // Reload profile to get the updated profile image
                  _loadProfile();
                },
              ),
              fallback: ProfilePictureEncouragement(
                onSignUp: () {
                  // TODO: Navigate to signup screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        TranslationService.translate('signup_flow_coming_soon'),
                      ),
                    ),
                  );
                },
                onUpgrade: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const UpgradeScreen(),
                    ),
                  );
                },
                onDetails: () {
                  final privileges = ref.read(privilegeProvider);
                  final currentTier = privileges?.tier ?? UserTier.anonymous;
                  showDialog(
                    context: context,
                    builder: (context) =>
                        ProfilePictureDetailsDialog(userTier: currentTier),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // User Name
            Text(
              currentUser?.displayName ??
                  currentUser?.email ??
                  TranslationService.translate('anonymous'),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // User Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Text(
                TranslationService.translate('active'),
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textColor,
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textColor.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileActions(NavigationNotifier navigationNotifier) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit, color: Colors.blue, size: 20),
            title: Text(
              TranslationService.translate('edit_profile'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/profile/edit');
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.analytics, color: Colors.green, size: 20),
            title: Text(
              TranslationService.translate('detailed_statistics'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to statistics screen
            },
          ),
          const Divider(height: 1),
          AchievementsGuard(
            child: ListTile(
              dense: true,
              leading: const Icon(
                Icons.emoji_events,
                color: Colors.orange,
                size: 20,
              ),
              title: Text(
                TranslationService.translate('achievements'),
                style: TextStyle(fontSize: 14, color: textColor),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pushNamed(context, '/achievements');
              },
            ),
            fallback: ListTile(
              dense: true,
              leading: const Icon(
                Icons.emoji_events,
                color: Colors.grey,
                size: 20,
              ),
              title: Text(
                TranslationService.translate('achievements'),
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              trailing: const Icon(Icons.lock, color: Colors.grey, size: 16),
              onTap: () {
                // Show upgrade encouragement
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.translate('upgrade_flow_coming_soon'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(
    User? currentUser,
    Map<String, dynamic> preferences,
    ProfileCacheModel? profile,
  ) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('account_information'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              TranslationService.translate('email'),
              currentUser?.email ??
                  TranslationService.translate('not_available'),
              textColor,
            ),
            _buildInfoRow(
              TranslationService.translate('user_id'),
              currentUser?.uid ?? TranslationService.translate('not_available'),
              textColor,
            ),
            _buildInfoRow(
              TranslationService.translate('email_verified'),
              currentUser?.emailVerified == true
                  ? TranslationService.translate('yes')
                  : TranslationService.translate('no'),
              textColor,
            ),
            _buildInfoRow(
              TranslationService.translate('account_created'),
              _formatTimestamp(profile?.createdAt),
              textColor,
            ),
            _buildInfoRow(
              TranslationService.translate('last_updated'),
              _formatTimestamp(profile?.updatedAt),
              textColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFeatures(NavigationNotifier navigationNotifier) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.settings, color: Colors.grey, size: 20),
            title: Text(
              TranslationService.translate('account_settings'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AccountSettingsScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.security, color: Colors.grey, size: 20),
            title: Text(
              TranslationService.translate('privacy_security'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.help, color: Colors.grey, size: 20),
            title: Text(
              TranslationService.translate('help_support'),
              style: TextStyle(fontSize: 14, color: textColor),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/help');
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return TranslationService.translate('not_available');

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return TranslationService.translate('not_available');
    } catch (e) {
      return TranslationService.translate('not_available');
    }
  }
}
