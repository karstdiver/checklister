import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/privilege_provider.dart';
import '../../../core/domain/user_tier.dart';
import '../../../core/services/translation_service.dart';
import '../../achievements/domain/achievement_providers.dart';
import '../../../core/services/acceptance_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DevOnlyPanel extends ConsumerStatefulWidget {
  const DevOnlyPanel({super.key});

  @override
  ConsumerState<DevOnlyPanel> createState() => _DevOnlyPanelState();
}

class _DevOnlyPanelState extends ConsumerState<DevOnlyPanel> {
  bool _acceptanceLoading = true;
  bool _accepted = false;

  @override
  void initState() {
    super.initState();
    _loadAcceptanceStatus();
  }

  Future<void> _loadAcceptanceStatus() async {
    final status = await AcceptanceService.loadAcceptance();
    setState(() {
      _accepted =
          status.privacyAccepted &&
          status.tosAccepted &&
          status.acceptedVersion >= AcceptanceService.currentPolicyVersion;
      _acceptanceLoading = false;
    });
  }

  Future<void> _setAcceptance(bool value) async {
    setState(() => _acceptanceLoading = true);
    if (value) {
      await AcceptanceService.saveAcceptance(
        privacyAccepted: true,
        tosAccepted: true,
      );

      // Only save to remote if user is not anonymous
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await AcceptanceService.saveAcceptanceRemote(
          privacyAccepted: true,
          tosAccepted: true,
        );
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('privacyAccepted');
      await prefs.remove('tosAccepted');
      await prefs.remove('acceptedVersion');
      await prefs.remove('acceptedAt');
      // Remove from Firestore as well (only for non-anonymous users)
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.isAnonymous) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'policyAcceptance': FieldValue.delete(),
        }, SetOptions(merge: true));
      }
    }
    await _loadAcceptanceStatus();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? TranslationService.translate('acceptance_set')
                : TranslationService.translate('acceptance_cleared'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(translationProvider);
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return ExpansionTile(
      title: Row(
        children: [
          const Icon(Icons.science, color: Colors.orange),
          const SizedBox(width: 8),
          Text(
            TranslationService.translate('development_only'),
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Privilege selection
              Text(
                TranslationService.translate('current_tier', [
                  _getTierName(currentTier),
                ]),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 16),
              Text(
                TranslationService.translate('switch_privilege_levels'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: UserTier.values.map((tier) {
                  final isSelected = currentTier == tier;
                  return FilterChip(
                    label: Text(_getTierName(tier)),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _switchToTier(context, ref, tier);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue[100],
                    checkmarkColor: Colors.blue,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              Text(
                TranslationService.translate('current_privileges'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              _buildPrivilegeList(privileges),
              const SizedBox(height: 16),
              // Achievement reset
              Text(
                TranslationService.translate('dev_tools'),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => _clearAchievements(context, ref),
                icon: const Icon(Icons.clear_all, size: 16),
                label: Text(TranslationService.translate('clear_achievements')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[100],
                  foregroundColor: Colors.red[800],
                ),
              ),
              const SizedBox(height: 24),
              // Acceptance status reset
              Text(
                TranslationService.translate('acceptance_status'),
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 8),
              _acceptanceLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        Switch(
                          value: _accepted,
                          onChanged: (v) => _setAcceptance(v),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _accepted
                              ? TranslationService.translate('acceptance_on')
                              : TranslationService.translate('acceptance_off'),
                          style: TextStyle(
                            color: _accepted ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ],
    );
  }

  String _getTierName(UserTier tier) {
    switch (tier) {
      case UserTier.anonymous:
        return TranslationService.translate('anonymous');
      case UserTier.free:
        return TranslationService.translate('free');
      case UserTier.premium:
        return TranslationService.translate('premium');
      case UserTier.pro:
        return TranslationService.translate('pro');
    }
  }

  Widget _buildPrivilegeList(UserPrivileges? privileges) {
    if (privileges == null) {
      return Text(TranslationService.translate('no_privileges_loaded'));
    }
    final features = privileges.features;
    final enabledFeatures = features.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...enabledFeatures.map(
          (feature) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(feature)),
              ],
            ),
          ),
        ),
        if (enabledFeatures.isEmpty)
          Text(
            TranslationService.translate('no_features_enabled'),
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  void _switchToTier(BuildContext context, WidgetRef ref, UserTier tier) {
    final privilegeNotifier = ref.read(privilegeProvider.notifier);
    privilegeNotifier.upgradeTier(tier);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          TranslationService.translate('switched_to_tier', [
            _getTierName(tier),
          ]),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAchievements(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('clear_achievements')),
        content: Text(
          TranslationService.translate('clear_achievements_confirm'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(TranslationService.translate('cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _performClearAchievements(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(TranslationService.translate('clear')),
          ),
        ],
      ),
    );
  }

  void _performClearAchievements(BuildContext context, WidgetRef ref) {
    final achievementNotifier = ref.read(achievementNotifierProvider.notifier);
    try {
      achievementNotifier.clearAllAchievements();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(TranslationService.translate('achievements_cleared')),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error clearing achievements: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
