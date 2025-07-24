import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/translation_service.dart';
import '../../shared/widgets/app_card.dart';
import 'package:checklister/features/auth/presentation/login_screen.dart';

class AnonymousProfileEncouragement extends ConsumerWidget {
  final VoidCallback? onSignUp;
  final VoidCallback? onMaybeLater;

  const AnonymousProfileEncouragement({
    super.key,
    this.onSignUp,
    this.onMaybeLater,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('profile')),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    // Profile Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.person_add,
                        size: 60,
                        color: Colors.blue,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      TranslationService.translate(
                        'anonymous_profile_encouragement_title',
                      ),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      TranslationService.translate(
                        'anonymous_profile_encouragement_subtitle',
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Description Card
                    AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TranslationService.translate(
                                'anonymous_profile_encouragement_description',
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 16),

                            Text(
                              TranslationService.translate(
                                'anonymous_profile_benefits',
                              ),
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),

                            const SizedBox(height: 8),

                            _buildBenefitItem(
                              TranslationService.translate(
                                'anonymous_profile_benefit_1',
                              ),
                            ),
                            _buildBenefitItem(
                              TranslationService.translate(
                                'anonymous_profile_benefit_2',
                              ),
                            ),
                            _buildBenefitItem(
                              TranslationService.translate(
                                'anonymous_profile_benefit_3',
                              ),
                            ),
                            _buildBenefitItem(
                              TranslationService.translate(
                                'anonymous_profile_benefit_4',
                              ),
                            ),
                            _buildBenefitItem(
                              TranslationService.translate(
                                'anonymous_profile_benefit_5',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        onSignUp ??
                        () {
                          print('[DEBUG] EncouragementScreen: onSignUp tapped');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LoginScreen(initialSignUpMode: true),
                            ),
                          );
                        },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      TranslationService.translate('sign_up_free'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                        onMaybeLater ??
                        () {
                          Navigator.of(context).pop();
                        },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      TranslationService.translate('maybe_later'),
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
