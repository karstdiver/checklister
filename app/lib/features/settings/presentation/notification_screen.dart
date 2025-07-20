import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/translation_service.dart';
import '../../../core/widgets/feature_guard.dart';
import '../../../core/widgets/signup_encouragement.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/providers/notification_settings_provider.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  bool _isSaving = false;

  Future<void> _saveNotificationSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final notificationNotifier = ref.read(
        notificationSettingsProvider.notifier,
      );
      await notificationNotifier.saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('settings_saved')),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.translate('error_saving_settings'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    // Watch notification settings
    final notificationSettings = ref.watch(notificationSettingsProvider);
    final notificationNotifier = ref.read(
      notificationSettingsProvider.notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('notifications')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveNotificationSettings,
            child: _isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(TranslationService.translate('save')),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Basic Notifications (Free)
          _buildBasicNotificationsSection(
            notificationSettings,
            notificationNotifier,
          ),
          const SizedBox(height: 16),

          // Enhanced Notifications (Guarded)
          _buildEnhancedNotificationsSection(
            notificationSettings,
            notificationNotifier,
          ),
          const SizedBox(height: 16),

          // Premium Notifications (Guarded)
          _buildPremiumNotificationsSection(
            notificationSettings,
            notificationNotifier,
          ),
          const SizedBox(height: 16),

          // Pro Notifications (Guarded)
          _buildProNotificationsSection(
            notificationSettings,
            notificationNotifier,
          ),
        ],
      ),
    );
  }

  Widget _buildBasicNotificationsSection(
    NotificationSettings notificationSettings,
    NotificationSettingsNotifier notificationNotifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('basic_notifications'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        TranslationService.translate(
                          'basic_notifications_description',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: Text(TranslationService.translate('enable_notifications')),
            subtitle: Text(
              TranslationService.translate('enable_notifications_description'),
            ),
            value: notificationSettings.basicNotificationsEnabled,
            onChanged: (value) {
              notificationNotifier.updateBasicNotifications(value);
            },
          ),
          SwitchListTile(
            title: Text(TranslationService.translate('reminder_notifications')),
            subtitle: Text(
              TranslationService.translate(
                'reminder_notifications_description',
              ),
            ),
            value: notificationSettings.reminderNotificationsEnabled,
            onChanged: (value) {
              notificationNotifier.updateReminderNotifications(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedNotificationsSection(
    NotificationSettings notificationSettings,
    NotificationSettingsNotifier notificationNotifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('enhanced_notifications'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        TranslationService.translate(
                          'enhanced_notifications_description',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Progress Notifications (Free tier)
          SwitchListTile(
            title: Text(TranslationService.translate('progress_notifications')),
            subtitle: Text(
              TranslationService.translate(
                'progress_notifications_description',
              ),
            ),
            value: notificationSettings.progressNotificationsEnabled,
            onChanged: (value) {
              notificationNotifier.updateProgressNotifications(value);
            },
          ),
          // Achievement Notifications (Free tier)
          SwitchListTile(
            title: Text(
              TranslationService.translate('achievement_notifications'),
            ),
            subtitle: Text(
              TranslationService.translate(
                'achievement_notifications_description',
              ),
            ),
            value: notificationSettings.achievementNotificationsEnabled,
            onChanged: (value) {
              notificationNotifier.updateAchievementNotifications(value);
            },
          ),
          // Weekly Reports (Premium tier) - Guarded
          FeatureGuard(
            feature: 'weeklyReports',
            child: SwitchListTile(
              title: Text(TranslationService.translate('weekly_reports')),
              subtitle: Text(
                TranslationService.translate('weekly_reports_description'),
              ),
              value: notificationSettings.weeklyReportsEnabled,
              onChanged: (value) {
                notificationNotifier.updateWeeklyReports(value);
              },
            ),
            fallback: _buildCuriousUserEncouragement(
              TranslationService.translate('weekly_reports'),
              TranslationService.translate(
                'weekly_reports_curious_description',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumNotificationsSection(
    NotificationSettings notificationSettings,
    NotificationSettingsNotifier notificationNotifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('premium_notifications'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        TranslationService.translate(
                          'premium_notifications_description',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Custom Reminders (Premium tier) - Guarded
          FeatureGuard(
            feature: 'customReminders',
            child: SwitchListTile(
              title: Text(TranslationService.translate('custom_reminders')),
              subtitle: Text(
                TranslationService.translate('custom_reminders_description'),
              ),
              value: notificationSettings.customRemindersEnabled,
              onChanged: (value) {
                notificationNotifier.updateCustomReminders(value);
              },
            ),
            fallback: _buildCuriousUserEncouragement(
              TranslationService.translate('custom_reminders'),
              TranslationService.translate(
                'custom_reminders_curious_description',
              ),
            ),
          ),
          // Smart Suggestions (Premium tier) - Guarded
          FeatureGuard(
            feature: 'smartSuggestions',
            child: SwitchListTile(
              title: Text(TranslationService.translate('smart_suggestions')),
              subtitle: Text(
                TranslationService.translate('smart_suggestions_description'),
              ),
              value: notificationSettings.smartSuggestionsEnabled,
              onChanged: (value) {
                notificationNotifier.updateSmartSuggestions(value);
              },
            ),
            fallback: _buildCuriousUserEncouragement(
              TranslationService.translate('smart_suggestions'),
              TranslationService.translate(
                'smart_suggestions_curious_description',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProNotificationsSection(
    NotificationSettings notificationSettings,
    NotificationSettingsNotifier notificationNotifier,
  ) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.workspace_premium, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        TranslationService.translate('pro_notifications'),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        TranslationService.translate(
                          'pro_notifications_description',
                        ),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Team Notifications (Pro tier) - Guarded
          FeatureGuard(
            feature: 'teamNotifications',
            child: SwitchListTile(
              title: Text(TranslationService.translate('team_notifications')),
              subtitle: Text(
                TranslationService.translate('team_notifications_description'),
              ),
              value: notificationSettings.teamNotificationsEnabled,
              onChanged: (value) {
                notificationNotifier.updateTeamNotifications(value);
              },
            ),
            fallback: _buildCuriousUserEncouragement(
              TranslationService.translate('team_notifications'),
              TranslationService.translate(
                'team_notifications_curious_description',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCuriousUserEncouragement(
    String featureName,
    String description,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                featureName,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          SignupEncouragement(
            title: TranslationService.translate('unlock_notification_features'),
            message: TranslationService.translate('upgrade_for_notifications'),
            featureName: featureName,
            onDismiss: () {
              // User dismissed the encouragement
            },
          ),
        ],
      ),
    );
  }
}
