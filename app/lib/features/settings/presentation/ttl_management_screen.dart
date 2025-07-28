import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/core/constants/ttl_config.dart';
import 'package:checklister/core/domain/user_tier.dart';
import 'package:checklister/core/providers/privilege_provider.dart';
import 'package:checklister/features/sessions/domain/session_notifier.dart';
import 'package:checklister/features/sessions/domain/session_providers.dart';
import 'package:checklister/core/services/translation_service.dart';
import 'package:checklister/core/services/ttl_cleanup_service.dart';
import 'package:checklister/shared/widgets/app_card.dart';
import 'package:logger/logger.dart';

class TTLManagementScreen extends ConsumerStatefulWidget {
  const TTLManagementScreen({super.key});

  @override
  ConsumerState<TTLManagementScreen> createState() =>
      _TTLManagementScreenState();
}

class _TTLManagementScreenState extends ConsumerState<TTLManagementScreen> {
  final Logger _logger = Logger();
  bool _isLoading = false;
  Map<String, int>? _cleanupResults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userPrivileges = ref.watch(privilegeProvider);
    final userTier = userPrivileges?.tier ?? UserTier.anonymous;

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('ttl_management')),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserTierInfo(userTier, theme),
            const SizedBox(height: 24),
            _buildTTLConfiguration(theme),
            const SizedBox(height: 24),
            _buildCleanupSection(theme),
            if (_cleanupResults != null) ...[
              const SizedBox(height: 24),
              _buildCleanupResults(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserTierInfo(UserTier userTier, ThemeData theme) {
    final ttlDays = TTLConfig.getTTLDaysForTier(userTier);
    final hasUnlimited = TTLConfig.hasUnlimitedTTL(userTier);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('current_user_tier'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  userTier.name.toUpperCase(),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                hasUnlimited
                    ? TranslationService.translate('unlimited_ttl')
                    : '${ttlDays} ${TranslationService.translate('days')}',
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTTLConfiguration(ThemeData theme) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('ttl_configuration'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...UserTier.values.map((tier) {
            final ttlDays = TTLConfig.getTTLDaysForTier(tier);
            final hasUnlimited = TTLConfig.hasUnlimitedTTL(tier);
            final warningThreshold = TTLConfig.getWarningThreshold(tier);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      tier.name.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasUnlimited
                              ? TranslationService.translate('unlimited_ttl')
                              : '${ttlDays} ${TranslationService.translate('days')}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        if (!hasUnlimited)
                          Text(
                            '${TranslationService.translate('warning_threshold')}: ${warningThreshold} ${TranslationService.translate('days')}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildCleanupSection(ThemeData theme) {
    final userPrivileges = ref.watch(privilegeProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('ttl_cleanup'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            TranslationService.translate('ttl_cleanup_description'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _cleanupCurrentTier,
                  icon: const Icon(Icons.cleaning_services),
                  label: Text(
                    TranslationService.translate('cleanup_current_tier'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // SECURITY: Only show admin buttons to actual admins
              if (userPrivileges?.canManageTTL == true ||
                  const bool.fromEnvironment('dart.vm.product') == false)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _cleanupAllTiers,
                    icon: const Icon(Icons.cleaning_services_outlined),
                    label: Text(
                      TranslationService.translate('cleanup_all_tiers'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.secondary,
                      foregroundColor: theme.colorScheme.onSecondary,
                    ),
                  ),
                ),
            ],
          ),
          // SECURITY: Only show admin buttons to actual admins
          if (userPrivileges?.canManageTTL == true ||
              const bool.fromEnvironment('dart.vm.product') == false) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cleanupOrphanedDocuments,
                icon: const Icon(Icons.delete_sweep),
                label: Text(
                  TranslationService.translate('cleanup_orphaned_documents'),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.errorContainer,
                  foregroundColor: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildCleanupResults(ThemeData theme) {
    if (_cleanupResults == null) return const SizedBox.shrink();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            TranslationService.translate('cleanup_results'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._cleanupResults!.entries.map((entry) {
            final tier = entry.key.replaceAll('_sessions', '');
            final count = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tier.toUpperCase()} ${TranslationService.translate('sessions')}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      count.toString(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: count > 0
                            ? theme.colorScheme.onErrorContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _cleanupCurrentTier() async {
    final userPrivileges = ref.read(privilegeProvider);
    final userTier = userPrivileges?.tier ?? UserTier.anonymous;
    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    setState(() {
      _isLoading = true;
      _cleanupResults = null;
    });

    try {
      final count = await sessionNotifier.cleanupExpiredSessions(userTier);
      setState(() {
        _cleanupResults = {'${userTier.name}_sessions': count};
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${TranslationService.translate('cleanup_completed')}: $count ${TranslationService.translate('sessions_deleted')}',
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during cleanup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('cleanup_error')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupAllTiers() async {
    // SECURITY: Only allow admin users or in debug mode
    final userPrivileges = ref.read(privilegeProvider);

    // Check if user has admin privileges
    final hasAdminAccess =
        userPrivileges?.canManageTTL == true ||
        const bool.fromEnvironment('dart.vm.product') == false;

    if (!hasAdminAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.translate('insufficient_privileges'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog for admin operations
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('admin_cleanup_confirmation')),
        content: Text(TranslationService.translate('admin_cleanup_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(TranslationService.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(TranslationService.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final sessionNotifier = ref.read(sessionNotifierProvider.notifier);

    setState(() {
      _isLoading = true;
      _cleanupResults = null;
    });

    try {
      final results = await sessionNotifier.cleanupAllExpiredSessions();
      setState(() {
        _cleanupResults = results;
      });

      final totalDeleted = results.values.fold(0, (sum, count) => sum + count);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${TranslationService.translate('admin_cleanup_completed')}: $totalDeleted ${TranslationService.translate('sessions_deleted')}',
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during admin cleanup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('cleanup_error')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cleanupOrphanedDocuments() async {
    // SECURITY: Only allow admin users or in debug mode
    final userPrivileges = ref.read(privilegeProvider);

    // Check if user has admin privileges
    final hasAdminAccess =
        userPrivileges?.canManageTTL == true ||
        const bool.fromEnvironment('dart.vm.product') == false;

    if (!hasAdminAccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              TranslationService.translate('insufficient_privileges'),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog for admin operations
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          TranslationService.translate('orphaned_cleanup_confirmation'),
        ),
        content: Text(TranslationService.translate('orphaned_cleanup_warning')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(TranslationService.translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(TranslationService.translate('confirm')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _cleanupResults = null;
    });

    try {
      final results = await TTLCleanupService.cleanupOrphanedDocuments();
      setState(() {
        _cleanupResults = results;
      });

      final totalDeleted = results.values.fold(0, (sum, count) => sum + count);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${TranslationService.translate('orphaned_cleanup_completed')}: $totalDeleted ${TranslationService.translate('orphaned_documents_deleted')}',
            ),
          ),
        );
      }
    } catch (e) {
      _logger.e('Error during orphaned document cleanup: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(TranslationService.translate('cleanup_error')),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
