import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';

class ChecklistScreen extends ConsumerWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);
    final analytics = AnalyticsService();
    final navigationState = ref.watch(navigationStateProvider);
    final navigationNotifier = ref.read(navigationNotifierProvider.notifier);

    // Get checklist ID from route params
    final checklistId =
        navigationState.routeParams?['checklistId'] as String? ?? 'demo';

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('checklist')),
        leading: IconButton(
          onPressed: () => navigationNotifier.goBack(),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Show checklist options menu
            },
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: 0.3, // TODO: Calculate from actual progress
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 16),

            // Progress text
            Text(
              TranslationService.translate('progress', [
                '3',
                '10',
              ]), // TODO: Use actual values
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),

            // Current item display
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Item image placeholder
                    Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Item title
                    Text(
                      TranslationService.translate('sample_item_title'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Item description
                    Text(
                      TranslationService.translate('sample_item_description'),
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Skip button
                        ElevatedButton.icon(
                          onPressed: () async {
                            // TODO: Mark as skipped
                            await analytics.logCustomEvent(
                              name: 'item_skipped',
                              parameters: {
                                'checklist_id': checklistId,
                                'item_id': 'current_item_id',
                              },
                            );
                          },
                          icon: const Icon(Icons.skip_next),
                          label: Text(TranslationService.translate('skip')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),

                        // Complete button
                        ElevatedButton.icon(
                          onPressed: () async {
                            // TODO: Mark as complete
                            await analytics.logCustomEvent(
                              name: 'item_completed',
                              parameters: {
                                'checklist_id': checklistId,
                                'item_id': 'current_item_id',
                              },
                            );
                          },
                          icon: const Icon(Icons.check),
                          label: Text(TranslationService.translate('complete')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Navigation buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Previous button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Go to previous item
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: Text(TranslationService.translate('previous')),
                ),

                // Next button
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Go to next item
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(TranslationService.translate('next')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
