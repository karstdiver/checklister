import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'account_settings_screen.dart';
import 'upgrade_screen.dart';

class ProfileOverviewScreen extends ConsumerStatefulWidget {
  const ProfileOverviewScreen({super.key});

  @override
  ConsumerState<ProfileOverviewScreen> createState() =>
      _ProfileOverviewScreenState();
}

class _ProfileOverviewScreenState extends ConsumerState<ProfileOverviewScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final currentUser = ref.read(currentUserProvider);
      if (currentUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'User profile not found';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'No authenticated user';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Consumer(
      builder: (context, ref, child) {
        final currentUser = ref.watch(currentUserProvider);
        final navigationNotifier = ref.read(
          navigationNotifierProvider.notifier,
        );

        // Show encouragement screen for anonymous users
        if (currentUser == null || currentUser.isAnonymous) {
          return AnonymousProfileEncouragement();
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
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorWidget()
              : _buildProfileContent(currentUser, navigationNotifier),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadUserData,
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(
    User? currentUser,
    NavigationNotifier navigationNotifier,
  ) {
    final stats = _userData?['stats'] as Map<String, dynamic>? ?? {};
    final preferences =
        _userData?['preferences'] as Map<String, dynamic>? ?? {};

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // Profile Header
          _buildProfileHeader(currentUser),
          const SizedBox(height: 16),

          // Quick Stats
          _buildQuickStats(stats),
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

  Widget _buildProfileHeader(User? currentUser) {
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
                    _userData?['profileImageUrl'] ?? currentUser?.photoURL,
                size: 80,
                onImageChanged: () {
                  // Reload user data to get the updated profile image
                  _loadUserData();
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

  Widget _buildQuickStats(Map<String, dynamic> stats) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('statistics'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.checklist,
                    label: TranslationService.translate('total_checklists'),
                    value: '${stats['totalChecklists'] ?? 0}',
                    textColor: textColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: TranslationService.translate('completed_checklists'),
                    value: '${stats['completedChecklists'] ?? 0}',
                    textColor: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.list,
                    label: TranslationService.translate('total_items'),
                    value: '${stats['totalItems'] ?? 0}',
                    textColor: textColor,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.done_all,
                    label: TranslationService.translate('completed_items'),
                    value: '${stats['completedItems'] ?? 0}',
                    textColor: textColor,
                  ),
                ),
              ],
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
              _formatTimestamp(_userData?['createdAt']),
              textColor,
            ),
            _buildInfoRow(
              TranslationService.translate('last_updated'),
              _formatTimestamp(_userData?['updatedAt']),
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
              // TODO: Navigate to privacy and security settings
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
            onTap: () => navigationNotifier.navigateToHelp(),
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
