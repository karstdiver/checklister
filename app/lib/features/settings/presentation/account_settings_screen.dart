import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

class AccountSettingsScreen extends ConsumerStatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  ConsumerState<AccountSettingsScreen> createState() =>
      _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends ConsumerState<AccountSettingsScreen> {
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
    ref.watch(translationProvider);
    final currentUser = ref.watch(currentUserProvider);
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;
    final isMaxTier = currentTier == UserTier.pro;
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('account_settings')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorWidget()
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
                // Test Privilege Panel (DEV ONLY)
                const PrivilegeTestPanel(),
                const Divider(height: 32, thickness: 2),
                Text(
                  'DEV ONLY',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: Colors.red),
                ),
                const SizedBox(height: 8),
                AcceptanceStatusSwitch(),
              ],
            ),
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

  Widget _buildAccountInfo(User? currentUser) {
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

class AcceptanceStatusSwitch extends StatefulWidget {
  const AcceptanceStatusSwitch({super.key});
  @override
  State<AcceptanceStatusSwitch> createState() => _AcceptanceStatusSwitchState();
}

class _AcceptanceStatusSwitchState extends State<AcceptanceStatusSwitch> {
  bool _accepted = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await AcceptanceService.loadAcceptance();
    setState(() {
      _accepted =
          status.privacyAccepted &&
          status.tosAccepted &&
          status.acceptedVersion >= AcceptanceService.currentPolicyVersion;
      _loading = false;
    });
  }

  Future<void> _setAcceptance(bool value) async {
    setState(() => _loading = true);
    if (value) {
      await AcceptanceService.saveAcceptance(
        privacyAccepted: true,
        tosAccepted: true,
      );
      await AcceptanceService.saveAcceptanceRemote(
        privacyAccepted: true,
        tosAccepted: true,
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacyAccepted');
      await prefs.remove('tosAccepted');
      await prefs.remove('acceptedVersion');
      await prefs.remove('acceptedAt');
      // Remove from Firestore as well
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'policyAcceptance': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
    }
    await _loadStatus();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Acceptance set (DEV ONLY)'
                : 'Acceptance cleared (DEV ONLY)',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Row(
      children: [
        Switch(value: _accepted, onChanged: (v) => _setAcceptance(v)),
        const SizedBox(width: 12),
        Text(
          _accepted ? 'Acceptance: ON' : 'Acceptance: OFF',
          style: TextStyle(
            color: _accepted ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
