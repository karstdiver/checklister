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
import '../../../core/widgets/privilege_test_panel.dart';
import 'upgrade_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/acceptance_service.dart';
import 'dev_only_panel.dart';
import '../../auth/domain/profile_provider.dart';

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
                // DEV ONLY Panel (consolidated)
                const DevOnlyPanel(),
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
}

// DEPRECATED: AcceptanceStatusSwitch is now merged into DevOnlyPanel.
// This widget is no longer used.
