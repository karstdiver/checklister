import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:checklister/features/settings/presentation/terms_of_service_screen.dart';
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

  testWidgets('displays English terms of service markdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterial(const TermsOfServiceScreen(), const Locale('en')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Markdown), findsOneWidget);
    expect(
      find.textContaining('By using this app, you agree to use it responsibly'),
      findsOneWidget,
    );
  });

  testWidgets('displays Spanish terms of service markdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrapWithMaterial(const TermsOfServiceScreen(), const Locale('es')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Markdown), findsOneWidget);
    expect(
      find.textContaining(
        'Al usar esta aplicación, usted acepta utilizarla de manera responsable',
      ),
      findsOneWidget,
    );
  });
}
