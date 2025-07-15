import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/settings_provider.dart';

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

        print(
          '🔍 DEBUG: LanguageScreen - settings.language: ${settings.language?.languageCode}_${settings.language?.countryCode}',
        );
        print(
          '🔍 DEBUG: LanguageScreen - context.locale: ${context.locale.languageCode}_${context.locale.countryCode}',
        );
        print(
          '🔍 DEBUG: LanguageScreen - currentLocale: ${currentLocale.languageCode}_${currentLocale.countryCode}',
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(tr('language')),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            itemCount: _languages.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected =
                  lang.locale.languageCode == currentLocale.languageCode &&
                  lang.locale.countryCode == currentLocale.countryCode;

              print(
                '🔍 DEBUG: Language option ${lang.name}: ${lang.locale.languageCode}_${lang.locale.countryCode} vs current: ${currentLocale.languageCode}_${currentLocale.countryCode} -> isSelected: $isSelected',
              );

              return ListTile(
                leading: Text(lang.flag, style: const TextStyle(fontSize: 28)),
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
                  print(
                    '🔍 DEBUG: Tapped on ${lang.name} (isSelected: $isSelected)',
                  );
                  if (!isSelected) {
                    try {
                      print(
                        '🔍 DEBUG: Changing language from ${currentLocale.languageCode}_${currentLocale.countryCode} to ${lang.locale.languageCode}_${lang.locale.countryCode}',
                      );

                      // Save language preference to settings first
                      await ref
                          .read(settingsProvider.notifier)
                          .setLanguage(lang.locale);

                      print('🔍 DEBUG: Language saved to settings');

                      // Then update EasyLocalization context
                      await context.setLocale(lang.locale);

                      // Force EasyLocalization to reload translations
                      await EasyLocalization.of(
                        context,
                      )?.delegate.load(lang.locale);

                      print(
                        '🔍 DEBUG: EasyLocalization context updated and translations reloaded',
                      );

                      // Navigate back after successful language change
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      print('🔍 DEBUG: Error changing language: $e');
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
                  } else {
                    print(
                      '🔍 DEBUG: Language already selected, just navigating back',
                    );
                    Navigator.of(context).pop();
                  }
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                tileColor: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              );
            },
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
