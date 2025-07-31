import 'package:flutter/material.dart';
import '../../core/services/import_service.dart';
import '../../core/services/translation_service.dart';
import '../../features/checklists/domain/checklist.dart';

class ImportPreview extends StatelessWidget {
  final ImportResult result;
  final VoidCallback onEdit;

  const ImportPreview({super.key, required this.result, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.preview, color: theme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                TranslationService.translate('preview'),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 16),
                label: Text(TranslationService.translate('edit')),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Summary
          _buildSummary(context),
          const SizedBox(height: 8),

          // Items preview
          if (result.items.isNotEmpty) ...[
            Text(
              TranslationService.translate('items'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 150),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: result.items.length,
                itemBuilder: (context, index) {
                  final item = result.items[index];
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.check_box_outline_blank,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    title: Text(
                      item.text,
                      style: theme.textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    contentPadding: EdgeInsets.zero,
                  );
                },
              ),
            ),
          ],

          // Errors
          if (result.errors.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildErrors(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context) {
    final theme = Theme.of(context);
    final hasErrors = result.errors.isNotEmpty;
    final hasPartialSuccess = result.hasPartialSuccess;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasErrors && !hasPartialSuccess
            ? Colors.red.withOpacity(0.1)
            : hasPartialSuccess
            ? Colors.orange.withOpacity(0.1)
            : Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasErrors && !hasPartialSuccess
              ? Colors.red.withOpacity(0.3)
              : hasPartialSuccess
              ? Colors.orange.withOpacity(0.3)
              : Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasErrors && !hasPartialSuccess
                    ? Icons.error
                    : hasPartialSuccess
                    ? Icons.warning
                    : Icons.check_circle,
                color: hasErrors && !hasPartialSuccess
                    ? Colors.red
                    : hasPartialSuccess
                    ? Colors.orange
                    : Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _getSummaryTitle(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: hasErrors && !hasPartialSuccess
                      ? Colors.red
                      : hasPartialSuccess
                      ? Colors.orange
                      : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(_getSummaryMessage(), style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildErrors(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                '${result.errors.length} ${TranslationService.translate('errors')}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...result.errors
              .take(3)
              .map(
                (error) => Padding(
                  padding: const EdgeInsets.only(left: 28),
                  child: Text(
                    '• $error',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.red.shade700,
                    ),
                  ),
                ),
              ),
          if (result.errors.length > 3)
            Padding(
              padding: const EdgeInsets.only(left: 28),
              child: Text(
                '... and ${result.errors.length - 3} more',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.red.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getSummaryTitle() {
    if (result.errors.isNotEmpty && !result.hasPartialSuccess) {
      return TranslationService.translate('import_failed');
    } else if (result.hasPartialSuccess) {
      return TranslationService.translate('partial_import_success');
    } else {
      return TranslationService.translate('import_successful');
    }
  }

  String _getSummaryMessage() {
    if (result.errors.isNotEmpty && !result.hasPartialSuccess) {
      return TranslationService.translate('import_failed_message');
    } else if (result.hasPartialSuccess) {
      return TranslationService.translate('partial_import_message')
          .replaceAll('{successful}', result.successfulItems.toString())
          .replaceAll('{failed}', result.failedItems.toString());
    } else {
      return TranslationService.translate(
        'import_successful_message',
      ).replaceAll('{count}', result.successfulItems.toString());
    }
  }
}
