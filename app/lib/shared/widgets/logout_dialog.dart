import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/providers.dart';
import '../../core/services/translation_service.dart';
import '../../features/auth/domain/auth_notifier.dart';

class LogoutDialog {
  static Future<void> show(
    BuildContext context,
    AuthNotifier authNotifier,
    WidgetRef ref,
  ) {
    // Watch the translation provider to trigger rebuilds when language changes
    ref.watch(translationProvider);
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(TranslationService.translate('logout')),
          content: Text(TranslationService.translate('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(showLogoutDialogProvider.notifier).state = false;
                Navigator.of(context).pop();
              },
              child: Text(TranslationService.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
                ref.read(showLogoutDialogProvider.notifier).state = false;
                Navigator.of(context).pop();
                await authNotifier.signOut();
                // Navigate to splash screen immediately after logout
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/splash');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(TranslationService.translate('logout')),
            ),
          ],
        );
      },
    );
  }
}
