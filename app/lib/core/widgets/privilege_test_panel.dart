import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privilege_provider.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';
import '../../features/achievements/domain/achievement_providers.dart';

class PrivilegeTestPanel extends ConsumerWidget {
  const PrivilegeTestPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    return ExpansionTile(
      title: Row(
        children: [
          Icon(Icons.science, color: Colors.orange),
          const SizedBox(width: 8),
          Text(TranslationService.translate('test_privileges')),
        ],
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              _buildDevTools(context, ref, privileges),
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

    // For testing, we'll directly update the privilege state
    // In production, this would call the actual upgrade method
    privilegeNotifier.testSwitchTier(tier);

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

  Widget _buildDevTools(
    BuildContext context,
    WidgetRef ref,
    UserPrivileges? privileges,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
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
    // Clear all achievements by resetting their progress and unlocked status
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
