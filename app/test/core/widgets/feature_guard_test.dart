import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:checklister/core/widgets/feature_guard.dart';

void main() {
  group('FeatureGuard', () {
    testWidgets('should show fallback when feature is not available', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'itemPhotos',
              child: const Text('Protected Content'),
              fallback: const Text('Custom Fallback'),
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
        ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'unknownFeature',
              child: const Text('Protected Content'),
              fallback: const Text('Custom Fallback'),
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
        ProviderScope(
          child: MaterialApp(
            home: FeatureGuard(
              feature: 'unknownFeature',
              child: const Text('Protected Content'),
              fallback: const Text('Custom Fallback'),
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
