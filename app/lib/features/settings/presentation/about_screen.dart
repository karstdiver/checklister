import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/translation_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends ConsumerStatefulWidget {
  const AboutScreen({super.key});

  @override
  ConsumerState<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends ConsumerState<AboutScreen> {
  PackageInfo? _packageInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = packageInfo;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('about')),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.checklist,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Checklister',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TranslationService.translate('app_tagline'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    if (_packageInfo != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Version ${_packageInfo!.version} (${_packageInfo!.buildNumber})',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Features Section
            Text(
              TranslationService.translate('features'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildFeatureTile(
                    icon: Icons.checklist,
                    title: TranslationService.translate('feature_checklists'),
                    description: TranslationService.translate(
                      'feature_checklists_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    icon: Icons.timer,
                    title: TranslationService.translate('feature_sessions'),
                    description: TranslationService.translate(
                      'feature_sessions_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    icon: Icons.emoji_events,
                    title: TranslationService.translate('feature_achievements'),
                    description: TranslationService.translate(
                      'feature_achievements_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    icon: Icons.language,
                    title: TranslationService.translate('feature_multilingual'),
                    description: TranslationService.translate(
                      'feature_multilingual_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildFeatureTile(
                    icon: Icons.cloud_sync,
                    title: TranslationService.translate('feature_sync'),
                    description: TranslationService.translate(
                      'feature_sync_desc',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Team Section
            Text(
              TranslationService.translate('team'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TranslationService.translate('developed_by'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).primaryColor,
                          child: const Text(
                            'KD',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karst Diver',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                TranslationService.translate('lead_developer'),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Contact Section
            Text(
              TranslationService.translate('contact'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: Text(TranslationService.translate('email_support')),
                    subtitle: const Text('support@checklister.app'),
                    onTap: () {
                      // TODO: Implement email support
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.web),
                    title: Text(TranslationService.translate('website')),
                    subtitle: const Text('checklister.app'),
                    onTap: () {
                      // TODO: Implement website link
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report),
                    title: Text(TranslationService.translate('report_bug')),
                    onTap: () {
                      // TODO: Implement bug reporting
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Legal Section
            Text(
              TranslationService.translate('legal'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.privacy_tip),
                    title: Text(TranslationService.translate('privacy_policy')),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Implement privacy policy
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.description),
                    title: Text(
                      TranslationService.translate('terms_of_service'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // TODO: Implement terms of service
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(description),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
