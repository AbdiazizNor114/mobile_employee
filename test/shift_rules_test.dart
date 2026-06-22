import 'package:flutter_test/flutter_test.dart';
import 'package:shaqonet_employee/core/models/shift.dart';

void main() {
  group('Shift time rules', () {
    test('ended open shifts cannot be accepted', () {
      final now = DateTime(2026, 6, 17, 12);
      final shift = Shift(
        id: 'old-open',
        role: 'Reception',
        location: 'HQ',
        startsAt: now.subtract(const Duration(days: 1, hours: 4)),
        endsAt: now.subtract(const Duration(days: 1)),
        status: ShiftStatus.available,
      );

      expect(shift.hasEnded(now), isTrue);
      expect(shift.canBeAccepted(now), isFalse);
    });

    test('future open shifts can be accepted', () {
      final now = DateTime(2026, 6, 17, 12);
      final shift = Shift(
        id: 'future-open',
        role: 'Reception',
        location: 'HQ',
        startsAt: now.add(const Duration(days: 1)),
        endsAt: now.add(const Duration(days: 1, hours: 8)),
        status: ShiftStatus.available,
      );

      expect(shift.canBeAccepted(now), isTrue);
    });

    test('worked shift can be confirmed for seven days after it ends', () {
      final endedAt = DateTime(2026, 6, 17, 12);
      final shift = Shift(
        id: 'worked-shift',
        role: 'Reception',
        location: 'HQ',
        startsAt: endedAt.subtract(const Duration(hours: 8)),
        endsAt: endedAt,
        status: ShiftStatus.confirmed,
        workConfirmationRequired: true,
      );

      expect(shift.canConfirmWork(endedAt), isTrue);
      expect(
        shift.canConfirmWork(endedAt.add(const Duration(days: 7))),
        isTrue,
      );
      expect(
        shift.isWorkConfirmationOverdue(
          endedAt.add(const Duration(days: 7, seconds: 1)),
        ),
        isTrue,
      );
    });

    test('confirmed work is no longer pending', () {
      final endedAt = DateTime(2026, 6, 17, 12);
      final shift = Shift(
        id: 'confirmed-work',
        role: 'Reception',
        location: 'HQ',
        startsAt: endedAt.subtract(const Duration(hours: 8)),
        endsAt: endedAt,
        status: ShiftStatus.confirmed,
        workConfirmationRequired: true,
        workConfirmationStatus: WorkConfirmationStatus.confirmed,
        workConfirmedAt: endedAt.add(const Duration(hours: 1)),
      );

      expect(shift.isAwaitingWorkConfirmation(endedAt), isFalse);
      expect(shift.canConfirmWork(endedAt), isFalse);
    });

    test('historical shifts outside the rollout do not become overdue', () {
      final endedAt = DateTime(2026, 5, 1, 12);
      final shift = Shift(
        id: 'historical-shift',
        role: 'Reception',
        location: 'HQ',
        startsAt: endedAt.subtract(const Duration(hours: 8)),
        endsAt: endedAt,
        status: ShiftStatus.confirmed,
      );

      expect(
        shift.isWorkConfirmationOverdue(endedAt.add(const Duration(days: 30))),
        isFalse,
      );
    });

    test('manager-marked absence is resolved and not overdue', () {
      final endedAt = DateTime(2026, 6, 1, 12);
      final shift = Shift(
        id: 'absent-shift',
        role: 'Reception',
        location: 'HQ',
        startsAt: endedAt.subtract(const Duration(hours: 8)),
        endsAt: endedAt,
        status: ShiftStatus.confirmed,
        workConfirmationRequired: true,
        workConfirmationStatus: WorkConfirmationStatus.absent,
      );

      expect(
        shift.isWorkConfirmationOverdue(endedAt.add(const Duration(days: 30))),
        isFalse,
      );
    });
  });
}
