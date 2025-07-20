import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privilege_provider.dart';
import '../domain/user_tier.dart';
import '../services/translation_service.dart';

class FeatureGuard extends ConsumerWidget {
  final Widget child;
  final String feature;
  final Widget? fallback;
  final UserTier? minimumTier;

  const FeatureGuard({
    super.key,
    required this.child,
    required this.feature,
    this.fallback,
    this.minimumTier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);

    // Check if user has the required feature
    final hasFeature = privileges?.hasFeature(feature) ?? false;

    // Check if user meets minimum tier requirement
    final meetsTierRequirement =
        minimumTier == null ||
        (privileges?.tier.index ?? 0) >= minimumTier!.index;

    if (hasFeature && meetsTierRequirement) {
      return child;
    }

    return fallback ?? _buildUpgradePrompt(context, ref, privileges);
  }

  Widget _buildUpgradePrompt(BuildContext context, WidgetRef ref, privileges) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 16),
          Text(
            'Premium Feature',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature requires a premium subscription.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _showUpgradeDialog(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upgrade to Premium'),
        content: const Text(
          'Unlock all features and remove limits with a premium subscription.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement upgrade flow
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    TranslationService.translate('upgrade_flow_coming_soon'),
                  ),
                ),
              );
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }
}

// Convenience widgets for common privilege checks
class TierGuard extends ConsumerWidget {
  final Widget child;
  final UserTier minimumTier;
  final Widget? fallback;

  const TierGuard({
    super.key,
    required this.child,
    required this.minimumTier,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privileges = ref.watch(privilegeProvider);
    final currentTier = privileges?.tier ?? UserTier.anonymous;

    if (currentTier.index >= minimumTier.index) {
      return child;
    }

    return fallback ??
        FeatureGuard(feature: 'any', child: child).build(context, ref);
  }
}

// Specific feature guards
class SessionPersistenceGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SessionPersistenceGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'sessionPersistence',
      child: child,
      fallback: fallback,
    );
  }
}

class AnalyticsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AnalyticsGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(feature: 'analytics', child: child, fallback: fallback);
  }
}

class ExportGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ExportGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(feature: 'export', child: child, fallback: fallback);
  }
}

// Enhanced feature guards
class EditChecklistGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const EditChecklistGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'canEditChecklists',
      child: child,
      fallback: fallback,
    );
  }
}

class DeleteChecklistGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const DeleteChecklistGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'canDeleteChecklists',
      child: child,
      fallback: fallback,
    );
  }
}

class DuplicateChecklistGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const DuplicateChecklistGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'canDuplicateChecklists',
      child: child,
      fallback: fallback,
    );
  }
}

class SessionHistoryGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SessionHistoryGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'sessionHistory',
      child: child,
      fallback: fallback,
    );
  }
}

class ChecklistTemplatesGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ChecklistTemplatesGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'checklistTemplates',
      child: child,
      fallback: fallback,
    );
  }
}

class ProfileCustomizationGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ProfileCustomizationGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'profileCustomization',
      child: child,
      fallback: fallback,
    );
  }
}

class ProfilePicturesGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const ProfilePicturesGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'profilePictures',
      child: child,
      fallback: fallback,
    );
  }
}

// Achievement feature guards
class AchievementsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AchievementsGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'achievements',
      child: child,
      fallback: fallback,
    );
  }
}

class AchievementSharingGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AchievementSharingGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'achievementSharing',
      child: child,
      fallback: fallback,
    );
  }
}

class AchievementLeaderboardsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const AchievementLeaderboardsGuard({
    super.key,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'achievementLeaderboards',
      child: child,
      fallback: fallback,
    );
  }
}

// Notification feature guards
class WeeklyReportsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const WeeklyReportsGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'weeklyReports',
      child: child,
      fallback: fallback,
    );
  }
}

class CustomRemindersGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const CustomRemindersGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'customReminders',
      child: child,
      fallback: fallback,
    );
  }
}

class SmartSuggestionsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const SmartSuggestionsGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'smartSuggestions',
      child: child,
      fallback: fallback,
    );
  }
}

class TeamNotificationsGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const TeamNotificationsGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'teamNotifications',
      child: child,
      fallback: fallback,
    );
  }
}

class DataBackupGuard extends ConsumerWidget {
  final Widget child;
  final Widget? fallback;

  const DataBackupGuard({super.key, required this.child, this.fallback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FeatureGuard(
      feature: 'dataBackup',
      child: child,
      fallback: fallback,
    );
  }
}
