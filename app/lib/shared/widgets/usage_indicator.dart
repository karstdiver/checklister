import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/domain/user_tier.dart';
import '../../core/providers/privilege_provider.dart';
import '../../core/services/translation_service.dart';

class UsageIndicator extends ConsumerWidget {
  final int currentChecklistCount;
  final int currentItemCount;
  final bool showItemLimit;

  const UsageIndicator({
    super.key,
    required this.currentChecklistCount,
    this.currentItemCount = 0,
    this.showItemLimit = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final privileges = ref.watch(privilegeProvider);

    if (privileges == null) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              TranslationService.translate('usage_limits'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildLimitBar(
                    context,
                    TranslationService.translate('checklists_used'),
                    currentChecklistCount,
                    privileges.maxChecklists,
                    theme,
                  ),
                ),
                if (showItemLimit) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildLimitBar(
                      context,
                      TranslationService.translate('items_per_list'),
                      currentItemCount,
                      privileges.maxItemsPerChecklist,
                      theme,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitBar(
    BuildContext context,
    String label,
    int current,
    int limit,
    ThemeData theme,
  ) {
    final isUnlimited = limit == -1;
    final percentage = isUnlimited ? 0.0 : (current / limit).clamp(0.0, 1.0);
    final isNearLimit = percentage > 0.8;
    final isAtLimit = percentage >= 1.0;

    Color progressColor;
    if (isAtLimit) {
      progressColor = theme.colorScheme.error;
    } else if (isNearLimit) {
      progressColor = theme.colorScheme.tertiary;
    } else {
      progressColor = theme.colorScheme.primary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                isUnlimited
                    ? '$current ∞'
                    : '$current ${TranslationService.translate('of_limit')} $limit',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isAtLimit
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        if (!isUnlimited) ...[
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: theme.colorScheme.surfaceVariant,
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ] else ...[
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: current,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isAtLimit) ...[
          const SizedBox(height: 4),
          Text(
            TranslationService.translate('limit_reached'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

class CompactUsageIndicator extends ConsumerWidget {
  final int currentChecklistCount;
  final int currentItemCount;
  final bool showItemLimit;

  const CompactUsageIndicator({
    super.key,
    required this.currentChecklistCount,
    this.currentItemCount = 0,
    this.showItemLimit = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final privileges = ref.watch(privilegeProvider);

    if (privileges == null) {
      return const SizedBox.shrink();
    }

    final checklistPercentage = privileges.maxChecklists == -1
        ? 0.0
        : (currentChecklistCount / privileges.maxChecklists).clamp(0.0, 1.0);

    final itemPercentage = privileges.maxItemsPerChecklist == -1
        ? 0.0
        : (currentItemCount / privileges.maxItemsPerChecklist).clamp(0.0, 1.0);

    final isNearLimit = checklistPercentage > 0.8 || itemPercentage > 0.8;
    final isAtLimit = checklistPercentage >= 1.0 || itemPercentage >= 1.0;

    if (!isNearLimit && !isAtLimit) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isAtLimit
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAtLimit ? Icons.warning : Icons.info_outline,
            size: 16,
            color: isAtLimit
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onTertiaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            isAtLimit
                ? TranslationService.translate('limit_reached')
                : TranslationService.translate('usage_limits'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: isAtLimit
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
