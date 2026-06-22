// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ShaqoNet';

  @override
  String get loginTitle => 'My Work';

  @override
  String get loginSubtitle =>
      'Sign in to see your shifts, activity, hours, and work records.';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign in';

  @override
  String get demoMode => 'Demo mode';

  @override
  String get home => 'Home';

  @override
  String get schedule => 'Schedule';

  @override
  String get activity => 'Activity';

  @override
  String get messages => 'Messages';

  @override
  String get hub => 'Team Hub';

  @override
  String get hours => 'Hours';

  @override
  String get profile => 'Profile';

  @override
  String get nextShift => 'Next shift';

  @override
  String get upcomingShifts => 'Upcoming shifts';

  @override
  String get availableShifts => 'Available shifts';

  @override
  String get weeklySchedule => 'Weekly schedule';

  @override
  String get activityFeed => 'Activity feed';

  @override
  String get totalHours => 'Total hours';

  @override
  String get timeSummary => 'Time summary';

  @override
  String get breakTime => 'Break time';

  @override
  String get aiInsight => 'AI insight';

  @override
  String get language => 'Language';

  @override
  String get employmentCertificate => 'Employment certificate';

  @override
  String get downloadPlaceholder => 'Contact your workplace for this document';

  @override
  String get logout => 'Logout';

  @override
  String get offlineReady => 'Offline-ready synced data';

  @override
  String get lastUpdated => 'Last updated just now';

  @override
  String get role => 'Role';

  @override
  String get phone => 'Phone';

  @override
  String get company => 'Company';

  @override
  String get notProvided => 'Not provided';

  @override
  String get preferences => 'Preferences';

  @override
  String get appLanguage => 'App language';

  @override
  String get englishName => 'English';

  @override
  String get somaliName => 'Somali';

  @override
  String get swahiliName => 'Swahili';

  @override
  String get documents => 'Documents';

  @override
  String get employmentDocumentsManaged =>
      'Employment documents are managed by your workplace.';

  @override
  String get all => 'All';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get open => 'Open';

  @override
  String get openShift => 'Open shift';

  @override
  String get changed => 'Changed';

  @override
  String get thisWeek => 'This week';

  @override
  String shiftsFor(String date) {
    return 'Shifts for $date';
  }

  @override
  String shiftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
      zero: 'No shifts',
    );
    return '$_temp0';
  }

  @override
  String get noShiftsMatch => 'No shifts match this filter right now.';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String get duration => 'Duration';

  @override
  String get notes => 'Notes';

  @override
  String get openShiftNote =>
      'Open shift. Accepting it will notify the coordinator.';

  @override
  String get noManagerNote => 'No manager note for this shift.';

  @override
  String get acceptOpenShift => 'Accept open shift';

  @override
  String get accepting => 'Accepting...';

  @override
  String get shiftUnavailable => 'Shift no longer available';

  @override
  String get alreadyAssigned => 'Already assigned';

  @override
  String get shiftAccepted => 'Open shift accepted and added to your schedule.';

  @override
  String get shiftAcceptFailed =>
      'Could not accept shift. Please try again later.';

  @override
  String hoursAndBreak(String hours, int minutes) {
    return '$hours hours, $minutes min break';
  }

  @override
  String get dateRange => 'Date range';

  @override
  String get change => 'Change';

  @override
  String get thisMonth => 'This month';

  @override
  String get lastSevenDays => 'Last 7 days';

  @override
  String get totalShiftHours => 'Total shift hours';

  @override
  String get workDays => 'Work days';

  @override
  String get averageShiftLength => 'Avg shift length';

  @override
  String get timeBalance => 'Time balance';

  @override
  String get bookedDays => 'Booked days';

  @override
  String get noBookedShifts => 'No booked shifts in this range';

  @override
  String get timeReport => 'Hours / Time report';

  @override
  String get chooseWorkedDays => 'Choose worked days';

  @override
  String get apply => 'Apply';

  @override
  String get activities => 'Activities';

  @override
  String unreadCount(int count) {
    return '$count unread';
  }

  @override
  String get markAllRead => 'Mark all read';

  @override
  String get noActivityYet => 'No activity yet.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int count) {
    return '$count min ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count h ago';
  }

  @override
  String daysAgo(int count) {
    return '$count d ago';
  }

  @override
  String aiOverdueConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shifts',
      one: '1 shift',
    );
    return 'AI insight: You missed the 7-day confirmation window for $_temp0. Ask your manager to review.';
  }

  @override
  String aiPendingConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed shifts are',
      one: '1 completed shift is',
    );
    return 'AI insight: $_temp0 waiting for confirmation. Confirm within 7 days of each shift.';
  }

  @override
  String get aiNoAssignedShifts =>
      'AI insight: No assigned shifts in this range yet. Widen the date range to check other days.';

  @override
  String aiScheduledNoneCompleted(String hours) {
    return 'AI insight: You have $hours scheduled hours in this range, but none completed yet.';
  }

  @override
  String get aiAllHoursCompleted =>
      'AI insight: Great consistency. All scheduled hours in this range are completed.';

  @override
  String aiHoursProgress(
      String completed, String remaining, String breakHours) {
    return 'AI insight: ${completed}h completed, ${remaining}h remaining, with ${breakHours}h break time scheduled.';
  }

  @override
  String get shifts => 'Shifts';

  @override
  String get absence => 'Absence';

  @override
  String get information => 'Information';

  @override
  String get noUpcomingShifts => 'No upcoming shifts yet';

  @override
  String get shiftConfirmations => 'Shift confirmations';

  @override
  String get confirmWithinSevenDays =>
      'Confirm completed shifts within 7 days.';

  @override
  String get confirming => 'Confirming...';

  @override
  String get confirmWorked => 'Confirm worked';

  @override
  String confirmedOn(String date) {
    return 'Confirmed $date';
  }

  @override
  String get confirmWorkedQuestion => 'Confirm worked shift?';

  @override
  String get confirmAttestation =>
      'I confirm that I worked this shift as scheduled.';

  @override
  String get cancel => 'Cancel';

  @override
  String get shiftConfirmedAsWorked => 'Shift confirmed as worked.';

  @override
  String get shiftConfirmationFailed =>
      'Could not confirm this shift. Please try again.';

  @override
  String get inbox => 'Inbox';

  @override
  String unreadWithCount(int count) {
    return 'Unread $count';
  }

  @override
  String get sent => 'Sent';

  @override
  String get subject => 'Subject';

  @override
  String get audience => 'Audience';

  @override
  String get message => 'Message';

  @override
  String get managers => 'Managers';

  @override
  String get contacts => 'Contacts';

  @override
  String get writeMessage => 'Write message';

  @override
  String get whatIsThisAbout => 'What is this about?';

  @override
  String get sendDirectlyToManagers => 'Send directly to your managers.';

  @override
  String get writeYourMessage => 'Write your message...';

  @override
  String get sendPrivateText => 'Send private text';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get noUnreadMessages => 'No unread messages';

  @override
  String get noSentMessages => 'No sent messages';

  @override
  String get you => 'You';

  @override
  String get sentMessage => 'Sent message';

  @override
  String messageFrom(String name) {
    return 'Message from $name';
  }

  @override
  String get reply => 'Reply';

  @override
  String get comment => 'Comment';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get chooseFromGallery => 'Choose from gallery';

  @override
  String get remove => 'Remove';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get phoneNumber => 'Phone number';

  @override
  String get jobTitle => 'Job title';

  @override
  String get extraInformation => 'Extra information';

  @override
  String get workplaceManagesExtraInfo =>
      'Emergency contact, certificates, and employment notes are managed by your workplace.';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileSaveFailed => 'Could not save profile. Please try again.';

  @override
  String get validProfileRequired =>
      'Add first name, last name, and a valid email.';

  @override
  String get imageTooLarge => 'Image is too large. Choose a smaller photo.';

  @override
  String get imagePickFailed => 'Could not pick image. Please try again.';

  @override
  String get awaitingConfirmation => 'Awaiting confirmation';

  @override
  String get confirmationOverdue => 'Confirmation overdue';

  @override
  String get scheduled => 'Scheduled';

  @override
  String get absent => 'Absent';

  @override
  String confirmBy(String date) {
    return 'Confirm by $date';
  }

  @override
  String get managerReviewRequired => 'Manager review required';

  @override
  String aiPendingConfirmationReminder(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count completed shifts are',
      one: '1 completed shift is',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'within $days days',
      one: 'within 1 day',
      zero: 'today',
    );
    return 'AI insight: $_temp0 waiting for confirmation. The oldest must be confirmed $_temp1.';
  }
}
