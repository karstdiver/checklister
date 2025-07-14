import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../domain/checklist.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../sessions/domain/session_providers.dart';

class ChecklistCard extends ConsumerWidget {
  final Checklist checklist;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onShare;

  const ChecklistCard({
    super.key,
    required this.checklist,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          checklist.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (checklist.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            checklist.description!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onEdit != null ||
                      onDelete != null ||
                      onDuplicate != null ||
                      onShare != null)
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.more_vert,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            onEdit?.call();
                            break;
                          case 'duplicate':
                            onDuplicate?.call();
                            break;
                          case 'share':
                            onShare?.call();
                            break;
                          case 'delete':
                            onDelete?.call();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        if (onEdit != null)
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                const Icon(Icons.edit, size: 20),
                                const SizedBox(width: 8),
                                Text(tr('edit')),
                              ],
                            ),
                          ),
                        if (onDuplicate != null)
                          PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                const Icon(Icons.copy, size: 20),
                                const SizedBox(width: 8),
                                Text(tr('duplicate')),
                              ],
                            ),
                          ),
                        if (onShare != null)
                          PopupMenuItem(
                            value: 'share',
                            child: Row(
                              children: [
                                const Icon(Icons.share, size: 20),
                                const SizedBox(width: 8),
                                Text(tr('share')),
                              ],
                            ),
                          ),
                        if (onDelete != null) ...[
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.delete,
                                  size: 20,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  tr('delete'),
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress indicator
              if (checklist.totalItems > 0) ...[
                Consumer(
                  builder: (context, ref, child) {
                    final sessionProgress = ref.watch(
                      activeSessionProgressProvider(checklist.id),
                    );

                    return sessionProgress.when(
                      data: (progress) {
                        // Use session progress if available, otherwise use checklist progress
                        final completed =
                            progress?.completed ?? checklist.completedItems;
                        final total = progress?.total ?? checklist.totalItems;
                        final hasActiveSession =
                            progress?.hasActiveSession ?? false;
                        final progressValue = total > 0
                            ? completed / total
                            : 0.0;

                        return Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: progressValue,
                                backgroundColor: colorScheme.surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  hasActiveSession
                                      ? Colors.blue
                                      : (checklist.isComplete
                                            ? Colors.green
                                            : colorScheme.primary),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '$completed/$total',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: hasActiveSession
                                    ? Colors.blue
                                    : colorScheme.onSurface.withOpacity(0.7),
                                fontWeight: hasActiveSession
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: checklist.completionPercentage,
                              backgroundColor: colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                checklist.isComplete
                                    ? Colors.green
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${checklist.completedItems}/${checklist.totalItems}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                      error: (error, stack) => Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: checklist.completionPercentage,
                              backgroundColor: colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                checklist.isComplete
                                    ? Colors.green
                                    : colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${checklist.completedItems}/${checklist.totalItems}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
              ],

              // Stats row
              Row(
                children: [
                  // Items count
                  Icon(
                    Icons.checklist,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${checklist.totalItems} ${tr('items')}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Tags
                  if (checklist.tags.isNotEmpty) ...[
                    Icon(
                      Icons.label,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      checklist.tags.take(2).join(', '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (checklist.tags.length > 2)
                      Text(
                        ' +${checklist.tags.length - 2}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ],
              ),

              // Last used info
              if (checklist.lastUsedAt != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${tr('last_used')}: ${_formatDate(checklist.lastUsedAt!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],

              // Public indicator
              if (checklist.isPublic) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.public, size: 12, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text(
                        tr('public'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return tr('today');
    } else if (difference.inDays == 1) {
      return tr('yesterday');
    } else if (difference.inDays < 7) {
      return '${difference.inDays} ${tr('days_ago')}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${tr('weeks_ago')}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
