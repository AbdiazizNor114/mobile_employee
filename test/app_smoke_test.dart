import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaqonet_employee/core/models/shift.dart';
import 'package:shaqonet_employee/core/providers/mock_work_provider.dart';
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

    expect(find.bySemanticsLabel('ShaqoNet'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a valid email address.'), findsOneWidget);
  });

  testWidgets('opens forgot password and validates email', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        child: const ShaqoNetEmployeeBootstrap(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset password'), findsOneWidget);
    expect(find.text('Send reset link'), findsOneWidget);

    await tester.tap(find.text('Send reset link'));
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

  testWidgets('keeps yesterday shift available for confirmation in Hours', (
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
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    container.read(companyPlanProvider.notifier).state = 'pro';
    container.read(shiftsProvider.notifier).replaceAll([
      Shift(
        id: 'yesterday-shift',
        role: 'Receptionist',
        location: 'HQ',
        startsAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          8,
        ),
        endsAt: DateTime(
          yesterday.year,
          yesterday.month,
          yesterday.day,
          16,
        ),
        status: ShiftStatus.confirmed,
        workConfirmationRequired: true,
      ),
      Shift(
        id: 'future-shift',
        role: 'Future shift',
        location: 'HQ',
        startsAt: DateTime.now().add(const Duration(days: 2)),
        endsAt: DateTime.now().add(const Duration(days: 2, hours: 8)),
        status: ShiftStatus.confirmed,
        workConfirmationRequired: true,
      ),
    ]);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hours'));
    await tester.pumpAndSettle();

    expect(find.text('Awaiting confirmation'), findsOneWidget);
    expect(find.text('Scheduled'), findsOneWidget);
    expect(find.textContaining('1 completed shift is waiting'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Awaiting confirmation')).dy,
      lessThan(tester.getTopLeft(find.text('Scheduled')).dy),
    );

    await tester.ensureVisible(find.text('Awaiting confirmation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Awaiting confirmation'));
    await tester.pumpAndSettle();

    expect(find.text('Confirm worked'), findsOneWidget);
  });

  testWidgets('shows detailed openable upcoming shifts on My Work', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

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
    final future = DateTime.now().add(const Duration(days: 3));
    container.read(shiftsProvider.notifier).replaceAll([
      Shift(
        id: 'future-detailed-shift',
        role: 'Very long reception shift title that should fit',
        location: 'Main floor with a very long location name',
        startsAt: DateTime(future.year, future.month, future.day, 9),
        endsAt: DateTime(future.year, future.month, future.day, 17),
        breakMinutes: 45,
        status: ShiftStatus.confirmed,
        notes: 'Bring badge.',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('09:00 - 17:00 · 8 hours, 45 min break'), findsWidgets);

    await tester.ensureVisible(find.text('09:00').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('09:00').last);
    await tester.pumpAndSettle();

    expect(find.text('Date'), findsWidgets);
    expect(find.text('Time'), findsWidgets);
    expect(find.text('Break time'), findsWidgets);
    expect(find.text('Bring badge.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('localizes absence tab in Somali', (tester) async {
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

    await tester.tap(find.text('Maqnaanshaha'));
    await tester.pumpAndSettle();

    expect(find.text('Codso maqnaansho'), findsOneWidget);
    expect(find.text('Sababta'), findsOneWidget);
    expect(find.text('Dir codsiga'), findsOneWidget);
  });
}
