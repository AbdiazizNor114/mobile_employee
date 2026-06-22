import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaqonet_employee/core/providers/service_providers.dart';
import 'package:shaqonet_employee/main.dart';

void main() {
  testWidgets('renders login and validates required credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        child: const ShaqoNetEmployeeBootstrap(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ShaqoNet'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('navigates tabs when authenticated session is present', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
          currentSessionProvider.overrideWith((ref) => true),
        ],
        child: const ShaqoNetEmployeeBootstrap(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Work'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();
    expect(find.text('This week'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();
    expect(find.text('Activities'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('opens the schedule in Somali without locale errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appBootstrapProvider.overrideWith((ref) async {}),
          currentSessionProvider.overrideWith((ref) => true),
        ],
        child: const ShaqoNetEmployeeBootstrap(),
      ),
    );
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ShaqoNetEmployeeBootstrap)),
    );
    await container.read(languageCodeProvider.notifier).setLanguage('so');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jadwalka'));
    await tester.pumpAndSettle();

    expect(find.text('Toddobaadkan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
