import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/core/widgets/feature_guard.dart';
import 'package:checklister/core/providers/privilege_provider.dart';
import 'package:checklister/core/domain/user_tier.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:checklister/firebase_options.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {}
  });

  group('FeatureGuard', () {
    testWidgets('should show fallback when feature is not available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'itemPhotos',
              child: Text('Protected Content'),
              fallback: Text('Custom Fallback'),
            ),
          ),
        ),
      );

      // Should show fallback for restricted feature
      expect(find.text('Protected Content'), findsNothing);
      expect(find.text('Custom Fallback'), findsOneWidget);
    });

    testWidgets('should work with custom fallback widgets', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'unknownFeature',
              child: Text('Protected Content'),
              fallback: Text('Custom Fallback'),
            ),
          ),
        ),
      );

      // Should show custom fallback
      expect(find.text('Protected Content'), findsNothing);
      expect(find.text('Custom Fallback'), findsOneWidget);
    });

    testWidgets('should handle unknown features gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'unknownFeature',
              child: Text('Protected Content'),
              fallback: Text('Custom Fallback'),
            ),
          ),
        ),
      );

      // Should show fallback for unknown feature
      expect(find.text('Protected Content'), findsNothing);
      expect(find.text('Custom Fallback'), findsOneWidget);
    });
  });
}

class PrivilegeNotifierFake extends StateNotifier<UserPrivileges?> {
  PrivilegeNotifierFake(UserPrivileges initial) : super(initial);
}
