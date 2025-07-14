import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        // Watch the current locale to trigger rebuilds when language changes
        final currentLocale = context.locale;

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
              final isSelected = lang.locale == currentLocale;
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
                  if (!isSelected) {
                    await context.setLocale(lang.locale);
                  }
                  Navigator.of(context).pop();
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
