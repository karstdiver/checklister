import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../core/services/translation_service.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/tier_indicator.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/services/admin_management_service.dart';

import 'upgrade_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/acceptance_service.dart';

import '../../auth/domain/profile_provider.dart';
import 'ttl_management_screen.dart';
import 'limit_management_screen.dart';

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      final connectivity = await Connectivity().checkConnectivity();
      ref
          .read(profileNotifierProvider.notifier)
          .loadProfile(currentUser.uid, connectivity: connectivity);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(translationProvider);
    final currentUser = ref.watch(currentUserProvider);
    final profileState = ref.watch(profileStateProvider);
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;
    final isMaxTier = currentTier == UserTier.pro;

    // Load profile if not already loaded and not loading
    if (profileState.isInitial && currentUser != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfile();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('account_settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.hasError
          ? _buildErrorWidget(profileState.errorMessage ?? 'Unknown error')
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Privilege Card
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        TierIndicator(
                          tier: currentTier,
                          fontSize: 16,
                          iconSize: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            TranslationService.translate('current_tier', [
                              TierIndicator.getTierDisplayName(currentTier),
                            ]),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (!isMaxTier)
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const UpgradeScreen(),
                                ),
                              );
                            },
                            child: Text(
                              TranslationService.translate('upgrade'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAccountInfo(currentUser),
                const SizedBox(height: 16),
                // Admin Panel Section
                if (privileges?.canAccessAdminPanel == true) ...[
                  _buildAdminPanel(privileges!),
                  const SizedBox(height: 16),
                ],
              ],
            ),
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
            onPressed: _loadProfile,
            child: Text(TranslationService.translate('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountInfo(User? currentUser) {
    final textColor = Theme.of(context).colorScheme.onSurface;
    final profile = ref.watch(profileDataProvider);

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

  String _formatTimestamp(DateTime? dateTime) {
    if (dateTime == null) return TranslationService.translate('not_available');
    try {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return TranslationService.translate('not_available');
    }
  }

  Widget _buildAdminPanel(UserPrivileges privileges) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Panel Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('admin_panel'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      Text(
                        'Role: ${privileges.adminRole.name.toUpperCase()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Admin Features
          _buildAdminFeatureTile(
            icon: Icons.analytics,
            title: TranslationService.translate('system_analytics'),
            subtitle: TranslationService.translate('view_system_statistics'),
            color: Colors.blue,
            onTap: () => _showAnalyticsDialog(),
            enabled: privileges.canViewAnalytics,
          ),

          if (privileges.canManageTTL) ...[
            const Divider(height: 1),
            _buildAdminFeatureTile(
              icon: Icons.timer,
              title: TranslationService.translate('ttl_management'),
              subtitle: TranslationService.translate('manage_data_retention'),
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TTLManagementScreen(),
                ),
              ),
              enabled: true,
            ),
          ],

          if (privileges.canManageSystem) ...[
            const Divider(height: 1),
            _buildAdminFeatureTile(
              icon: Icons.settings_applications,
              title: TranslationService.translate('limit_management'),
              subtitle: TranslationService.translate('configure_limits'),
              color: Colors.indigo,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LimitManagementScreen(),
                ),
              ),
              enabled: true,
            ),
          ],

          if (privileges.canManageUsers) ...[
            const Divider(height: 1),
            _buildAdminFeatureTile(
              icon: Icons.people,
              title: TranslationService.translate('user_management'),
              subtitle: TranslationService.translate('manage_user_accounts'),
              color: Colors.green,
              onTap: () => _showUserManagementDialog(),
              enabled: true,
            ),
          ],

          if (privileges.canManageSystem) ...[
            const Divider(height: 1),
            _buildAdminFeatureTile(
              icon: Icons.settings_system_daydream,
              title: TranslationService.translate('system_settings'),
              subtitle: TranslationService.translate(
                'configure_system_settings',
              ),
              color: Colors.purple,
              onTap: () => _showSystemSettingsDialog(),
              enabled: true,
            ),
          ],

          if (privileges.canCleanupAllData) ...[
            const Divider(height: 1),
            _buildAdminFeatureTile(
              icon: Icons.cleaning_services,
              title: TranslationService.translate('data_cleanup'),
              subtitle: TranslationService.translate('cleanup_expired_data'),
              color: Colors.red,
              onTap: () => _showDataCleanupDialog(),
              enabled: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdminFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: enabled ? color : textColor.withValues(alpha: 0.3),
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: enabled ? textColor : textColor.withValues(alpha: 0.5),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: enabled
              ? textColor.withValues(alpha: 0.7)
              : textColor.withValues(alpha: 0.3),
        ),
      ),
      trailing: enabled
          ? const Icon(Icons.arrow_forward_ios, size: 16)
          : Icon(Icons.lock, size: 16, color: textColor.withValues(alpha: 0.3)),
      onTap: enabled ? onTap : null,
    );
  }

  void _showAnalyticsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('system_analytics')),
        content: Text(
          TranslationService.translate('system_analytics_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('ok')),
          ),
        ],
      ),
    );
  }

  void _showUserManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('user_management')),
        content: Text(
          TranslationService.translate('user_management_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('ok')),
          ),
        ],
      ),
    );
  }

  void _showSystemSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('system_settings')),
        content: Text(
          TranslationService.translate('system_settings_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('ok')),
          ),
        ],
      ),
    );
  }

  void _showDataCleanupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('data_cleanup')),
        content: Text(TranslationService.translate('data_cleanup_coming_soon')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('ok')),
          ),
        ],
      ),
    );
  }
}

// DEPRECATED: AcceptanceStatusSwitch is now merged into DevOnlyPanel.
// This widget is no longer used.
