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
  String get signingIn => 'Waa la galayaa...';

  @override
  String get forgotPassword => 'Ma illowday furaha sirta ah?';

  @override
  String get validEmailRequired => 'Fadlan geli iimayl sax ah.';

  @override
  String get passwordMinLength =>
      'Furaha sirta ahi waa inuu ugu yaraan 6 xaraf noqdaa.';

  @override
  String get signInGenericError =>
      'Lama geli karin. Hubi iimaylka iyo furaha sirta ah.';

  @override
  String get serverUnreachable =>
      'Server-ka ShaqoNet lama gaari karo. Fadlan mar kale isku day.';

  @override
  String signInFailedWithStatus(int status) {
    return 'Gelitaanka wuu fashilmay ($status). Fadlan mar kale isku day.';
  }

  @override
  String get resetPassword => 'Dib u dejin furaha sirta ah';

  @override
  String get resetPasswordHelp =>
      'Geli iimaylka koontadaada, waxaan kuu diri doonaa xiriir ammaan ah oo furaha lagu beddelo.';

  @override
  String get sendResetLink => 'Dir xiriirka beddelka';

  @override
  String get passwordResetSent =>
      'Iimaylka beddelka furaha waa la diray. Hubi sanduuqaaga.';

  @override
  String get passwordResetFailed =>
      'Iimaylka beddelka lama diri karin. Mar kale isku day.';

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
  String get location => 'Goobta';

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
  String get noShiftsRightNow => 'Hadda shaqo ma jirto';

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
  String shiftId(String id) {
    return 'Aqoonsiga shaqada $id';
  }

  @override
  String get shiftIdLabel => 'Aqoonsiga shaqada';

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
  String get noManagerContactsYet => 'Weli xiriirrada maamulayaasha lama hayo';

  @override
  String get writeMessage => 'Qor farriin';

  @override
  String get whatIsThisAbout => 'Farriintani maxay ku saabsan tahay?';

  @override
  String get sendDirectlyToManagers => 'Si gaar ah ugu dir maamulayaashaada.';

  @override
  String get sendPrivateTextToManagers =>
      'Farriin gaar ah ugu dir maamulayaasha.';

  @override
  String get writeYourMessage => 'Farriintaada qor...';

  @override
  String get sendPrivateText => 'Dir farriin gaar ah';

  @override
  String get postedToTeamHub => 'Waxaa lagu qoray xarunta kooxda.';

  @override
  String get messageSentToManager => 'Farriinta waxaa loo diray maamulahaaga.';

  @override
  String get couldNotPost =>
      'Lama diri karin. Cusboonaysii kadib mar kale isku day.';

  @override
  String get teamUpdatesReadOnly =>
      'Cusboonaysiinta kooxda qorshahan waa akhris keliya.';

  @override
  String get postHubComment => 'Ku qor faallo xarunta kooxda';

  @override
  String get comments => 'Faallooyin';

  @override
  String get noCommentsYet =>
      'Weli faallooyin ma jiraan. Ku dar ta ugu horreysa si kooxda oo dhan u aragto.';

  @override
  String get whatShouldTeamTrack => 'Maxay kooxdu la socotaa?';

  @override
  String get postEveryoneCanSee => 'Ku qor si qof walba u arko una faalloodo.';

  @override
  String get hubCommentInfo =>
      'Faalladani waxay ku jiraysaa xarunta guud ee kooxda si qof walba uga shaqeeyo xog isku mid ah.';

  @override
  String get addHubComment => 'Kooxdaada u qor faallo...';

  @override
  String get postComment => 'Dir faallo';

  @override
  String get postToHub => 'Ku qor xarunta';

  @override
  String get noHubPostsYet => 'Weli qoraallo xarunta kooxda ma jiraan';

  @override
  String get noHubPostsSubtitle =>
      'Qor cusboonaysiin ama faallo marka kooxda oo dhan ay u baahan tahay inay aragto.';

  @override
  String get teamUpdateFallback => 'Cusboonaysiin kooxeed';

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
  String get activityShiftPublished => 'Shaqada waa la daabacay';

  @override
  String get openShiftsThisWeek => 'Shaqooyinka furan ee toddobaadkan';

  @override
  String get chooseScheduleDate => 'Dooro taariikhda jadwalka';

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

  @override
  String get requestAbsence => 'Codso maqnaansho';

  @override
  String get absenceRequestHelp =>
      'Codso fasax, xanuun, ama waqti kale oo shaqada laga maqnaado.';

  @override
  String pendingAbsenceRequests(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count codsi ayaa sugaya hubin',
      one: '1 codsi ayaa sugaya hubin',
    );
    return '$_temp0';
  }

  @override
  String get reason => 'Sababta';

  @override
  String get start => 'Bilow';

  @override
  String get end => 'Dhammaad';

  @override
  String get note => 'Qoraal';

  @override
  String get optionalManagerMessage =>
      'Farriin ikhtiyaari ah oo maamulaha loo diro';

  @override
  String get sendRequest => 'Dir codsiga';

  @override
  String get sending => 'Waa la dirayaa...';

  @override
  String get requests => 'Codsiyada';

  @override
  String get noAbsenceRequestsYet => 'Weli codsiyo maqnaansho ma jiraan.';

  @override
  String get endDateAfterStart =>
      'Taariikhda dhammaadka waa inay ka dambaysaa taariikhda bilowga.';

  @override
  String get absenceRequestSent => 'Codsiga maqnaanshaha waa la diray.';

  @override
  String get absenceRequestsUnavailable =>
      'Codsiyada maqnaanshaha weli goobtan shaqo looma diyaarin.';

  @override
  String get sessionCannotSendRequest =>
      'Kalfadhigaagu codsigan ma diri karo. Mar kale gal oo isku day.';

  @override
  String get connectionFailedRetry =>
      'ShaqoNet lama gaari karo. Hubi internetkaaga oo mar kale isku day.';

  @override
  String get absenceRequestFailed =>
      'Codsiga lama diri karin. Soo jiid si aad u cusboonaysiiso oo mar kale isku day.';

  @override
  String get vacation => 'Fasax';

  @override
  String get sickLeave => 'Fasax xanuun';

  @override
  String get parentalLeave => 'Fasax waalidnimo';

  @override
  String get otherAbsence => 'Kale';

  @override
  String get pending => 'Sugaya';

  @override
  String get approved => 'La oggolaaday';

  @override
  String get denied => 'La diiday';
}
