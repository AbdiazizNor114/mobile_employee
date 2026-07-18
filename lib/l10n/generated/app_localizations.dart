import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_so.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('so'),
    Locale('sw')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ShaqoNet'**
  String get appTitle;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'My Work'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your shifts, activity, hours, and work records.'**
  String get loginSubtitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @validEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get validEmailRequired;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordMinLength;

  /// No description provided for @signInGenericError.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Check your email and password.'**
  String get signInGenericError;

  /// No description provided for @serverUnreachable.
  ///
  /// In en, this message translates to:
  /// **'Could not reach the ShaqoNet server. Please try again.'**
  String get serverUnreachable;

  /// No description provided for @signInFailedWithStatus.
  ///
  /// In en, this message translates to:
  /// **'Sign-in failed ({status}). Please try again.'**
  String signInFailedWithStatus(int status);

  /// No description provided for @resetPassword.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetPassword;

  /// No description provided for @resetPasswordHelp.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email and we will send you a secure reset link.'**
  String get resetPasswordHelp;

  /// No description provided for @sendResetLink.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get sendResetLink;

  /// No description provided for @passwordResetSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get passwordResetSent;

  /// No description provided for @passwordResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send reset email. Try again.'**
  String get passwordResetFailed;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode'**
  String get demoMode;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// No description provided for @activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @hub.
  ///
  /// In en, this message translates to:
  /// **'Team Hub'**
  String get hub;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @nextShift.
  ///
  /// In en, this message translates to:
  /// **'Next shift'**
  String get nextShift;

  /// No description provided for @upcomingShifts.
  ///
  /// In en, this message translates to:
  /// **'Upcoming shifts'**
  String get upcomingShifts;

  /// No description provided for @availableShifts.
  ///
  /// In en, this message translates to:
  /// **'Available shifts'**
  String get availableShifts;

  /// No description provided for @weeklySchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly schedule'**
  String get weeklySchedule;

  /// No description provided for @activityFeed.
  ///
  /// In en, this message translates to:
  /// **'Activity feed'**
  String get activityFeed;

  /// No description provided for @totalHours.
  ///
  /// In en, this message translates to:
  /// **'Total hours'**
  String get totalHours;

  /// No description provided for @timeSummary.
  ///
  /// In en, this message translates to:
  /// **'Time summary'**
  String get timeSummary;

  /// No description provided for @breakTime.
  ///
  /// In en, this message translates to:
  /// **'Break time'**
  String get breakTime;

  /// No description provided for @aiInsight.
  ///
  /// In en, this message translates to:
  /// **'AI insight'**
  String get aiInsight;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @employmentCertificate.
  ///
  /// In en, this message translates to:
  /// **'Employment certificate'**
  String get employmentCertificate;

  /// No description provided for @downloadPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Contact your workplace for this document'**
  String get downloadPlaceholder;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @offlineReady.
  ///
  /// In en, this message translates to:
  /// **'Saved work is available offline'**
  String get offlineReady;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Saved just now'**
  String get lastUpdated;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @notProvided.
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @englishName.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishName;

  /// No description provided for @somaliName.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get somaliName;

  /// No description provided for @swahiliName.
  ///
  /// In en, this message translates to:
  /// **'Swahili'**
  String get swahiliName;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @employmentDocumentsManaged.
  ///
  /// In en, this message translates to:
  /// **'Employment documents are managed by your workplace.'**
  String get employmentDocumentsManaged;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @confirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmed;

  /// No description provided for @open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get open;

  /// No description provided for @openShift.
  ///
  /// In en, this message translates to:
  /// **'Open shift'**
  String get openShift;

  /// No description provided for @changed.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get changed;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get thisWeek;

  /// No description provided for @shiftsFor.
  ///
  /// In en, this message translates to:
  /// **'Shifts for {date}'**
  String shiftsFor(String date);

  /// No description provided for @shiftCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No shifts} =1{1 shift} other{{count} shifts}}'**
  String shiftCount(int count);

  /// No description provided for @noShiftsMatch.
  ///
  /// In en, this message translates to:
  /// **'No shifts match this filter right now.'**
  String get noShiftsMatch;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get duration;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @openShiftNote.
  ///
  /// In en, this message translates to:
  /// **'Open shift. Accepting it will notify the coordinator.'**
  String get openShiftNote;

  /// No description provided for @noManagerNote.
  ///
  /// In en, this message translates to:
  /// **'No manager note for this shift.'**
  String get noManagerNote;

  /// No description provided for @acceptOpenShift.
  ///
  /// In en, this message translates to:
  /// **'Accept open shift'**
  String get acceptOpenShift;

  /// No description provided for @accepting.
  ///
  /// In en, this message translates to:
  /// **'Accepting...'**
  String get accepting;

  /// No description provided for @shiftUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Shift no longer available'**
  String get shiftUnavailable;

  /// No description provided for @alreadyAssigned.
  ///
  /// In en, this message translates to:
  /// **'Already assigned'**
  String get alreadyAssigned;

  /// No description provided for @shiftAccepted.
  ///
  /// In en, this message translates to:
  /// **'Open shift accepted and added to your schedule.'**
  String get shiftAccepted;

  /// No description provided for @shiftAcceptFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not accept shift. Please try again later.'**
  String get shiftAcceptFailed;

  /// No description provided for @hoursAndBreak.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours, {minutes} min break'**
  String hoursAndBreak(String hours, int minutes);

  /// No description provided for @dateRange.
  ///
  /// In en, this message translates to:
  /// **'Date range'**
  String get dateRange;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get thisMonth;

  /// No description provided for @lastSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Last 7 days'**
  String get lastSevenDays;

  /// No description provided for @totalShiftHours.
  ///
  /// In en, this message translates to:
  /// **'Total shift hours'**
  String get totalShiftHours;

  /// No description provided for @workDays.
  ///
  /// In en, this message translates to:
  /// **'Work days'**
  String get workDays;

  /// No description provided for @averageShiftLength.
  ///
  /// In en, this message translates to:
  /// **'Avg shift length'**
  String get averageShiftLength;

  /// No description provided for @timeBalance.
  ///
  /// In en, this message translates to:
  /// **'Time balance'**
  String get timeBalance;

  /// No description provided for @bookedDays.
  ///
  /// In en, this message translates to:
  /// **'Booked days'**
  String get bookedDays;

  /// No description provided for @noBookedShifts.
  ///
  /// In en, this message translates to:
  /// **'No booked shifts in this range'**
  String get noBookedShifts;

  /// No description provided for @timeReport.
  ///
  /// In en, this message translates to:
  /// **'Hours / Time report'**
  String get timeReport;

  /// No description provided for @chooseWorkedDays.
  ///
  /// In en, this message translates to:
  /// **'Choose worked days'**
  String get chooseWorkedDays;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @activities.
  ///
  /// In en, this message translates to:
  /// **'Activities'**
  String get activities;

  /// No description provided for @unreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String unreadCount(int count);

  /// No description provided for @markAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllRead;

  /// No description provided for @noActivityYet.
  ///
  /// In en, this message translates to:
  /// **'No activity yet.'**
  String get noActivityYet;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} min ago'**
  String minutesAgo(int count);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} h ago'**
  String hoursAgo(int count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count} d ago'**
  String daysAgo(int count);

  /// No description provided for @aiOverdueConfirmations.
  ///
  /// In en, this message translates to:
  /// **'AI insight: You missed the 7-day confirmation window for {count, plural, =1{1 shift} other{{count} shifts}}. Ask your manager to review.'**
  String aiOverdueConfirmations(int count);

  /// No description provided for @aiPendingConfirmations.
  ///
  /// In en, this message translates to:
  /// **'AI insight: {count, plural, =1{1 completed shift is} other{{count} completed shifts are}} waiting for confirmation. Confirm within 7 days of each shift.'**
  String aiPendingConfirmations(int count);

  /// No description provided for @aiNoAssignedShifts.
  ///
  /// In en, this message translates to:
  /// **'AI insight: No assigned shifts in this range yet. Widen the date range to check other days.'**
  String get aiNoAssignedShifts;

  /// No description provided for @aiScheduledNoneCompleted.
  ///
  /// In en, this message translates to:
  /// **'AI insight: You have {hours} scheduled hours in this range, but none completed yet.'**
  String aiScheduledNoneCompleted(String hours);

  /// No description provided for @aiAllHoursCompleted.
  ///
  /// In en, this message translates to:
  /// **'AI insight: Great consistency. All scheduled hours in this range are completed.'**
  String get aiAllHoursCompleted;

  /// No description provided for @aiHoursProgress.
  ///
  /// In en, this message translates to:
  /// **'AI insight: {completed}h completed, {remaining}h remaining, with {breakHours}h break time scheduled.'**
  String aiHoursProgress(String completed, String remaining, String breakHours);

  /// No description provided for @shifts.
  ///
  /// In en, this message translates to:
  /// **'Shifts'**
  String get shifts;

  /// No description provided for @absence.
  ///
  /// In en, this message translates to:
  /// **'Absence'**
  String get absence;

  /// No description provided for @information.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @noUpcomingShifts.
  ///
  /// In en, this message translates to:
  /// **'No upcoming shifts yet'**
  String get noUpcomingShifts;

  /// No description provided for @noShiftsRightNow.
  ///
  /// In en, this message translates to:
  /// **'No shifts right now'**
  String get noShiftsRightNow;

  /// No description provided for @shiftConfirmations.
  ///
  /// In en, this message translates to:
  /// **'Shift confirmations'**
  String get shiftConfirmations;

  /// No description provided for @confirmWithinSevenDays.
  ///
  /// In en, this message translates to:
  /// **'Confirm completed shifts within 7 days.'**
  String get confirmWithinSevenDays;

  /// No description provided for @confirming.
  ///
  /// In en, this message translates to:
  /// **'Confirming...'**
  String get confirming;

  /// No description provided for @confirmWorked.
  ///
  /// In en, this message translates to:
  /// **'Confirm worked'**
  String get confirmWorked;

  /// No description provided for @confirmedOn.
  ///
  /// In en, this message translates to:
  /// **'Confirmed {date}'**
  String confirmedOn(String date);

  /// No description provided for @confirmWorkedQuestion.
  ///
  /// In en, this message translates to:
  /// **'Confirm worked shift?'**
  String get confirmWorkedQuestion;

  /// No description provided for @confirmAttestation.
  ///
  /// In en, this message translates to:
  /// **'I confirm that I worked this shift as scheduled.'**
  String get confirmAttestation;

  /// No description provided for @shiftId.
  ///
  /// In en, this message translates to:
  /// **'Shift ID {id}'**
  String shiftId(String id);

  /// No description provided for @shiftIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Shift ID'**
  String get shiftIdLabel;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @shiftConfirmedAsWorked.
  ///
  /// In en, this message translates to:
  /// **'Shift confirmed as worked.'**
  String get shiftConfirmedAsWorked;

  /// No description provided for @shiftConfirmationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not confirm this shift. Please try again.'**
  String get shiftConfirmationFailed;

  /// No description provided for @inbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inbox;

  /// No description provided for @unreadWithCount.
  ///
  /// In en, this message translates to:
  /// **'Unread {count}'**
  String unreadWithCount(int count);

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @audience.
  ///
  /// In en, this message translates to:
  /// **'Audience'**
  String get audience;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @managers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get managers;

  /// No description provided for @contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contacts;

  /// No description provided for @noManagerContactsYet.
  ///
  /// In en, this message translates to:
  /// **'No manager contacts yet'**
  String get noManagerContactsYet;

  /// No description provided for @writeMessage.
  ///
  /// In en, this message translates to:
  /// **'Write message'**
  String get writeMessage;

  /// No description provided for @whatIsThisAbout.
  ///
  /// In en, this message translates to:
  /// **'What is this about?'**
  String get whatIsThisAbout;

  /// No description provided for @sendDirectlyToManagers.
  ///
  /// In en, this message translates to:
  /// **'Send directly to your managers.'**
  String get sendDirectlyToManagers;

  /// No description provided for @sendPrivateTextToManagers.
  ///
  /// In en, this message translates to:
  /// **'Send a private text to managers.'**
  String get sendPrivateTextToManagers;

  /// No description provided for @writeYourMessage.
  ///
  /// In en, this message translates to:
  /// **'Write your message...'**
  String get writeYourMessage;

  /// No description provided for @sendPrivateText.
  ///
  /// In en, this message translates to:
  /// **'Send private text'**
  String get sendPrivateText;

  /// No description provided for @postedToTeamHub.
  ///
  /// In en, this message translates to:
  /// **'Posted to team hub.'**
  String get postedToTeamHub;

  /// No description provided for @messageSentToManager.
  ///
  /// In en, this message translates to:
  /// **'Message sent to your manager.'**
  String get messageSentToManager;

  /// No description provided for @couldNotPost.
  ///
  /// In en, this message translates to:
  /// **'Could not post. Retry sync and try again.'**
  String get couldNotPost;

  /// No description provided for @teamUpdatesReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Team updates are read-only on this plan.'**
  String get teamUpdatesReadOnly;

  /// No description provided for @postHubComment.
  ///
  /// In en, this message translates to:
  /// **'Post hub comment'**
  String get postHubComment;

  /// No description provided for @comments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet. Add the first one so the whole team can see it.'**
  String get noCommentsYet;

  /// No description provided for @whatShouldTeamTrack.
  ///
  /// In en, this message translates to:
  /// **'What should the team track?'**
  String get whatShouldTeamTrack;

  /// No description provided for @postEveryoneCanSee.
  ///
  /// In en, this message translates to:
  /// **'Post so everyone can see and comment.'**
  String get postEveryoneCanSee;

  /// No description provided for @hubCommentInfo.
  ///
  /// In en, this message translates to:
  /// **'This comment stays in the public Team Hub thread so everyone works from the same record.'**
  String get hubCommentInfo;

  /// No description provided for @addHubComment.
  ///
  /// In en, this message translates to:
  /// **'Add a hub comment for your team...'**
  String get addHubComment;

  /// No description provided for @postComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get postComment;

  /// No description provided for @postToHub.
  ///
  /// In en, this message translates to:
  /// **'Post to hub'**
  String get postToHub;

  /// No description provided for @noHubPostsYet.
  ///
  /// In en, this message translates to:
  /// **'No hub posts yet'**
  String get noHubPostsYet;

  /// No description provided for @noHubPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Post an update or comment when the whole team should see it.'**
  String get noHubPostsSubtitle;

  /// No description provided for @teamUpdateFallback.
  ///
  /// In en, this message translates to:
  /// **'Team update'**
  String get teamUpdateFallback;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @noUnreadMessages.
  ///
  /// In en, this message translates to:
  /// **'No unread messages'**
  String get noUnreadMessages;

  /// No description provided for @noSentMessages.
  ///
  /// In en, this message translates to:
  /// **'No sent messages'**
  String get noSentMessages;

  /// No description provided for @you.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// No description provided for @sentMessage.
  ///
  /// In en, this message translates to:
  /// **'Sent message'**
  String get sentMessage;

  /// No description provided for @messageFrom.
  ///
  /// In en, this message translates to:
  /// **'Message from {name}'**
  String messageFrom(String name);

  /// No description provided for @reply.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @activityShiftPublished.
  ///
  /// In en, this message translates to:
  /// **'Shift published'**
  String get activityShiftPublished;

  /// No description provided for @openShiftsThisWeek.
  ///
  /// In en, this message translates to:
  /// **'Open shifts this week'**
  String get openShiftsThisWeek;

  /// No description provided for @chooseScheduleDate.
  ///
  /// In en, this message translates to:
  /// **'Choose schedule date'**
  String get chooseScheduleDate;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfile;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get chooseFromGallery;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumber;

  /// No description provided for @jobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job title'**
  String get jobTitle;

  /// No description provided for @extraInformation.
  ///
  /// In en, this message translates to:
  /// **'Extra information'**
  String get extraInformation;

  /// No description provided for @workplaceManagesExtraInfo.
  ///
  /// In en, this message translates to:
  /// **'Emergency contact, certificates, and employment notes are managed by your workplace.'**
  String get workplaceManagesExtraInfo;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved.'**
  String get profileSaved;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @validProfileRequired.
  ///
  /// In en, this message translates to:
  /// **'Add first name, last name, and a valid email.'**
  String get validProfileRequired;

  /// No description provided for @imageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'Image is too large. Choose a smaller photo.'**
  String get imageTooLarge;

  /// No description provided for @imagePickFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not pick image. Please try again.'**
  String get imagePickFailed;

  /// No description provided for @awaitingConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get awaitingConfirmation;

  /// No description provided for @confirmationOverdue.
  ///
  /// In en, this message translates to:
  /// **'Confirmation overdue'**
  String get confirmationOverdue;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @confirmBy.
  ///
  /// In en, this message translates to:
  /// **'Confirm by {date}'**
  String confirmBy(String date);

  /// No description provided for @managerReviewRequired.
  ///
  /// In en, this message translates to:
  /// **'Manager review required'**
  String get managerReviewRequired;

  /// No description provided for @aiPendingConfirmationReminder.
  ///
  /// In en, this message translates to:
  /// **'AI insight: {count, plural, =1{1 completed shift is} other{{count} completed shifts are}} waiting for confirmation. The oldest must be confirmed {days, plural, =0{today} =1{within 1 day} other{within {days} days}}.'**
  String aiPendingConfirmationReminder(int count, int days);

  /// No description provided for @requestAbsence.
  ///
  /// In en, this message translates to:
  /// **'Request absence'**
  String get requestAbsence;

  /// No description provided for @absenceRequestHelp.
  ///
  /// In en, this message translates to:
  /// **'Send vacation, sick leave, or other time off.'**
  String get absenceRequestHelp;

  /// No description provided for @pendingAbsenceRequests.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request waiting for review} other{{count} requests waiting for review}}'**
  String pendingAbsenceRequests(int count);

  /// No description provided for @reason.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reason;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @optionalManagerMessage.
  ///
  /// In en, this message translates to:
  /// **'Optional message for your manager'**
  String get optionalManagerMessage;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @sending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get sending;

  /// No description provided for @requests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// No description provided for @noAbsenceRequestsYet.
  ///
  /// In en, this message translates to:
  /// **'No absence requests yet.'**
  String get noAbsenceRequestsYet;

  /// No description provided for @endDateAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End date must be after start date.'**
  String get endDateAfterStart;

  /// No description provided for @absenceRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Absence request sent.'**
  String get absenceRequestSent;

  /// No description provided for @absenceRequestsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Absence requests are not available for this workplace yet.'**
  String get absenceRequestsUnavailable;

  /// No description provided for @sessionCannotSendRequest.
  ///
  /// In en, this message translates to:
  /// **'Your session cannot send this request. Sign in again and retry.'**
  String get sessionCannotSendRequest;

  /// No description provided for @connectionFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Could not reach ShaqoNet. Check your connection and try again.'**
  String get connectionFailedRetry;

  /// No description provided for @absenceRequestFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send request. Pull to refresh and try again.'**
  String get absenceRequestFailed;

  /// No description provided for @vacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get vacation;

  /// No description provided for @sickLeave.
  ///
  /// In en, this message translates to:
  /// **'Sick leave'**
  String get sickLeave;

  /// No description provided for @parentalLeave.
  ///
  /// In en, this message translates to:
  /// **'Parental leave'**
  String get parentalLeave;

  /// No description provided for @otherAbsence.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherAbsence;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @approved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// No description provided for @denied.
  ///
  /// In en, this message translates to:
  /// **'Denied'**
  String get denied;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'so', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'so':
      return AppLocalizationsSo();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
