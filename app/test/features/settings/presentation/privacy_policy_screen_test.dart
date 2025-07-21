import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:checklister/features/settings/presentation/privacy_policy_screen.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget _wrapWithMaterial(Widget child, Locale locale) {
    return ProviderScope(
      child: MaterialApp(
        locale: locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('es')],
        home: child,
      ),
    );
  }

  testWidgets('displays English privacy policy markdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterial(const PrivacyPolicyScreen(), const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Markdown), findsOneWidget);
    expect(
      find.textContaining('Your privacy is important to us.'),
      findsOneWidget,
    );
  });

  testWidgets('displays Spanish privacy policy markdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterial(const PrivacyPolicyScreen(), const Locale('es')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Markdown), findsOneWidget);
    expect(
      find.textContaining('Su privacidad es importante para nosotros.'),
      findsOneWidget,
    );
  });
}
