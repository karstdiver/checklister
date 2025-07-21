import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/translation_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown/flutter_markdown.dart';

class TermsOfServiceScreen extends ConsumerWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(translationProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(TranslationService.translate('terms_of_service')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<String>(
          future: _loadLocalizedMarkdown(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text(TranslationService.translate('tos_load_error')),
              );
            } else {
              return Markdown(
                data: snapshot.data ?? '',
                styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
              );
            }
          },
        ),
      ),
    );
  }

  Future<String> _loadLocalizedMarkdown(BuildContext context) async {
    final locale = Localizations.localeOf(context).languageCode;
    final assetPath = 'assets/terms_of_service_${locale}.md';
    try {
      return await rootBundle.loadString(assetPath);
    } catch (_) {
      // Fallback to English if the localized file doesn't exist
      return await rootBundle.loadString('assets/terms_of_service_en.md');
    }
  }
}
