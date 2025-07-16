import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';
import '../../../core/services/translation_service.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static final List<_LanguageOption> _languages = [
    _LanguageOption(
      locale: const Locale('en', 'US'),
      name: 'English',
      flag: '🇺🇸',
    ),
    _LanguageOption(
      locale: const Locale('es', 'ES'),
      name: 'Español',
      flag: '🇪🇸',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        // Watch the settings to get the current language preference
        final settings = ref.watch(settingsProvider);
        final currentLocale = settings.language ?? context.locale;

        // Watch the translation provider to trigger rebuilds
        ref.watch(translationProvider);

        return Scaffold(
          appBar: AppBar(
            title: Text(TranslationService.translate('language')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            children: [
              // Language options
              ...List.generate(_languages.length, (index) {
                final lang = _languages[index];
                final isSelected =
                    lang.locale.languageCode == currentLocale.languageCode &&
                    lang.locale.countryCode == currentLocale.countryCode;

                return Column(
                  children: [
                    ListTile(
                      leading: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 28),
                      ),
                      title: Text(
                        lang.name,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : const Icon(
                              Icons.radio_button_unchecked,
                              color: Colors.grey,
                            ),
                      onTap: () async {
                        if (!isSelected) {
                          try {
                            // Save language preference to settings first
                            await ref
                                .read(settingsProvider.notifier)
                                .setLanguage(lang.locale);

                            // Update the translation provider to trigger rebuilds
                            await ref
                                .read(translationProvider.notifier)
                                .setLocale(lang.locale);

                            // Update EasyLocalization for compatibility
                            await context.setLocale(lang.locale);

                            // Navigate back to settings screen
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            // Handle any errors during language change
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error changing language: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: isSelected
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withOpacity(0.08)
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    if (index < _languages.length - 1) const Divider(height: 1),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _LanguageOption {
  final Locale locale;
  final String name;
  final String flag;
  const _LanguageOption({
    required this.locale,
    required this.name,
    required this.flag,
  });
}
