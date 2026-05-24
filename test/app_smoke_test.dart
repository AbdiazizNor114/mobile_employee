import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shaqonet_employee/core/providers/service_providers.dart';
import 'package:shaqonet_employee/main.dart';

void main() {
  testWidgets('shows login and opens employee shell in demo mode', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appBootstrapProvider.overrideWith((ref) async {})],
        child: const ShaqoNetEmployeeBootstrap(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Work'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Demo mode'), findsOneWidget);
    expect(
      find.text(
        'Real sign-in needs Supabase URL and anon key. Demo mode is available.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(
      find.text('Real sign-in is not configured yet. Use Demo mode for now.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Demo mode'));
    await tester.pumpAndSettle();

    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Next shift'), findsOneWidget);

    await tester.tap(find.text('Schedule'));
    await tester.pumpAndSettle();

    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Confirmed'), findsWidgets);
    expect(find.text('Open'), findsWidgets);
    expect(find.text('Upcoming shifts'), findsOneWidget);
    expect(find.text('23h'), findsOneWidget);

    await tester.ensureVisible(find.text('Weekend cover'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekend cover'));
    await tester.pumpAndSettle();

    expect(find.text('Accept open shift'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);

    await tester.tap(find.text('Accept open shift'));
    await tester.pumpAndSettle();

    expect(
      find.text('Open shift accepted and added to your schedule.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Weekend cover'));
    await tester.pumpAndSettle();

    expect(find.text('Already assigned'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView).first, const Offset(0, 500), 1000);
    await tester.pumpAndSettle();

    expect(find.text('31h'), findsOneWidget);

    await tester.tap(find.text('Activity'));
    await tester.pumpAndSettle();

    expect(find.text('3 unread'), findsOneWidget);
    expect(find.text('Shift accepted'), findsOneWidget);
    expect(find.text('Weekend cover at West Team'), findsOneWidget);
    expect(find.textContaining('h ago'), findsWidgets);

    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();

    expect(find.text('0 unread'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('English'), findsOneWidget);
    expect(find.text('Somali'), findsOneWidget);

    await tester.tap(find.text('Somali'));
    await tester.pumpAndSettle();

    expect(find.text('Hoy'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Samira');
    await tester.enterText(find.byType(TextFormField).at(1), 'Ali');
    await tester.tap(find.text('Save profile'));
    await tester.pumpAndSettle();

    expect(find.text('Samira Ali'), findsWidgets);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'Not Saved');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Samira Ali'), findsWidgets);
    expect(find.text('Not Saved Ali'), findsNothing);
    expect(find.text('Next shift'), findsOneWidget);

    await tester.tap(find.text('Hours').last);
    await tester.pumpAndSettle();

    expect(find.text('Date range'), findsOneWidget);
    expect(find.text('49.5'), findsOneWidget);
    expect(find.text('Total shift hours'), findsOneWidget);
    expect(find.text('Break time'), findsOneWidget);
    expect(find.text('Avg shift length'), findsOneWidget);

    await tester.tap(find.text('This week'));
    await tester.pumpAndSettle();

    expect(find.text('26'), findsOneWidget);

    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'AI insight: Your time record is stable for the selected range. Review changed shifts before the report closes.',
      ),
      findsOneWidget,
    );
  });
}
