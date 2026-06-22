// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppLocalizationsSo extends AppLocalizations {
  AppLocalizationsSo([String locale = 'so']) : super(locale);

  @override
  String get appTitle => 'ShaqoNet';

  @override
  String get loginTitle => 'Shaqadayda';

  @override
  String get loginSubtitle =>
      'Gal si aad u aragto jadwalka, hawsha, saacadaha, iyo diiwaankaaga shaqo.';

  @override
  String get email => 'Iimayl';

  @override
  String get password => 'Furaha sirta ah';

  @override
  String get signIn => 'Gal';

  @override
  String get demoMode => 'Tijaabo';

  @override
  String get home => 'Bogga hore';

  @override
  String get schedule => 'Jadwalka';

  @override
  String get activity => 'Hawlaha';

  @override
  String get messages => 'Farriimaha';

  @override
  String get hub => 'Wadahadalka kooxda';

  @override
  String get hours => 'Saacado';

  @override
  String get profile => 'Xogtayda';

  @override
  String get nextShift => 'Shaqada xigta';

  @override
  String get upcomingShifts => 'Shaqooyinka soo socda';

  @override
  String get availableShifts => 'Shaqooyin bannaan';

  @override
  String get weeklySchedule => 'Jadwal toddobaadle';

  @override
  String get activityFeed => 'Dhaqdhaqaaqyada shaqada';

  @override
  String get totalHours => 'Wadarta saacadaha';

  @override
  String get timeSummary => 'Warbixinta saacadaha';

  @override
  String get breakTime => 'Waqtiga nasashada';

  @override
  String get aiInsight => 'Talo shaqo';

  @override
  String get language => 'Luqad';

  @override
  String get employmentCertificate => 'Shahaado shaqo';

  @override
  String get downloadPlaceholder =>
      'La xiriir goobtaada shaqada si aad dukumentigan u hesho';

  @override
  String get logout => 'Ka bax';

  @override
  String get offlineReady => 'Xogta shaqada waa la kaydiyay';

  @override
  String get lastUpdated => 'Hadda la cusboonaysiiyay';

  @override
  String get role => 'Doorka';

  @override
  String get phone => 'Telefoon';

  @override
  String get company => 'Shirkadda';

  @override
  String get notProvided => 'Lama gelin';

  @override
  String get preferences => 'Doorashooyinka';

  @override
  String get appLanguage => 'Luqadda app-ka';

  @override
  String get englishName => 'Ingiriisi';

  @override
  String get somaliName => 'Soomaali';

  @override
  String get swahiliName => 'Sawaaxili';

  @override
  String get documents => 'Dukumentiyada';

  @override
  String get employmentDocumentsManaged =>
      'Dukumentiyada shaqada waxaa maamusha goobtaada shaqada.';

  @override
  String get all => 'Dhammaan';

  @override
  String get confirmed => 'La xaqiijiyay';

  @override
  String get open => 'Bannaan';

  @override
  String get openShift => 'Shaqo bannaan';

  @override
  String get changed => 'La beddelay';

  @override
  String get thisWeek => 'Toddobaadkan';

  @override
  String shiftsFor(String date) {
    return 'Shaqooyinka $date';
  }

  @override
  String shiftCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shaqo',
      one: '1 shaqo',
      zero: 'Shaqo ma jirto',
    );
    return '$_temp0';
  }

  @override
  String get noShiftsMatch => 'Ma jiraan shaqooyin ku habboon doorashadan.';

  @override
  String get date => 'Taariikhda';

  @override
  String get time => 'Waqtiga';

  @override
  String get duration => 'Muddada';

  @override
  String get notes => 'Faahfaahin';

  @override
  String get openShiftNote =>
      'Shaqo bannaan. Markaad qaadato, maamulaha waa la ogeysiinayaa.';

  @override
  String get noManagerNote => 'Maamuluhu faahfaahin kuma darin shaqadan.';

  @override
  String get acceptOpenShift => 'Qaado shaqadan bannaan';

  @override
  String get accepting => 'Waa la qaadayaa...';

  @override
  String get shiftUnavailable => 'Shaqadan mar dambe lama heli karo';

  @override
  String get alreadyAssigned => 'Hore ayaa laguugu qoray';

  @override
  String get shiftAccepted =>
      'Shaqada waa laguu qoray waxaana lagu daray jadwalkaaga.';

  @override
  String get shiftAcceptFailed =>
      'Shaqada lama qaadan karin. Fadlan mar kale isku day.';

  @override
  String hoursAndBreak(String hours, int minutes) {
    return '$hours saac, nasasho $minutes daqiiqo';
  }

  @override
  String get dateRange => 'Muddada taariikhda';

  @override
  String get change => 'Beddel';

  @override
  String get thisMonth => 'Bishan';

  @override
  String get lastSevenDays => '7-dii maalmood ee u dambeysay';

  @override
  String get totalShiftHours => 'Wadarta saacadaha shaqada';

  @override
  String get workDays => 'Maalmaha shaqada';

  @override
  String get averageShiftLength => 'Celceliska muddada shaqada';

  @override
  String get timeBalance => 'Isugeynta waqtiga';

  @override
  String get bookedDays => 'Maalmaha la qorsheeyay';

  @override
  String get noBookedShifts => 'Muddadan shaqo laguma qorin';

  @override
  String get timeReport => 'Warbixinta saacadaha';

  @override
  String get chooseWorkedDays => 'Dooro maalmaha shaqada';

  @override
  String get apply => 'Ku dabaq';

  @override
  String get activities => 'Hawlaha';

  @override
  String unreadCount(int count) {
    return '$count aan la akhriyin';
  }

  @override
  String get markAllRead => 'Dhammaan akhri';

  @override
  String get noActivityYet => 'Weli wax hawl ah ma jiraan.';

  @override
  String get justNow => 'Hadda';

  @override
  String minutesAgo(int count) {
    return '$count daqiiqo ka hor';
  }

  @override
  String hoursAgo(int count) {
    return '$count saac ka hor';
  }

  @override
  String daysAgo(int count) {
    return '$count maalmood ka hor';
  }

  @override
  String aiOverdueConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shaqo',
      one: '1 shaqo',
    );
    return 'Talo shaqo: Waxaad dhaaftay 7-dii maalmood ee xaqiijinta $_temp0. Maamulahaaga la xiriir.';
  }

  @override
  String aiPendingConfirmations(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shaqo oo dhammaatay ayaa',
      one: '1 shaqo oo dhammaatay ayaa',
    );
    return 'Talo shaqo: $_temp0 sugaysa xaqiijin. Shaqo kasta ku xaqiiji 7 maalmood gudahood.';
  }

  @override
  String get aiNoAssignedShifts =>
      'Talo shaqo: Muddadan shaqo laguma qorin. Beddel muddada taariikhda si aad maalmo kale u hubiso.';

  @override
  String aiScheduledNoneCompleted(String hours) {
    return 'Talo shaqo: Muddadan waxaa laguu qorsheeyay $hours saac, laakiin weli midna ma dhammaan.';
  }

  @override
  String get aiAllHoursCompleted =>
      'Talo shaqo: Aad baad u wanaagsan tahay. Dhammaan saacadaha muddadan waa la dhammaystiray.';

  @override
  String aiHoursProgress(
      String completed, String remaining, String breakHours) {
    return 'Talo shaqo: $completed saac waa dhammaatay, $remaining saac ayaa hadhay, nasashaduna waa $breakHours saac.';
  }

  @override
  String get shifts => 'Shaqooyinka';

  @override
  String get absence => 'Maqnaanshaha';

  @override
  String get information => 'Macluumaadka';

  @override
  String get noUpcomingShifts => 'Weli shaqo soo socota ma jirto';

  @override
  String get shiftConfirmations => 'Xaqiijinta shaqooyinka';

  @override
  String get confirmWithinSevenDays =>
      'Shaqada dhammaatay ku xaqiiji 7 maalmood gudahood.';

  @override
  String get confirming => 'Waa la xaqiijinayaa...';

  @override
  String get confirmWorked => 'Xaqiiji inaan shaqeeyay';

  @override
  String confirmedOn(String date) {
    return 'La xaqiijiyay $date';
  }

  @override
  String get confirmWorkedQuestion => 'Ma xaqiijinaysaa shaqadan?';

  @override
  String get confirmAttestation =>
      'Waxaan xaqiijinayaa inaan shaqadan u shaqeeyay sidii loo qorsheeyay.';

  @override
  String get cancel => 'Jooji';

  @override
  String get shiftConfirmedAsWorked => 'Shaqada waa la xaqiijiyay.';

  @override
  String get shiftConfirmationFailed =>
      'Shaqada lama xaqiijin karin. Fadlan mar kale isku day.';

  @override
  String get inbox => 'Farriimaha soo galay';

  @override
  String unreadWithCount(int count) {
    return 'Aan la akhriyin $count';
  }

  @override
  String get sent => 'La diray';

  @override
  String get subject => 'Cinwaanka';

  @override
  String get audience => 'Cidda loo dirayo';

  @override
  String get message => 'Farriin';

  @override
  String get managers => 'Maamulayaasha';

  @override
  String get contacts => 'Xiriirrada';

  @override
  String get writeMessage => 'Qor farriin';

  @override
  String get whatIsThisAbout => 'Farriintani maxay ku saabsan tahay?';

  @override
  String get sendDirectlyToManagers => 'Si gaar ah ugu dir maamulayaashaada.';

  @override
  String get writeYourMessage => 'Farriintaada qor...';

  @override
  String get sendPrivateText => 'Dir farriin gaar ah';

  @override
  String get noMessagesYet => 'Weli farriimo ma jiraan';

  @override
  String get noUnreadMessages => 'Farriimo aan la akhriyin ma jiraan';

  @override
  String get noSentMessages => 'Farriimo la diray ma jiraan';

  @override
  String get you => 'Adiga';

  @override
  String get sentMessage => 'Farriin la diray';

  @override
  String messageFrom(String name) {
    return 'Farriin ka timid $name';
  }

  @override
  String get reply => 'Ka jawaab';

  @override
  String get comment => 'Faallo';

  @override
  String get editProfile => 'Wax ka beddel xogtayda';

  @override
  String get chooseFromGallery => 'Sawirrada ka dooro';

  @override
  String get remove => 'Ka saar';

  @override
  String get firstName => 'Magaca hore';

  @override
  String get lastName => 'Magaca dambe';

  @override
  String get phoneNumber => 'Lambarka telefoonka';

  @override
  String get jobTitle => 'Jagada shaqada';

  @override
  String get extraInformation => 'Macluumaad dheeraad ah';

  @override
  String get workplaceManagesExtraInfo =>
      'Xiriirka degdegga ah, shahaadooyinka, iyo faahfaahinta shaqada waxaa maamusha goobtaada shaqada.';

  @override
  String get saveProfile => 'Kaydi xogtayda';

  @override
  String get profileSaved => 'Xogtaada waa la kaydiyay.';

  @override
  String get profileSaveFailed =>
      'Xogta lama kaydin karin. Fadlan mar kale isku day.';

  @override
  String get validProfileRequired =>
      'Geli magaca hore, magaca dambe, iyo iimayl sax ah.';

  @override
  String get imageTooLarge =>
      'Sawirku aad buu u weyn yahay. Dooro sawir ka yar.';

  @override
  String get imagePickFailed =>
      'Sawirka lama dooran karin. Fadlan mar kale isku day.';

  @override
  String get awaitingConfirmation => 'Xaqiijin sugaysa';

  @override
  String get confirmationOverdue => 'Xaqiijintu way daahday';

  @override
  String get scheduled => 'La qorsheeyay';

  @override
  String get absent => 'Maqnaa';

  @override
  String confirmBy(String date) {
    return 'Xaqiiji ka hor $date';
  }

  @override
  String get managerReviewRequired => 'Maamuluhu waa inuu hubiyaa';

  @override
  String aiPendingConfirmationReminder(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shaqo oo dhammaatay ayaa',
      one: '1 shaqo oo dhammaatay ayaa',
    );
    String _temp1 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days maalmood gudahood',
      one: '1 maalin gudaheed',
      zero: 'maanta',
    );
    return 'Talo shaqo: $_temp0 sugaysa xaqiijin. Shaqada ugu horreysa waa in la xaqiijiyaa $_temp1.';
  }
}
