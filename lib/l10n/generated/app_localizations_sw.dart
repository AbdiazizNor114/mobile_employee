// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String get appTitle => 'ShaqoNet';

  @override
  String get loginTitle => 'Kazi yangu';

  @override
  String get loginSubtitle =>
      'Ingia uone ratiba, shughuli, saa na rekodi zako za kazi.';

  @override
  String get email => 'Barua pepe';

  @override
  String get password => 'Nenosiri';

  @override
  String get signIn => 'Ingia';

  @override
  String get demoMode => 'Hali ya majaribio';

  @override
  String get home => 'Mwanzo';

  @override
  String get schedule => 'Ratiba';

  @override
  String get activity => 'Shughuli';

  @override
  String get messages => 'Ujumbe';

  @override
  String get hub => 'Mazungumzo ya timu';

  @override
  String get hours => 'Saa';

  @override
  String get profile => 'Wasifu';

  @override
  String get nextShift => 'Zamu inayofuata';

  @override
  String get upcomingShifts => 'Zamu zijazo';

  @override
  String get availableShifts => 'Zamu zilizo wazi';

  @override
  String get weeklySchedule => 'Ratiba ya wiki';

  @override
  String get activityFeed => 'Shughuli za kazi';

  @override
  String get totalHours => 'Jumla ya saa';

  @override
  String get timeSummary => 'Muhtasari wa saa';

  @override
  String get breakTime => 'Muda wa mapumziko';

  @override
  String get aiInsight => 'Ushauri wa kazi';

  @override
  String get language => 'Lugha';

  @override
  String get employmentCertificate => 'Cheti cha ajira';

  @override
  String get downloadPlaceholder =>
      'Wasiliana na mwajiri wako ili kupata hati hii';

  @override
  String get logout => 'Toka';

  @override
  String get offlineReady => 'Taarifa za kazi zimehifadhiwa';

  @override
  String get lastUpdated => 'Imesasishwa sasa hivi';

  @override
  String get role => 'Wajibu';

  @override
  String get phone => 'Simu';

  @override
  String get company => 'Kampuni';

  @override
  String get notProvided => 'Haijawekwa';

  @override
  String get preferences => 'Mapendeleo';

  @override
  String get appLanguage => 'Lugha ya programu';

  @override
  String get englishName => 'Kiingereza';

  @override
  String get somaliName => 'Kisomali';

  @override
  String get swahiliName => 'Kiswahili';

  @override
  String get documents => 'Hati';

  @override
  String get employmentDocumentsManaged =>
      'Hati za ajira zinasimamiwa na mahali pako pa kazi.';

  @override
  String get all => 'Zote';

  @override
  String get confirmed => 'Zimethibitishwa';

  @override
  String get open => 'Wazi';

  @override
  String get openShift => 'Zamu wazi';

  @override
  String get changed => 'Imebadilishwa';

  @override
  String get thisWeek => 'Wiki hii';

  @override
  String shiftsFor(String date) {
    return 'Zamu za $date';
  }

  @override
  String shiftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zamu $count',
      one: 'Zamu moja',
      zero: 'Hakuna zamu',
    );
    return '$_temp0';
  }

  @override
  String get noShiftsMatch =>
      'Hakuna zamu zinazolingana na kichujio hiki kwa sasa.';

  @override
  String get date => 'Tarehe';

  @override
  String get time => 'Saa';

  @override
  String get duration => 'Muda wa zamu';

  @override
  String get notes => 'Maelezo';

  @override
  String get openShiftNote =>
      'Zamu iko wazi. Ukiikubali, msimamizi ataarifiwa.';

  @override
  String get noManagerNote => 'Msimamizi hajaweka maelezo kwa zamu hii.';

  @override
  String get acceptOpenShift => 'Kubali zamu iliyo wazi';

  @override
  String get accepting => 'Inakubaliwa...';

  @override
  String get shiftUnavailable => 'Zamu haipatikani tena';

  @override
  String get alreadyAssigned => 'Tayari umepangiwa';

  @override
  String get shiftAccepted =>
      'Zamu imekubaliwa na kuongezwa kwenye ratiba yako.';

  @override
  String get shiftAcceptFailed =>
      'Zamu haikuweza kukubaliwa. Tafadhali jaribu tena.';

  @override
  String hoursAndBreak(String hours, int minutes) {
    return 'Saa $hours, mapumziko dakika $minutes';
  }

  @override
  String get dateRange => 'Kipindi cha tarehe';

  @override
  String get change => 'Badilisha';

  @override
  String get thisMonth => 'Mwezi huu';

  @override
  String get lastSevenDays => 'Siku 7 zilizopita';

  @override
  String get totalShiftHours => 'Jumla ya saa za zamu';

  @override
  String get workDays => 'Siku za kazi';

  @override
  String get averageShiftLength => 'Wastani wa muda wa zamu';

  @override
  String get timeBalance => 'Hesabu ya muda';

  @override
  String get bookedDays => 'Siku zilizopangwa';

  @override
  String get noBookedShifts => 'Hakuna zamu zilizopangwa katika kipindi hiki';

  @override
  String get timeReport => 'Ripoti ya saa';

  @override
  String get chooseWorkedDays => 'Chagua siku za kazi';

  @override
  String get apply => 'Tumia';

  @override
  String get activities => 'Shughuli';

  @override
  String unreadCount(int count) {
    return '$count hazijasomwa';
  }

  @override
  String get markAllRead => 'Weka zote kama zimesomwa';

  @override
  String get noActivityYet => 'Bado hakuna shughuli.';

  @override
  String get justNow => 'Sasa hivi';

  @override
  String minutesAgo(int count) {
    return 'Dakika $count zilizopita';
  }

  @override
  String hoursAgo(int count) {
    return 'Saa $count zilizopita';
  }

  @override
  String daysAgo(int count) {
    return 'Siku $count zilizopita';
  }

  @override
  String aiOverdueConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'zamu $count',
      one: 'zamu moja',
    );
    return 'Ushauri wa kazi: Umepitisha muda wa siku 7 wa kuthibitisha $_temp0. Wasiliana na msimamizi wako.';
  }

  @override
  String aiPendingConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zamu $count zilizokamilika zinasubiri',
      one: 'Zamu moja iliyokamilika inasubiri',
    );
    return 'Ushauri wa kazi: $_temp0 uthibitisho. Thibitisha kila zamu ndani ya siku 7.';
  }

  @override
  String get aiNoAssignedShifts =>
      'Ushauri wa kazi: Hakuna zamu iliyopangwa katika kipindi hiki. Badilisha kipindi cha tarehe ili uangalie siku nyingine.';

  @override
  String aiScheduledNoneCompleted(String hours) {
    return 'Ushauri wa kazi: Umepangiwa saa $hours katika kipindi hiki, lakini bado hakuna iliyokamilika.';
  }

  @override
  String get aiAllHoursCompleted =>
      'Ushauri wa kazi: Umefanya vizuri. Saa zote zilizopangwa katika kipindi hiki zimekamilika.';

  @override
  String aiHoursProgress(
      String completed, String remaining, String breakHours) {
    return 'Ushauri wa kazi: Saa $completed zimekamilika, saa $remaining zimebaki, na mapumziko yamepangwa kwa saa $breakHours.';
  }

  @override
  String get shifts => 'Zamu';

  @override
  String get absence => 'Kutokuwepo';

  @override
  String get information => 'Taarifa';

  @override
  String get noUpcomingShifts => 'Bado hakuna zamu zijazo';

  @override
  String get shiftConfirmations => 'Uthibitisho wa zamu';

  @override
  String get confirmWithinSevenDays =>
      'Thibitisha zamu zilizokamilika ndani ya siku 7.';

  @override
  String get confirming => 'Inathibitishwa...';

  @override
  String get confirmWorked => 'Thibitisha kuwa nilifanya kazi';

  @override
  String confirmedOn(String date) {
    return 'Imethibitishwa $date';
  }

  @override
  String get confirmWorkedQuestion => 'Unathibitisha zamu hii?';

  @override
  String get confirmAttestation =>
      'Ninathibitisha kuwa nilifanya zamu hii kama ilivyopangwa.';

  @override
  String get cancel => 'Ghairi';

  @override
  String get shiftConfirmedAsWorked => 'Zamu imethibitishwa kuwa imefanywa.';

  @override
  String get shiftConfirmationFailed =>
      'Zamu haikuweza kuthibitishwa. Tafadhali jaribu tena.';

  @override
  String get inbox => 'Kikasha';

  @override
  String unreadWithCount(int count) {
    return 'Hazijasomwa $count';
  }

  @override
  String get sent => 'Zilizotumwa';

  @override
  String get subject => 'Kichwa';

  @override
  String get audience => 'Wapokeaji';

  @override
  String get message => 'Ujumbe';

  @override
  String get managers => 'Wasimamizi';

  @override
  String get contacts => 'Mawasiliano';

  @override
  String get writeMessage => 'Andika ujumbe';

  @override
  String get whatIsThisAbout => 'Ujumbe huu unahusu nini?';

  @override
  String get sendDirectlyToManagers =>
      'Tuma moja kwa moja kwa wasimamizi wako.';

  @override
  String get writeYourMessage => 'Andika ujumbe wako...';

  @override
  String get sendPrivateText => 'Tuma ujumbe binafsi';

  @override
  String get noMessagesYet => 'Bado hakuna ujumbe';

  @override
  String get noUnreadMessages => 'Hakuna ujumbe ambao haujasomwa';

  @override
  String get noSentMessages => 'Hakuna ujumbe uliotumwa';

  @override
  String get you => 'Wewe';

  @override
  String get sentMessage => 'Ujumbe uliotumwa';

  @override
  String messageFrom(String name) {
    return 'Ujumbe kutoka kwa $name';
  }

  @override
  String get reply => 'Jibu';

  @override
  String get comment => 'Maoni';

  @override
  String get editProfile => 'Hariri wasifu';

  @override
  String get chooseFromGallery => 'Chagua kutoka kwenye picha';

  @override
  String get remove => 'Ondoa';

  @override
  String get firstName => 'Jina la kwanza';

  @override
  String get lastName => 'Jina la mwisho';

  @override
  String get phoneNumber => 'Nambari ya simu';

  @override
  String get jobTitle => 'Cheo cha kazi';

  @override
  String get extraInformation => 'Taarifa za ziada';

  @override
  String get workplaceManagesExtraInfo =>
      'Mawasiliano ya dharura, vyeti na maelezo ya ajira yanasimamiwa na mahali pako pa kazi.';

  @override
  String get saveProfile => 'Hifadhi wasifu';

  @override
  String get profileSaved => 'Wasifu umehifadhiwa.';

  @override
  String get profileSaveFailed =>
      'Wasifu haukuweza kuhifadhiwa. Tafadhali jaribu tena.';

  @override
  String get validProfileRequired =>
      'Weka jina la kwanza, jina la mwisho na barua pepe sahihi.';

  @override
  String get imageTooLarge => 'Picha ni kubwa sana. Chagua picha ndogo zaidi.';

  @override
  String get imagePickFailed =>
      'Picha haikuweza kuchaguliwa. Tafadhali jaribu tena.';
}
