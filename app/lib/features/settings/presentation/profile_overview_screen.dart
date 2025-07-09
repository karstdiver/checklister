import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/providers/providers.dart';
import '../../../core/navigation/navigation_notifier.dart';
import '../../../shared/widgets/app_card.dart';

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
    final currentUser = ref.watch(currentUserProvider);
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('profile')),
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
          ElevatedButton(onPressed: _loadUserData, child: Text(tr('retry'))),
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

          // Account Information
          _buildAccountInfo(currentUser, preferences),
          const SizedBox(height: 16),

          // Advanced Features
          _buildAdvancedFeatures(navigationNotifier),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(User? currentUser) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue,
              backgroundImage: currentUser?.photoURL != null
                  ? NetworkImage(currentUser!.photoURL!)
                  : null,
              child: currentUser?.photoURL == null
                  ? Text(
                      currentUser?.email?.isNotEmpty == true
                          ? currentUser!.email!.substring(0, 1).toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),

            // User Name
            Text(
              currentUser?.displayName ?? currentUser?.email ?? tr('anonymous'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                tr('active'),
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
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('statistics'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.checklist,
                    label: tr('total_checklists'),
                    value: '${stats['totalChecklists'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.check_circle,
                    label: tr('completed_checklists'),
                    value: '${stats['completedChecklists'] ?? 0}',
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
                    label: tr('total_items'),
                    value: '${stats['totalItems'] ?? 0}',
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.done_all,
                    label: tr('completed_items'),
                    value: '${stats['completedItems'] ?? 0}',
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
  }) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blue),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileActions(NavigationNotifier navigationNotifier) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.edit, color: Colors.blue, size: 20),
            title: Text(
              tr('edit_profile'),
              style: const TextStyle(fontSize: 14),
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
              tr('detailed_statistics'),
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to statistics screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(
              Icons.emoji_events,
              color: Colors.orange,
              size: 20,
            ),
            title: Text(
              tr('achievements'),
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to user souvenir screen
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(
    User? currentUser,
    Map<String, dynamic> preferences,
  ) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr('account_information'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              tr('email'),
              currentUser?.email ?? tr('not_available'),
            ),
            _buildInfoRow(
              tr('user_id'),
              currentUser?.uid ?? tr('not_available'),
            ),
            _buildInfoRow(
              tr('email_verified'),
              currentUser?.emailVerified == true ? tr('yes') : tr('no'),
            ),
            _buildInfoRow(
              tr('account_created'),
              _formatTimestamp(_userData?['createdAt']),
            ),
            _buildInfoRow(
              tr('last_updated'),
              _formatTimestamp(_userData?['updatedAt']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFeatures(NavigationNotifier navigationNotifier) {
    return AppCard(
      child: Column(
        children: [
          ListTile(
            dense: true,
            leading: const Icon(Icons.settings, color: Colors.grey, size: 20),
            title: Text(
              tr('account_settings'),
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to account settings screen
            },
          ),
          const Divider(height: 1),
          ListTile(
            dense: true,
            leading: const Icon(Icons.security, color: Colors.grey, size: 20),
            title: Text(
              tr('privacy_security'),
              style: const TextStyle(fontSize: 14),
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
              tr('help_support'),
              style: const TextStyle(fontSize: 14),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => navigationNotifier.navigateToHelp(),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return tr('not_available');

    try {
      if (timestamp is Timestamp) {
        final date = timestamp.toDate();
        return '${date.day}/${date.month}/${date.year}';
      }
      return tr('not_available');
    } catch (e) {
      return tr('not_available');
    }
  }
}
