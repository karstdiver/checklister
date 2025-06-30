import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../features/auth/domain/auth_notifier.dart';

class LogoutDialog {
  static Future<void> show(BuildContext context, AuthNotifier authNotifier) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(tr('logout')),
          content: Text(tr('logout_confirmation')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('cancel')),
            ),
            ElevatedButton(
              onPressed: () async {
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
              child: Text(tr('logout')),
            ),
          ],
        );
      },
    );
  }
}
