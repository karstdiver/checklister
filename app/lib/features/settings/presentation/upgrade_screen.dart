import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/analytics_service.dart';
import '../../../core/services/translation_service.dart';

class UpgradeScreen extends ConsumerWidget {
  const UpgradeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Log screen view for analytics
    AnalyticsService().logScreenView(screenName: 'UpgradeScreen');

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('upgrade')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(Icons.workspace_premium, size: 80, color: Colors.amber),
            const SizedBox(height: 24),
            Text(
              TranslationService.translate('upgrade_benefits_title'),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              TranslationService.translate('upgrade_benefits_desc'),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                AnalyticsService().logCustomEvent(name: 'upgrade_button_tap');
                // TODO: Implement upgrade flow (e.g., open purchase dialog)
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      TranslationService.translate('upgrade_coming_soon'),
                    ),
                  ),
                );
              },
              child: Text(TranslationService.translate('upgrade_now')),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
