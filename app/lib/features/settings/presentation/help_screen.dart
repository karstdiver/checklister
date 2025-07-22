import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/translation_service.dart';

class HelpScreen extends ConsumerStatefulWidget {
  const HelpScreen({super.key});

  @override
  ConsumerState<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends ConsumerState<HelpScreen> {
  List<FAQItem> _faqItems = [];
  Locale? _lastLocale;

  @override
  void initState() {
    super.initState();
    // Do not access context here!
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLocale = Localizations.localeOf(context);
    if (_lastLocale != currentLocale) {
      _lastLocale = currentLocale;
      _updateFAQItems();
    }
  }

  void _updateFAQItems() {
    print('[DEBUG] _updateFAQItems called');
    setState(() {
      _faqItems = [
        FAQItem(
          id: 0,
          question: TranslationService.translate(
            'faq_create_checklist_question',
          ),
          answer: TranslationService.translate('faq_create_checklist_answer'),
        ),
        FAQItem(
          id: 1,
          question: TranslationService.translate('faq_start_session_question'),
          answer: TranslationService.translate('faq_start_session_answer'),
        ),
        FAQItem(
          id: 2,
          question: TranslationService.translate('faq_complete_items_question'),
          answer: TranslationService.translate('faq_complete_items_answer'),
        ),
        FAQItem(
          id: 3,
          question: TranslationService.translate('faq_skip_items_question'),
          answer: TranslationService.translate('faq_skip_items_answer'),
        ),
        FAQItem(
          id: 4,
          question: TranslationService.translate('faq_achievements_question'),
          answer: TranslationService.translate('faq_achievements_answer'),
        ),
        FAQItem(
          id: 5,
          question: TranslationService.translate(
            'faq_change_language_question',
          ),
          answer: TranslationService.translate('faq_change_language_answer'),
        ),
        FAQItem(
          id: 6,
          question: TranslationService.translate(
            'faq_enable_notifications_question',
          ),
          answer: TranslationService.translate(
            'faq_enable_notifications_answer',
          ),
        ),
        FAQItem(
          id: 7,
          question: TranslationService.translate('faq_offline_use_question'),
          answer: TranslationService.translate('faq_offline_use_answer'),
        ),
      ];
      print('[DEBUG] FAQ list length: \'${_faqItems.length}\'');
      for (var i = 0; i < _faqItems.length; i++) {
        print('[DEBUG] FAQ $i: question="${_faqItems[i].question}"');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('help')),
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
            // Help Header
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
                        Icons.help,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      TranslationService.translate('help_and_support'),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      TranslationService.translate('help_subtitle'),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              TranslationService.translate('quick_actions'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.play_circle, color: Colors.green),
                    title: Text(
                      TranslationService.translate('getting_started'),
                    ),
                    subtitle: Text(
                      TranslationService.translate('getting_started_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showGettingStartedGuide(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.video_library,
                      color: Colors.blue,
                    ),
                    title: Text(
                      TranslationService.translate('video_tutorials'),
                    ),
                    subtitle: Text(
                      TranslationService.translate('video_tutorials_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showVideoTutorials(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.contact_support,
                      color: Colors.orange,
                    ),
                    title: Text(
                      TranslationService.translate('contact_support'),
                    ),
                    subtitle: Text(
                      TranslationService.translate('contact_support_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showContactSupport(context);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // FAQ Section
            Text(
              TranslationService.translate('frequently_asked_questions'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: ExpansionPanelList.radio(
                elevation: 0,
                expandedHeaderPadding: EdgeInsets.zero,
                children: _faqItems.map((faq) {
                  return ExpansionPanelRadio(
                    value: faq.id,
                    headerBuilder: (context, _) {
                      return ListTile(
                        title: Text(
                          faq.question,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    },
                    body: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Text(
                        faq.answer,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Tips & Tricks
            Text(
              TranslationService.translate('tips_and_tricks'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _buildTipTile(
                    icon: Icons.timer,
                    title: TranslationService.translate('tip_sessions'),
                    description: TranslationService.translate(
                      'tip_sessions_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildTipTile(
                    icon: Icons.emoji_events,
                    title: TranslationService.translate('tip_achievements'),
                    description: TranslationService.translate(
                      'tip_achievements_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildTipTile(
                    icon: Icons.notifications,
                    title: TranslationService.translate('tip_notifications'),
                    description: TranslationService.translate(
                      'tip_notifications_desc',
                    ),
                  ),
                  const Divider(height: 1),
                  _buildTipTile(
                    icon: Icons.language,
                    title: TranslationService.translate('tip_language'),
                    description: TranslationService.translate(
                      'tip_language_desc',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Troubleshooting
            Text(
              TranslationService.translate('troubleshooting'),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.sync_problem, color: Colors.red),
                    title: Text(TranslationService.translate('sync_issues')),
                    subtitle: Text(
                      TranslationService.translate('sync_issues_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showSyncTroubleshooting(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.notifications_off,
                      color: Colors.orange,
                    ),
                    title: Text(
                      TranslationService.translate('notification_issues'),
                    ),
                    subtitle: Text(
                      TranslationService.translate('notification_issues_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showNotificationTroubleshooting(context);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bug_report, color: Colors.purple),
                    title: Text(TranslationService.translate('report_bug')),
                    subtitle: Text(
                      TranslationService.translate('report_bug_desc'),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      _showBugReport(context);
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

  Widget _buildTipTile({
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

  void _showGettingStartedGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('getting_started')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showVideoTutorials(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('video_tutorials')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('contact_support')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSyncTroubleshooting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('sync_issues')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationTroubleshooting(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('notification_issues')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBugReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(TranslationService.translate('report_bug')),
        content: Text(
          TranslationService.translate('future_feature_coming_soon'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final int id;
  final String question;
  final String answer;
  FAQItem({required this.id, required this.question, required this.answer});
}
