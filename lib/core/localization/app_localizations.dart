import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = Intl.canonicalizedLocale(locale);

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ta'),
    Locale('hi'),
    Locale('te'),
    Locale('ml'),
    Locale('kn'),
  ];

  // App Title
  String get appTitle;

  String get landMapping;

  // Navigation
  String get home;

  String get map;

  String get camera;

  String get settings;

  String get profile;

  // GPS & Location
  String get location;

  String get latitude;

  String get longitude;

  String get accuracy;

  String get altitude;

  String get getCurrentLocation;

  String get locationPermissionRequired;

  String get enableLocationServices;

  // Camera & Image
  String get takePhoto;

  String get gallery;

  String get captureImage;

  String get analyzeImage;

  String get imageAnalysis;

  String get cameraPermissionRequired;

  // AI Analysis
  String get analyzing;

  String get analysisComplete;

  String get landFeatures;

  String get vegetation;

  String get waterBodies;

  String get elevation;

  String get soilType;

  // Map & Points
  String get mapView;

  String get addPoint;

  String get savedPoints;

  String get pointDetails;

  String get annotations;

  String get offlineMode;

  // Data Management
  String get save;

  String get export;

  String get delete;

  String get sync;

  String get exportCsv;

  String get exportJson;

  String get exportPdf;

  // General
  String get ok;

  String get cancel;

  String get error;

  String get success;

  String get loading;

  String get noData;

  String get retry;

  // Language & Settings
  String get language;

  String get selectLanguage;

  String get theme;

  String get selectTheme;

  String get darkMode;

  String get about;

  String get languageChanged;

  String get system;

  String get light;

  String get dark;

  // Search and Sort
  String get search;

  String get searchSavedPoints;

  String get sortBy;

  String get date;

  String get name;

  String get ascending;

  String get descending;

  String get close;

  String get deletePoint;

  String get deleteConfirmation;

  String get areYouSureDeletePoint;

  String get pointDeletedSuccessfully;

  String get errorDeletingPoint;

  String get errorLoadingSavedPoints;

  String get noPointsFound;

  String get noSavedPointsYet;

  String get tryAdjustingSearch;

  String get startCapturingPoints;

  String get unnamedPoint;

  String get analysisResults;

  String get landFeature;

  String get vegetationCoverage;

  String get waterCoverage;

  String get elevationEstimate;

  String get confidence;

  String get notes;

  String get useDarkTheme;

  String get landMapVersion;

  String get aiPoweredDescription;

  // Camera
  String get photoCapturedSuccessfully;

  String get errorCapturingPhoto;

  String get imageImportedSuccessfully;

  String get errorImportingImage;

  String get cannotSwitchCamera;

  String get initializingCamera;

  String get cameraNotAvailable;

  String get routeNotFound;

  // Map & Walk Mode
  String get walkMode;

  String get startWalk;

  String get stopWalk;

  String get capturePoint;

  String get walkDistance;

  String get points;

  String get pointsCaptured;

  String get pointCapture;

  String get area;

  String get perimeter;

  String get areaName;

  String get areaNameRequired;

  String get pleaseEnterAreaName;

  String get description;

  String get optional;

  String get capturedPoints;

  String get saveArea;

  String get savingArea;

  String get areaSavedSuccessfully;

  String get walkModeStarted;

  String get walkModeStopped;

  String get highAccuracyGPS;

  String get tapCaptureToAddPoints;

  String get minimumDistance;

  String get distanceWalked;

  String get normalView;

  String get satelliteView;

  String get pointMustBeAway;

  String get moveAtLeast;

  String get fromLastPoint;

  String get pointTooClose;

  String get lowGPSAccuracy;

  String get moveToOpenArea;

  String get gettingBetterGPS;

  String get pointCapturedSuccessfully;

  String get distanceFromLastPoint;

  String get navigatingToPoint;

  String get allPointsCleared;

  String get currentPoints;

  String get pointsAdded;

  String get noPointsCaptured;

  String get clearAll;

  String get viewPoints;

  String get navigateTo;

  String get meters;

  String get squareMeters;

  String get corners;

  String get atLeastThreePoints;

  String get areaSummary;

  String get walkStarted;

  String get unableToDetermineLocation;

  String get gpsError;

  String get pleaseCheckLocationSettings;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'en',
        'ta',
        'hi',
        'te',
        'ml',
        'kn'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ta':
      return AppLocalizationsTa();
    case 'hi':
      return AppLocalizationsHi();
    case 'te':
      return AppLocalizationsTe();
    case 'ml':
      return AppLocalizationsMl();
    case 'kn':
      return AppLocalizationsKn();
    case 'en':
    default:
      return AppLocalizationsEn();
  }
}

class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn() : super('en');

  @override
  String get appTitle => 'Land Mapper';

  @override
  String get landMapping => 'Land Mapping';

  @override
  String get home => 'Home';

  @override
  String get map => 'Map';

  @override
  String get camera => 'Camera';

  @override
  String get settings => 'Settings';

  @override
  String get profile => 'Profile';

  @override
  String get location => 'Location';

  @override
  String get latitude => 'Latitude';

  @override
  String get longitude => 'Longitude';

  @override
  String get accuracy => 'Accuracy';

  @override
  String get altitude => 'Altitude';

  @override
  String get getCurrentLocation => 'Get Current Location';

  @override
  String get locationPermissionRequired => 'Location permission is required';

  @override
  String get enableLocationServices => 'Please enable location services';

  @override
  String get takePhoto => 'Take Photo';

  @override
  String get gallery => 'Gallery';

  @override
  String get captureImage => 'Capture Image';

  @override
  String get analyzeImage => 'Analyze Image';

  @override
  String get imageAnalysis => 'Image Analysis';

  @override
  String get cameraPermissionRequired => 'Camera permission is required';

  @override
  String get analyzing => 'Analyzing...';

  @override
  String get analysisComplete => 'Analysis Complete';

  @override
  String get landFeatures => 'Land Features';

  @override
  String get vegetation => 'Vegetation';

  @override
  String get waterBodies => 'Water Bodies';

  @override
  String get elevation => 'Elevation';

  @override
  String get soilType => 'Soil Type';

  @override
  String get mapView => 'Map View';

  @override
  String get addPoint => 'Add Point';

  @override
  String get savedPoints => 'Saved Points';

  @override
  String get pointDetails => 'Point Details';

  @override
  String get annotations => 'Annotations';

  @override
  String get offlineMode => 'Offline Mode';

  @override
  String get save => 'Save';

  @override
  String get export => 'Export';

  @override
  String get delete => 'Delete';

  @override
  String get sync => 'Sync';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get ok => 'OK';

  @override
  String get cancel => 'Cancel';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get loading => 'Loading...';

  @override
  String get noData => 'No data available';

  @override
  String get retry => 'Retry';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get theme => 'Theme';

  @override
  String get selectTheme => 'Select Theme';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get about => 'About';

  @override
  String get languageChanged => 'Language Changed';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get search => 'Search';

  @override
  String get searchSavedPoints => 'Search Saved Points';

  @override
  String get sortBy => 'Sort By';

  @override
  String get date => 'Date';

  @override
  String get name => 'Name';

  @override
  String get ascending => 'Ascending';

  @override
  String get descending => 'Descending';

  @override
  String get close => 'Close';

  @override
  String get deletePoint => 'Delete Point';

  @override
  String get deleteConfirmation => 'Delete Confirmation';

  @override
  String get areYouSureDeletePoint =>
      'Are you sure you want to delete this point?';

  @override
  String get pointDeletedSuccessfully => 'Point Deleted Successfully';

  @override
  String get errorDeletingPoint => 'Error Deleting Point';

  @override
  String get errorLoadingSavedPoints => 'Error Loading Saved Points';

  @override
  String get noPointsFound => 'No Points Found';

  @override
  String get noSavedPointsYet => 'No Saved Points Yet';

  @override
  String get tryAdjustingSearch => 'Try Adjusting Search';

  @override
  String get startCapturingPoints => 'Start Capturing Points';

  @override
  String get unnamedPoint => 'Unnamed Point';

  @override
  String get analysisResults => 'Analysis Results';

  @override
  String get landFeature => 'Land Feature';

  @override
  String get vegetationCoverage => 'Vegetation Coverage';

  @override
  String get waterCoverage => 'Water Coverage';

  @override
  String get elevationEstimate => 'Elevation Estimate';

  @override
  String get confidence => 'Confidence';

  @override
  String get notes => 'Notes';

  @override
  String get useDarkTheme => 'Use Dark Theme';

  @override
  String get landMapVersion => 'Land Map Version';

  @override
  String get aiPoweredDescription => 'AI Powered Description';

  @override
  String get photoCapturedSuccessfully =>
      'Photo captured and saved successfully!';

  @override
  String get errorCapturingPhoto => 'Error capturing photo';

  @override
  String get imageImportedSuccessfully => 'Image imported successfully!';

  @override
  String get errorImportingImage => 'Error importing image';

  @override
  String get cannotSwitchCamera => 'Cannot switch camera';

  @override
  String get initializingCamera => 'Initializing camera...';

  @override
  String get cameraNotAvailable => 'Camera not available';

  @override
  String get routeNotFound => 'Route not found';

  @override
  String get walkMode => 'Walk Mode';

  @override
  String get startWalk => 'Start Walk';

  @override
  String get stopWalk => 'Stop Walk';

  @override
  String get capturePoint => 'Capture Point';

  @override
  String get walkDistance => 'Walk Distance';

  @override
  String get points => 'Points';

  @override
  String get pointsCaptured => 'Points Captured';

  @override
  String get pointCapture => 'Point Capture';

  @override
  String get area => 'Area';

  @override
  String get perimeter => 'Perimeter';

  @override
  String get areaName => 'Area Name';

  @override
  String get areaNameRequired => 'Area Name Required';

  @override
  String get pleaseEnterAreaName => 'Please enter the area name';

  @override
  String get description => 'Description';

  @override
  String get optional => 'Optional';

  @override
  String get capturedPoints => 'Captured Points';

  @override
  String get saveArea => 'Save Area';

  @override
  String get savingArea => 'Saving Area';

  @override
  String get areaSavedSuccessfully => 'Area saved successfully';

  @override
  String get walkModeStarted => 'Walk mode started';

  @override
  String get walkModeStopped => 'Walk mode stopped';

  @override
  String get highAccuracyGPS => 'High accuracy GPS enabled';

  @override
  String get tapCaptureToAddPoints => 'Tap "Capture" to add points';

  @override
  String get minimumDistance => 'Minimum distance';

  @override
  String get distanceWalked => 'Distance walked';

  @override
  String get normalView => 'Normal View';

  @override
  String get satelliteView => 'Satellite View';

  @override
  String get pointMustBeAway => 'Point must be at least';

  @override
  String get moveAtLeast => 'Move at least';

  @override
  String get fromLastPoint => 'from the last point';

  @override
  String get pointTooClose => 'Point too close to point';

  @override
  String get lowGPSAccuracy => 'Low GPS accuracy';

  @override
  String get moveToOpenArea => 'Move to a clearer area with open sky view';

  @override
  String get gettingBetterGPS => 'Getting better GPS fix... Please wait';

  @override
  String get pointCapturedSuccessfully => 'Point captured successfully';

  @override
  String get distanceFromLastPoint => 'Distance from last point';

  @override
  String get navigatingToPoint => 'Navigating to point';

  @override
  String get allPointsCleared => 'All points and paths have been cleared';

  @override
  String get currentPoints => 'Current Points';

  @override
  String get pointsAdded => 'points added';

  @override
  String get noPointsCaptured => 'No points were captured';

  @override
  String get clearAll => 'Clear All';

  @override
  String get viewPoints => 'View Points';

  @override
  String get navigateTo => 'Navigate To';

  @override
  String get meters => 'meters';

  @override
  String get squareMeters => 'square meters';

  @override
  String get corners => 'corners';

  @override
  String get atLeastThreePoints =>
      'At least 3 points are required to save an area';

  @override
  String get areaSummary => 'Area Summary';

  @override
  String get walkStarted => 'Walk started';

  @override
  String get unableToDetermineLocation =>
      'Unable to determine current location';

  @override
  String get gpsError => 'GPS error occurred';

  @override
  String get pleaseCheckLocationSettings =>
      'Please check your location settings';
}

class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa() : super('ta');

  @override
  String get appTitle => 'நில வரைபடம்';

  @override
  String get landMapping => 'நில வரைபடம் வரைதல்';

  @override
  String get home => 'முகப்பு';

  @override
  String get map => 'வரைபடம்';

  @override
  String get camera => 'கேமரா';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get profile => 'சுயவிவரம்';

  @override
  String get location => 'இடம்';

  @override
  String get latitude => 'அட்சாங்கம்';

  @override
  String get longitude => 'தீர்க்கரேகை';

  @override
  String get accuracy => 'துல்லியம்';

  @override
  String get altitude => 'உயரம்';

  @override
  String get getCurrentLocation => 'தற்போதைய இடத்தைப் பெறுக';

  @override
  String get locationPermissionRequired => 'இட அனுமதி தேவை';

  @override
  String get enableLocationServices => 'தயவுசெய்து இட சேவைகளை இயக்கவும்';

  @override
  String get takePhoto => 'புகைப்படம் எடுக்கவும்';

  @override
  String get gallery => 'பட்டியல்';

  @override
  String get captureImage => 'படம் எடுக்கவும்';

  @override
  String get analyzeImage => 'படத்தை பகுப்பாய்வு செய்யவும்';

  @override
  String get imageAnalysis => 'பட பகுப்பாய்வு';

  @override
  String get cameraPermissionRequired => 'கேமரா அனுமதி தேவை';

  @override
  String get analyzing => 'பகுப்பாய்வு செய்கிறது...';

  @override
  String get analysisComplete => 'பகுப்பாய்வு முடிந்தது';

  @override
  String get landFeatures => 'நில அம்சங்கள்';

  @override
  String get vegetation => 'தாவரங்கள்';

  @override
  String get waterBodies => 'நீர்நிலைகள்';

  @override
  String get elevation => 'உயரம்';

  @override
  String get soilType => 'மண் வகை';

  @override
  String get mapView => 'வரைபட காட்சி';

  @override
  String get addPoint => 'புள்ளி சேர்க்கவும்';

  @override
  String get savedPoints => 'சேமித்த புள்ளிகள்';

  @override
  String get pointDetails => 'புள்ளி விவரங்கள்';

  @override
  String get annotations => 'குறிப்புகள்';

  @override
  String get offlineMode => 'ஆஃப்லைன் பயன்முறை';

  @override
  String get save => 'சேமிக்கவும்';

  @override
  String get export => 'ஏற்றுமதி';

  @override
  String get delete => 'நீக்கவும்';

  @override
  String get sync => 'ஒத்திசைவு';

  @override
  String get exportCsv => 'CSV ஏற்றுமதி';

  @override
  String get exportJson => 'JSON ஏற்றுமதி';

  @override
  String get exportPdf => 'PDF ஏற்றுமதி';

  @override
  String get ok => 'சரி';

  @override
  String get cancel => 'ரத்து செய்யவும்';

  @override
  String get error => 'பிழை';

  @override
  String get success => 'வெற்றி';

  @override
  String get loading => 'ஏற்றுகிறது...';

  @override
  String get noData => 'தரவு இல்லை';

  @override
  String get retry => 'மீண்டும் முயற்சிக்கவும்';

  @override
  String get language => 'மொழி';

  @override
  String get selectLanguage => 'மொழியை தேர்வு செய்யவும்';

  @override
  String get theme => 'அமைப்பு';

  @override
  String get selectTheme => 'அமைப்பை தேர்வு செய்யவும்';

  @override
  String get darkMode => 'மாற்று முறை';

  @override
  String get about => 'பற்றி';

  @override
  String get languageChanged => 'மொழி மாற்றப்பட்டது';

  @override
  String get system => 'சிஸ்டம்';

  @override
  String get light => 'நேர்த்தி';

  @override
  String get dark => 'மாற்று முறை';

  @override
  String get search => 'தேடு';

  @override
  String get searchSavedPoints => 'சேமிக்கப்பட்ட புள்ளிகளைத் தேடவும்';

  @override
  String get sortBy => 'தொகுப்பு';

  @override
  String get date => 'தேதி';

  @override
  String get name => 'பெயர்';

  @override
  String get ascending => 'வரிசை உயர்வாக';

  @override
  String get descending => 'வரிசை குறைவாக';

  @override
  String get close => 'மூடவும்';

  @override
  String get deletePoint => 'புள்ளியை நீக்கவும்';

  @override
  String get deleteConfirmation => 'நீக்குதல் உறுதிப்படுத்தவும்';

  @override
  String get areYouSureDeletePoint => 'இந்த புள்ளியை நீக்க விரும்புகிறீர்களா?';

  @override
  String get pointDeletedSuccessfully => 'புள்ளி வெற்றிகரமாக நீக்கப்பட்டது';

  @override
  String get errorDeletingPoint => 'புள்ளியை நீக்கும் போது பிழை ஏற்பட்டது';

  @override
  String get errorLoadingSavedPoints =>
      'சேமிக்கப்பட்ட புள்ளிகளை ஏற்றும் போது பிழை ஏற்பட்டது';

  @override
  String get noPointsFound => 'புள்ளிகள் கிடைக்கவில்லை';

  @override
  String get noSavedPointsYet => 'இதுவரை சேமிக்கப்படாத புள்ளிகள்';

  @override
  String get tryAdjustingSearch => 'தேடுதலை மாற்றி முயற்சிக்கவும்';

  @override
  String get startCapturingPoints => 'புள்ளிகளை பிடிக்க தொடங்கவும்';

  @override
  String get unnamedPoint => 'பெயரில்லா புள்ளி';

  @override
  String get analysisResults => 'பகுப்பாய்வு முடிவுகள்';

  @override
  String get landFeature => 'நில அம்சம்';

  @override
  String get vegetationCoverage => 'தாவர மூடல்';

  @override
  String get waterCoverage => 'நீர் மூடல்';

  @override
  String get elevationEstimate => 'உயர மதிப்பு';

  @override
  String get confidence => 'நம்பிக்கை';

  @override
  String get notes => 'குறிப்புகள்';

  @override
  String get useDarkTheme => 'மாற்று முறை பயன்படுத்தவும்';

  @override
  String get landMapVersion => 'நில வரைபட பதிப்பு';

  @override
  String get aiPoweredDescription => 'AI செயலியால் ஆதரிக்கப்பட்ட விவரணம்';

  @override
  String get photoCapturedSuccessfully =>
      'புகைப்படம் எடுக்கப்பட்டு வெற்றிகரமாக சேமிக்கப்பட்டது!';

  @override
  String get errorCapturingPhoto => 'புகைப்படம் எடுக்கும் போது பிழை';

  @override
  String get imageImportedSuccessfully =>
      'படம் வெற்றிகரமாக இறக்குமதி செய்யப்பட்டது!';

  @override
  String get errorImportingImage => 'படம் இறக்குமதி செய்யும் போது பிழை';

  @override
  String get cannotSwitchCamera => 'கேமராவை மாற்ற முடியவில்லை';

  @override
  String get initializingCamera => 'கேமராவை துவக்குகிறது...';

  @override
  String get cameraNotAvailable => 'கேமரா கிடைக்கவில்லை';

  @override
  String get routeNotFound => 'பாதை கண்டுபிடிக்கப்படவில்லை';

  // Map & Walk Mode
  @override
  String get walkMode => 'நடை முறை';

  @override
  String get startWalk => 'நடை தொடங்கு';

  @override
  String get stopWalk => 'நடை நிறுத்து';

  @override
  String get capturePoint => 'புள்ளி பிடி';

  @override
  String get walkDistance => 'நடை தூரம்';

  @override
  String get points => 'புள்ளிகள்';

  @override
  String get pointsCaptured => 'புள்ளிகள் பிடிக்கப்பட்டன';

  @override
  String get pointCapture => 'புள்ளி பிடிப்பு';

  @override
  String get area => 'பகுதி';

  @override
  String get perimeter => 'சுற்றளவு';

  @override
  String get areaName => 'பகுதி பெயர்';

  @override
  String get areaNameRequired => 'பகுதி பெயர் தேவை';

  @override
  String get pleaseEnterAreaName => 'தயவுசெய்து பகுதி பெயரை உள்ளிடவும்';

  @override
  String get description => 'விவரணம்';

  @override
  String get optional => 'விருப்பம்';

  @override
  String get capturedPoints => 'பிடிக்கப்பட்ட புள்ளிகள்';

  @override
  String get saveArea => 'பகுதி சேமி';

  @override
  String get savingArea => 'பகுதி சேமிக்கிறது';

  @override
  String get areaSavedSuccessfully => 'பகுதி வெற்றிகரமாக சேமிக்கப்பட்டது';

  @override
  String get walkModeStarted => 'நடை முறை தொடங்கியது';

  @override
  String get walkModeStopped => 'நடை முறை நிறுத்தப்பட்டது';

  @override
  String get highAccuracyGPS => 'உயர் துல்லிய GPS இயக்கப்பட்டது';

  @override
  String get tapCaptureToAddPoints => 'புள்ளிகள் சேர்க்க "பிடி"யை தட்டவும்';

  @override
  String get minimumDistance => 'குறைந்தபட்ச தூரம்';

  @override
  String get distanceWalked => 'நடந்த தூரம்';

  @override
  String get normalView => 'சாதாரண காட்சி';

  @override
  String get satelliteView => 'செயற்கைக்கோள் காட்சி';

  @override
  String get pointMustBeAway => 'புள்ளி குறைந்தபட்சம்';

  @override
  String get moveAtLeast => 'குறைந்தபட்சம் நகர்த்தவும்';

  @override
  String get fromLastPoint => 'கடைசி புள்ளியிலிருந்து';

  @override
  String get pointTooClose => 'புள்ளி மிக அருகில் உள்ளது';

  @override
  String get lowGPSAccuracy => 'குறைந்த GPS துல்லியம்';

  @override
  String get moveToOpenArea => 'திறந்த வானுடன் தெளிவான பகுதிக்கு செல்லவும்';

  @override
  String get gettingBetterGPS => 'சிறந்த GPS பெறுகிறது... காத்திருக்கவும்';

  @override
  String get pointCapturedSuccessfully => 'புள்ளி வெற்றிகரமாக பிடிக்கப்பட்டது';

  @override
  String get distanceFromLastPoint => 'கடைசி புள்ளியிலிருந்து தூரம்';

  @override
  String get navigatingToPoint => 'புள்ளிக்கு வழிநடத்துகிறது';

  @override
  String get allPointsCleared => 'அனைத்து புள்ளிகளும் பாதைகளும் அழிக்கப்பட்டன';

  @override
  String get currentPoints => 'தற்போதைய புள்ளிகள்';

  @override
  String get pointsAdded => 'புள்ளிகள் சேர்க்கப்பட்டன';

  @override
  String get noPointsCaptured => 'புள்ளிகள் பிடிக்கப்படவில்லை';

  @override
  String get clearAll => 'அனைத்தையும் அழி';

  @override
  String get viewPoints => 'புள்ளிகள் பார்';

  @override
  String get navigateTo => 'வழிநடத்து';

  @override
  String get meters => 'மீட்டர்கள்';

  @override
  String get squareMeters => 'சதுர மீட்டர்கள்';

  @override
  String get corners => 'மூலைகள்';

  @override
  String get atLeastThreePoints => 'பகுதி சேமிக்க குறைந்தது 3 புள்ளிகள் தேவை';

  @override
  String get areaSummary => 'பகுதி சுருக்கம்';

  @override
  String get walkStarted => 'நடை தொடங்கியது';

  @override
  String get unableToDetermineLocation =>
      'தற்போதைய இடத்தை தீர்மானிக்க முடியவில்லை';

  @override
  String get gpsError => 'GPS பிழை ஏற்பட்டது';

  @override
  String get pleaseCheckLocationSettings =>
      'தயவுசெய்து உங்கள் இட அமைப்புகளை சரிபார்க்கவும்';
}

class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi() : super('hi');

  @override
  String get appTitle => 'भूमि मैपर';

  @override
  String get landMapping => 'भूमि मैपिंग';

  @override
  String get home => 'गृह';

  @override
  String get map => 'मानचित्र';

  @override
  String get camera => 'कैमरा';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get profile => 'प्रोफ़ाइल';

  @override
  String get location => 'स्थान';

  @override
  String get latitude => 'अक्षांश';

  @override
  String get longitude => 'देशांतर';

  @override
  String get accuracy => 'सटीकता';

  @override
  String get altitude => 'ऊंचाई';

  @override
  String get getCurrentLocation => 'वर्तमान स्थान प्राप्त करें';

  @override
  String get locationPermissionRequired => 'स्थान अनुमति आवश्यक है';

  @override
  String get enableLocationServices => 'कृपया स्थान सेवाओं को सक्षम करें';

  @override
  String get takePhoto => 'फोटो लें';

  @override
  String get gallery => 'गैलरी';

  @override
  String get captureImage => 'छवि पकड़ें';

  @override
  String get analyzeImage => 'छवि विश्लेषण करें';

  @override
  String get imageAnalysis => 'छवि विश्लेषण';

  @override
  String get cameraPermissionRequired => 'कैमरा अनुमति आवश्यक है';

  @override
  String get analyzing => 'विश्लेषण कर रहा है...';

  @override
  String get analysisComplete => 'विश्लेषण पूरा हुआ';

  @override
  String get landFeatures => 'भूमि के लक्षण';

  @override
  String get vegetation => 'वनस्पति';

  @override
  String get waterBodies => 'जल निकाय';

  @override
  String get elevation => 'ऊंचाई';

  @override
  String get soilType => 'मिट्टी का प्रकार';

  @override
  String get mapView => 'मानचित्र दृश्य';

  @override
  String get addPoint => 'बिंदु जोड़ें';

  @override
  String get savedPoints => 'सहेजे गए बिंदु';

  @override
  String get pointDetails => 'बिंदु के विवरण';

  @override
  String get annotations => 'टिप्पणियाँ';

  @override
  String get offlineMode => 'ऑफलाइन मोड';

  @override
  String get save => 'सहेजें';

  @override
  String get export => 'निर्यात';

  @override
  String get delete => 'हटाएं';

  @override
  String get sync => 'सिंक';

  @override
  String get exportCsv => 'CSV निर्यात';

  @override
  String get exportJson => 'JSON निर्यात';

  @override
  String get exportPdf => 'PDF निर्यात';

  @override
  String get ok => 'ठीक';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get error => 'त्रुटि';

  @override
  String get success => 'सफलता';

  @override
  String get loading => 'लोड हो रहा है...';

  @override
  String get noData => 'कोई डेटा उपलब्ध नहीं';

  @override
  String get retry => 'फिर से कोशिश करें';

  @override
  String get language => 'भाषा';

  @override
  String get selectLanguage => 'भाषा चुनें';

  @override
  String get theme => 'थीम';

  @override
  String get selectTheme => 'थीम चुनें';

  @override
  String get darkMode => 'डार्क मोड';

  @override
  String get about => 'के बारे में';

  @override
  String get languageChanged => 'भाषा बदल गई';

  @override
  String get system => 'सिस्टम';

  @override
  String get light => 'लाइट';

  @override
  String get dark => 'डार्क';

  @override
  String get search => 'खोज';

  @override
  String get searchSavedPoints => 'सहेजे गए बिंदुओं की खोज करें';

  @override
  String get sortBy => 'क्रमबद्ध करें';

  @override
  String get date => 'तारीख';

  @override
  String get name => 'नाम';

  @override
  String get ascending => 'आरोही';

  @override
  String get descending => 'अवरोही';

  @override
  String get close => 'बंद करें';

  @override
  String get deletePoint => 'बिंदु हटाएं';

  @override
  String get deleteConfirmation => 'हटाने की पुष्टि करें';

  @override
  String get areYouSureDeletePoint =>
      'क्या आप वाकई इस बिंदु को हटाना चाहते हैं?';

  @override
  String get pointDeletedSuccessfully => 'बिंदु सफलतापूर्वक हटा दिया गया';

  @override
  String get errorDeletingPoint => 'बिंदु हटाने में त्रुटि हुई';

  @override
  String get errorLoadingSavedPoints =>
      'सहेजे गए बिंदु लोड करने में त्रुटि हुई';

  @override
  String get noPointsFound => 'कोई बिंदु नहीं मिला';

  @override
  String get noSavedPointsYet => 'अभी तक कोई बिंदु नहीं सहेजा गया';

  @override
  String get tryAdjustingSearch => 'खोज समायोजित करके दोबारा कोशिश करें';

  @override
  String get startCapturingPoints => 'बिंदु पकड़ना शुरू करें';

  @override
  String get unnamedPoint => 'नामहीन बिंदु';

  @override
  String get analysisResults => 'विश्लेषण परिणाम';

  @override
  String get landFeature => 'भूमि की विशेषता';

  @override
  String get vegetationCoverage => 'वनस्पति कवरेज';

  @override
  String get waterCoverage => 'जल कवरेज';

  @override
  String get elevationEstimate => 'ऊंचाई का अनुमान';

  @override
  String get confidence => 'विश्वास';

  @override
  String get notes => 'टिप्पणियाँ';

  @override
  String get useDarkTheme => 'डार्क थीम का उपयोग करें';

  @override
  String get landMapVersion => 'भूमि मानचित्र संस्करण';

  @override
  String get aiPoweredDescription => 'AI द्वारा संचालित विवरण';

  @override
  String get photoCapturedSuccessfully =>
      'फोटो सफलतापूर्वक कैप्चर और सेव किया गया!';

  @override
  String get errorCapturingPhoto => 'फोटो कैप्चर करने में त्रुटि';

  @override
  String get imageImportedSuccessfully => 'छवि सफलतापूर्वक आयात की गई!';

  @override
  String get errorImportingImage => 'छवि आयात करने में त्रुटि';

  @override
  String get cannotSwitchCamera => 'कैमरा स्विच नहीं कर सकते';

  @override
  String get initializingCamera => 'कैमरा आरम्भ हो रहा है...';

  @override
  String get cameraNotAvailable => 'कैमरा उपलब्ध नहीं';

  @override
  String get routeNotFound => 'रूट नहीं मिला';

  // Map & Walk Mode
  @override
  String get walkMode => 'पैदल मोड';

  @override
  String get startWalk => 'चलना शुरू करें';

  @override
  String get stopWalk => 'चलना बंद करें';

  @override
  String get capturePoint => 'बिंदु कैप्चर करें';

  @override
  String get walkDistance => 'चलने की दूरी';

  @override
  String get points => 'बिंदु';

  @override
  String get pointsCaptured => 'बिंदु कैप्चर किए गए';

  @override
  String get pointCapture => 'बिंदु कैप्चर';

  @override
  String get area => 'क्षेत्र';

  @override
  String get perimeter => 'परिधि';

  @override
  String get areaName => 'क्षेत्र का नाम';

  @override
  String get areaNameRequired => 'क्षेत्र का नाम आवश्यक है';

  @override
  String get pleaseEnterAreaName => 'कृपया क्षेत्र का नाम दर्ज करें';

  @override
  String get description => 'विवरण';

  @override
  String get optional => 'वैकल्पिक';

  @override
  String get capturedPoints => 'कैप्चर किए गए बिंदु';

  @override
  String get saveArea => 'क्षेत्र सहेजें';

  @override
  String get savingArea => 'क्षेत्र सहेजा जा रहा है';

  @override
  String get areaSavedSuccessfully => 'क्षेत्र सफलतापूर्वक सहेजा गया';

  @override
  String get walkModeStarted => 'पैदल मोड शुरू किया गया';

  @override
  String get walkModeStopped => 'पैदल मोड बंद किया गया';

  @override
  String get highAccuracyGPS => 'उच्च सटीकता GPS सक्षम';

  @override
  String get tapCaptureToAddPoints =>
      'बिंदु जोड़ने के लिए "कैप्चर" पर टैप करें';

  @override
  String get minimumDistance => 'न्यूनतम दूरी';

  @override
  String get distanceWalked => 'चली गई दूरी';

  @override
  String get normalView => 'सामान्य दृश्य';

  @override
  String get satelliteView => 'उपग्रह दृश्य';

  @override
  String get pointMustBeAway => 'बिंदु कम से कम';

  @override
  String get moveAtLeast => 'कम से कम हिलाएं';

  @override
  String get fromLastPoint => 'अंतिम बिंदु से';

  @override
  String get pointTooClose => 'बिंदु बहुत करीब है';

  @override
  String get lowGPSAccuracy => 'कम GPS सटीकता';

  @override
  String get moveToOpenArea => 'खुले आसमान के साथ स्पष्ट क्षेत्र में जाएं';

  @override
  String get gettingBetterGPS =>
      'बेहतर GPS प्राप्त हो रहा है... कृपया प्रतीक्षा करें';

  @override
  String get pointCapturedSuccessfully => 'बिंदु सफलतापूर्वक कैप्चर किया गया';

  @override
  String get distanceFromLastPoint => 'अंतिम बिंदु से दूरी';

  @override
  String get navigatingToPoint => 'बिंदु की ओर नेविगेट कर रहा है';

  @override
  String get allPointsCleared => 'सभी बिंदु और पथ साफ कर दिए गए हैं';

  @override
  String get currentPoints => 'वर्तमान बिंदु';

  @override
  String get pointsAdded => 'बिंदु जोड़े गए';

  @override
  String get noPointsCaptured => 'कोई बिंदु कैप्चर नहीं किया गया';

  @override
  String get clearAll => 'सभी साफ करें';

  @override
  String get viewPoints => 'बिंदु देखें';

  @override
  String get navigateTo => 'नेविगेट करें';

  @override
  String get meters => 'मीटर';

  @override
  String get squareMeters => 'वर्ग मीटर';

  @override
  String get corners => 'कोने';

  @override
  String get atLeastThreePoints =>
      'क्षेत्र सहेजने के लिए कम से कम 3 बिंदु आवश्यक हैं';

  @override
  String get areaSummary => 'क्षेत्र सारांश';

  @override
  String get walkStarted => 'चलना शुरू किया गया';

  @override
  String get unableToDetermineLocation =>
      'वर्तमान स्थान निर्धारित करने में असमर्थ';

  @override
  String get gpsError => 'GPS त्रुटि हुई';

  @override
  String get pleaseCheckLocationSettings => 'कृपया अपनी स्थान सेटिंग्स जांचें';
}

class AppLocalizationsTe extends AppLocalizations {
  AppLocalizationsTe() : super('te');

  @override
  String get appTitle => 'ల్యాండ్ మ్యాపర్';

  @override
  String get landMapping => 'ల్యాండ్ మ్యాపింగ్';

  @override
  String get home => 'హోమ్';

  @override
  String get map => 'మాప్';

  @override
  String get camera => 'కెమెరా';

  @override
  String get settings => 'సెట్టింగ్స్';

  @override
  String get profile => 'ప్రొఫైల్';

  @override
  String get location => 'లొకేషన్';

  @override
  String get latitude => 'లాటిట్యూడ్';

  @override
  String get longitude => 'లాంగిట్యూడ్';

  @override
  String get accuracy => 'సరిపోలిక';

  @override
  String get altitude => 'ఎత్తు';

  @override
  String get getCurrentLocation => 'ప్రస్తుత స్థానాన్ని పొందండి';

  @override
  String get locationPermissionRequired => 'లొకేషన్ అనుమతి అవసరం';

  @override
  String get enableLocationServices =>
      'దయచేసి లొకేషన్ సర్వీసులను ప్రారంభించండి';

  @override
  String get takePhoto => 'ఫోటో తీయండి';

  @override
  String get gallery => 'గ్యాలరీ';

  @override
  String get captureImage => 'ఇమేజ్ ని సేకరించండి';

  @override
  String get analyzeImage => 'ఇమేజ్ ని విశ్లేషించండి';

  @override
  String get imageAnalysis => 'ఇమేజ్ విశ్లేషణ';

  @override
  String get cameraPermissionRequired => 'కెమెరా అనుమతి అవసరం';

  @override
  String get analyzing => 'విశ్లేషిస్తున్నారు...';

  @override
  String get analysisComplete => 'విశ్లేషణ పూర్తయింది';

  @override
  String get landFeatures => 'ల్యాండ్ ఫీచర్లు';

  @override
  String get vegetation => 'వెజిటేషన్';

  @override
  String get waterBodies => 'వాటర్ బాడీస్';

  @override
  String get elevation => 'ఎత్తు';

  @override
  String get soilType => 'మట్టి రకం';

  @override
  String get mapView => 'మాప్ వ్యూ';

  @override
  String get addPoint => 'పాయింట్ జోడించండి';

  @override
  String get savedPoints => 'సేవ్ చేసిన పాయింట్లు';

  @override
  String get pointDetails => 'పాయింట్ వివరాలు';

  @override
  String get annotations => 'అనోటేషన్లు';

  @override
  String get offlineMode => 'ఆఫ్లైన్ మోడ్';

  @override
  String get save => 'సేవ్ చేయండి';

  @override
  String get export => 'ఎగుమతి';

  @override
  String get delete => 'తొలగించు';

  @override
  String get sync => 'సింక్';

  @override
  String get exportCsv => 'CSV ఎగుమతి';

  @override
  String get exportJson => 'JSON ఎగుమతి';

  @override
  String get exportPdf => 'PDF ఎగుమతి';

  @override
  String get ok => 'సరే';

  @override
  String get cancel => 'రద్దు చేయండి';

  @override
  String get error => 'పొరపాటు';

  @override
  String get success => 'సక్సెస్';

  @override
  String get loading => 'లోడ్ అవుతోంది...';

  @override
  String get noData => 'డేటా అందుబాటులో లేదు';

  @override
  String get retry => 'మళ్లీ ప్రయత్నించండి';

  @override
  String get language => 'భాష';

  @override
  String get selectLanguage => 'భాష ఎంచుకోండి';

  @override
  String get theme => 'థీమ్';

  @override
  String get selectTheme => 'థీమ్ ఎంచుకోండి';

  @override
  String get darkMode => 'డార్క్ మోడ్';

  @override
  String get about => 'పింది';

  @override
  String get languageChanged => 'భాష మారింది';

  @override
  String get system => 'సిస్టమ్';

  @override
  String get light => 'లైట్';

  @override
  String get dark => 'డార్క్';

  @override
  String get search => 'శోధించండి';

  @override
  String get searchSavedPoints => 'సేవ్ చేసిన పాయింట్లను శోధించండి';

  @override
  String get sortBy => 'సారణి';

  @override
  String get date => 'తేది';

  @override
  String get name => 'పేరు';

  @override
  String get ascending => 'పైకి';

  @override
  String get descending => 'దిగువకు';

  @override
  String get close => 'మూసివేయండి';

  @override
  String get deletePoint => 'పాయింట్ ని తొలగించండి';

  @override
  String get deleteConfirmation => 'తొలగించడాన్ని ధృవీకరించండి';

  @override
  String get areYouSureDeletePoint =>
      'మీరు ఈ పాయింట్ ని తొలగించాలని నిర్ధారించుకున్నారా?';

  @override
  String get pointDeletedSuccessfully =>
      'పాయింట్ సక్సెస్ ఫుల్ గా తొలగించబడింది';

  @override
  String get errorDeletingPoint => 'పాయింట్ తొలగించడంలో పొరపాటు';

  @override
  String get errorLoadingSavedPoints =>
      'సేవ్ చేసిన పాయింట్లను లోడ్ చేయడంలో పొరపాటు';

  @override
  String get noPointsFound => 'పాయింట్లు కనుగొనబడలేదు';

  @override
  String get noSavedPointsYet => 'ఇంకా సేవ్ చేయబడని పాయింట్లు';

  @override
  String get tryAdjustingSearch => 'శోధనను సరిచేసి ప్రయత్నించండి';

  @override
  String get startCapturingPoints => 'పాయింట్లను సేకరించడం ప్రారంభించండి';

  @override
  String get unnamedPoint => 'పేరు లేని పాయింట్';

  @override
  String get analysisResults => 'విశ్లేషణ ఫలితాలు';

  @override
  String get landFeature => 'ల్యాండ్ ఫీచర్';

  @override
  String get vegetationCoverage => 'వెజిటేషన్ కవరేజ్';

  @override
  String get waterCoverage => 'వాటర్ కవరేజ్';

  @override
  String get elevationEstimate => 'ఎత్తు అంచనా';

  @override
  String get confidence => 'నమ్మకం';

  @override
  String get notes => 'నోట్లు';

  @override
  String get useDarkTheme => 'డార్క్ థీమ్ ఉపయోగించండి';

  @override
  String get landMapVersion => 'ల్యాండ్ మాప్ వెర్షన్';

  @override
  String get aiPoweredDescription => 'ఎఐ బేస్డ్ వివరణ';

  @override
  String get photoCapturedSuccessfully =>
      'ఫోటో విజయవంతంగా క్యాప్చర్ మరియు సేవ్ చేయబడింది!';

  @override
  String get errorCapturingPhoto => 'ఫోటో క్యాప్చర్ చేయడంలో పొరపాటు';

  @override
  String get imageImportedSuccessfully =>
      'ఇమేజ్ విజయవంతంగా ఇంపోర్ట్ చేయబడింది!';

  @override
  String get errorImportingImage => 'ఇమేజ్ ఇంపోర్ట్ చేయడంలో పొరపాటు';

  @override
  String get cannotSwitchCamera => 'కెమెరాను స్విచ్ చేయలేము';

  @override
  String get initializingCamera => 'కెమెరా ప్రారంభిస్తోంది...';

  @override
  String get cameraNotAvailable => 'కెమెరా అందుబాటులో లేదు';

  @override
  String get routeNotFound => 'రూట్ కనుగొనబడలేదు';

  // Map & Walk Mode
  @override
  String get walkMode => 'వాక్ మోడ్';

  @override
  String get startWalk => 'వాక్ ప్రారంభించు';

  @override
  String get stopWalk => 'వాక్ ఆపు';

  @override
  String get capturePoint => 'పాయింట్ క్యాప్చర్ చేయి';

  @override
  String get walkDistance => 'వాక్ దూరం';

  @override
  String get points => 'పాయింట్లు';

  @override
  String get pointsCaptured => 'పాయింట్లు క్యాప్చర్ చేయబడ్డాయి';

  @override
  String get pointCapture => 'పాయింట్ క్యాప్చర్';

  @override
  String get area => 'ప్రాంతం';

  @override
  String get perimeter => 'చుట్టుకొలత';

  @override
  String get areaName => 'ప్రాంత పేరు';

  @override
  String get areaNameRequired => 'ప్రాంత పేరు అవసరం';

  @override
  String get pleaseEnterAreaName => 'దయచేసి ప్రాంత పేరు నమోదు చేయండి';

  @override
  String get description => 'వివరణ';

  @override
  String get optional => 'ఐచ్ఛికం';

  @override
  String get capturedPoints => 'క్యాప్చర్ చేసిన పాయింట్లు';

  @override
  String get saveArea => 'ప్రాంతం సేవ్ చేయి';

  @override
  String get savingArea => 'ప్రాంతం సేవ్ చేస్తోంది';

  @override
  String get areaSavedSuccessfully => 'ప్రాంతం విజయవంతంగా సేవ్ చేయబడింది';

  @override
  String get walkModeStarted => 'వాక్ మోడ్ ప్రారంభమైంది';

  @override
  String get walkModeStopped => 'వాక్ మోడ్ ఆపబడింది';

  @override
  String get highAccuracyGPS => 'అధిక ఖచ్చితత్వ GPS ప్రారంభించబడింది';

  @override
  String get tapCaptureToAddPoints =>
      'పాయింట్లు జోడించడానికి "క్యాప్చర్" నొక్కండి';

  @override
  String get minimumDistance => 'కనిష్ట దూరం';

  @override
  String get distanceWalked => 'నడిచిన దూరం';

  @override
  String get normalView => 'సాధారణ దృశ్యం';

  @override
  String get satelliteView => 'ఉపగ్రహ దృశ్యం';

  @override
  String get pointMustBeAway => 'పాయింట్ కనీసం';

  @override
  String get moveAtLeast => 'కనీసం కదిలించు';

  @override
  String get fromLastPoint => 'చివరి పాయింట్ నుండి';

  @override
  String get pointTooClose => 'పాయింట్ చాలా దగ్గరగా ఉంది';

  @override
  String get lowGPSAccuracy => 'తక్కువ GPS ఖచ్చితత్వం';

  @override
  String get moveToOpenArea => 'తెరిచిన ఆకాశంతో స్పష్టమైన ప్రాంతానికి వెళ్లండి';

  @override
  String get gettingBetterGPS => 'మెరుగైన GPS పొందుతోంది... దయచేసి వేచి ఉండండి';

  @override
  String get pointCapturedSuccessfully =>
      'పాయింట్ విజయవంతంగా క్యాప్చర్ చేయబడింది';

  @override
  String get distanceFromLastPoint => 'చివరి పాయింట్ నుండి దూరం';

  @override
  String get navigatingToPoint => 'పాయింట్‌కు నావిగేట్ చేస్తోంది';

  @override
  String get allPointsCleared =>
      'అన్ని పాయింట్లు మరియు మార్గాలు క్లియర్ చేయబడ్డాయి';

  @override
  String get currentPoints => 'ప్రస్తుత పాయింట్లు';

  @override
  String get pointsAdded => 'పాయింట్లు జోడించబడ్డాయి';

  @override
  String get noPointsCaptured => 'పాయింట్లు క్యాప్చర్ చేయబడలేదు';

  @override
  String get clearAll => 'అన్నీ క్లియర్ చేయి';

  @override
  String get viewPoints => 'పాయింట్లు చూడు';

  @override
  String get navigateTo => 'నావిగేట్ చేయి';

  @override
  String get meters => 'మీటర్లు';

  @override
  String get squareMeters => 'చదరపు మీటర్లు';

  @override
  String get corners => 'మూలలు';

  @override
  String get atLeastThreePoints =>
      'ప్రాంతం సేవ్ చేయడానికి కనీసం 3 పాయింట్లు అవసరం';

  @override
  String get areaSummary => 'ప్రాంత సారాంశం';

  @override
  String get walkStarted => 'వాక్ ప్రారంభమైంది';

  @override
  String get unableToDetermineLocation =>
      'ప్రస్తుత స్థానాన్ని నిర్ధారించలేకపోయింది';

  @override
  String get gpsError => 'GPS లోపం సంభవించింది';

  @override
  String get pleaseCheckLocationSettings =>
      'దయచేసి మీ స్థాన సెట్టింగులను తనిఖీ చేయండి';
}

class AppLocalizationsMl extends AppLocalizations {
  AppLocalizationsMl() : super('ml');

  @override
  String get appTitle => 'ഭൂപട സൃഷ്ടിക്കുക';

  @override
  String get landMapping => 'ഭൂപട സൃഷ്ടിക്കുക';

  @override
  String get home => 'ഹോം';

  @override
  String get map => 'മാപ്പ്';

  @override
  String get camera => 'ക്യാമറ';

  @override
  String get settings => 'സെറ്റിംഗ്സ്';

  @override
  String get profile => 'പ്രൊഫൈല്‍';

  @override
  String get location => 'സ്ഥലം';

  @override
  String get latitude => 'ലാറ്റിറ്റ്യൂഡ്';

  @override
  String get longitude => 'ലോങ്കിറ്റ്യൂഡ്';

  @override
  String get accuracy => 'സഠികത';

  @override
  String get altitude => 'ഉയരം';

  @override
  String get getCurrentLocation => 'പ്രസ്തുത സ്ഥലം നേടുക';

  @override
  String get locationPermissionRequired => 'സ്ഥല അനുമതി ആവശ്യമാണ്';

  @override
  String get enableLocationServices =>
      'ദയവായി സ്ഥല സേവനങ്ങൾ പ്രവർത്തനാത്മകമാക്കുക';

  @override
  String get takePhoto => 'ഫോട്ടോ എടുക്കുക';

  @override
  String get gallery => 'ഗാലറി';

  @override
  String get captureImage => 'ചിത്രം പിടിക്കുക';

  @override
  String get analyzeImage => 'ചിത്രം വിശകലനം ചെയ്യുക';

  @override
  String get imageAnalysis => 'ചിത്ര വിശകലനം';

  @override
  String get cameraPermissionRequired => 'ക്യാമറ അനുമതി ആവശ്യമാണ്';

  @override
  String get analyzing => 'വിശകലനം ചെയ്യുന്നു...';

  @override
  String get analysisComplete => 'വിശകലനം പൂർത്തിയായി';

  @override
  String get landFeatures => 'ഭൂപ്രകൃതി';

  @override
  String get vegetation => 'വനസമ്പത്ത്';

  @override
  String get waterBodies => 'ജലാശയങ്ങൾ';

  @override
  String get elevation => 'ഉയരം';

  @override
  String get soilType => 'മണ്ണ് തരം';

  @override
  String get mapView => 'മാപ്പ് വ്യൂ';

  @override
  String get addPoint => 'ബിന്ദു ചേർക്കുക';

  @override
  String get savedPoints => 'സേവ് ചെയ്ത ബിന്ദുക്കൾ';

  @override
  String get pointDetails => 'ബിന്ദു വിവരങ്ങൾ';

  @override
  String get annotations => 'അനോട്ടേഷനുകൾ';

  @override
  String get offlineMode => 'ഓഫ്ലൈൻ മോഡ്';

  @override
  String get save => 'സേവ് ചെയ്യുക';

  @override
  String get export => 'എക്സ്പോർട്ട്';

  @override
  String get delete => 'ഇല്ലാതാക്കുക';

  @override
  String get sync => 'സിങ്ക്';

  @override
  String get exportCsv => 'CSV എക്സ്പോർട്ട്';

  @override
  String get exportJson => 'JSON എക്സ്പോർട്ട്';

  @override
  String get exportPdf => 'PDF എക്സ്പോർട്ട്';

  @override
  String get ok => 'ശരി';

  @override
  String get cancel => 'രദ്ദാക്കുക';

  @override
  String get error => 'പിശക്';

  @override
  String get success => 'വിജയം';

  @override
  String get loading => 'ലോഡ് ചെയ്യുന്നു...';

  @override
  String get noData => 'ഡാറ്റ ലഭ്യമല്ല';

  @override
  String get retry => 'വീണ്ടും ശ്രമിക്കുക';

  @override
  String get language => 'ഭാഷ';

  @override
  String get selectLanguage => 'ഭാഷ തിരഞ്ഞെടുക്കുക';

  @override
  String get theme => 'തീം';

  @override
  String get selectTheme => 'തീം തിരഞ്ഞെടുക്കുക';

  @override
  String get darkMode => 'ഡാർക്ക് മോഡ്';

  @override
  String get about => 'പ്രതി';

  @override
  String get languageChanged => 'ഭാഷ മാറി';

  @override
  String get system => 'സിസ്റ്റം';

  @override
  String get light => 'ലൈറ്റ്';

  @override
  String get dark => 'ഡാർക്ക്';

  @override
  String get search => 'തിരയുക';

  @override
  String get searchSavedPoints => 'സേവ് ചെയ്ത ബിന്ദുക്കൾ തിരയുക';

  @override
  String get sortBy => 'തരംതിരിക്കുക';

  @override
  String get date => 'തീയതി';

  @override
  String get name => 'പേര്';

  @override
  String get ascending => 'അര്‍ദ്ധനില';

  @override
  String get descending => 'അവര്‍ദ്ധനില';

  @override
  String get close => 'അടയ്ക്കുക';

  @override
  String get deletePoint => 'ബിന്ദു ഇല്ലാതാക്കുക';

  @override
  String get deleteConfirmation => 'ഇല്ലാതാക്കൽ ഉറപ്പാക്കുക';

  @override
  String get areYouSureDeletePoint => 'ബിന്ദു ഇല്ലാതാക്കണമോ എന്ന് ഉറപ്പാക്കുക?';

  @override
  String get pointDeletedSuccessfully => 'ബിന്ദു വിജയകരമായി ഇല്ലാതാക്കി';

  @override
  String get errorDeletingPoint => 'ബിന്ദു ഇല്ലാതാക്കൽ പിശകുണ്ടായി';

  @override
  String get errorLoadingSavedPoints =>
      'സേവ് ചെയ്ത ബിന്ദുക്കൾ ലോഡ് ചെയ്യൽ പിശകുണ്ടായി';

  @override
  String get noPointsFound => 'ബിന്ദുക്കൾ കണ്ടെത്തിയില്ല';

  @override
  String get noSavedPointsYet => 'ഇതുവരെ സേവ് ചെയ്ത ബിന്ദുക്കളില്ല';

  @override
  String get tryAdjustingSearch => 'തിരയൽ സമായോജിപ്പിച്ച് ശ്രമിക്കുക';

  @override
  String get startCapturingPoints => 'ബിന്ദുക്കൾ പിടിക്കൽ ആരംഭിക്കുക';

  @override
  String get unnamedPoint => 'പേരില്ലാത്ത ബിന്ദു';

  @override
  String get analysisResults => 'വിശകലന ഫലങ്ങൾ';

  @override
  String get landFeature => 'ഭൂപ്രകൃതി';

  @override
  String get vegetationCoverage => 'വനസമ്പത്ത് കവറേജ്';

  @override
  String get waterCoverage => 'ജല കവറേജ്';

  @override
  String get elevationEstimate => 'ഉയരം അനുമാനം';

  @override
  String get confidence => 'വിശ്വാസം';

  @override
  String get notes => 'കുറിപ്പുകൾ';

  @override
  String get useDarkTheme => 'ഡാർക്ക് തീം ഉപയോഗിക്കുക';

  @override
  String get landMapVersion => 'ഭൂപട പതിപ്പ്';

  @override
  String get aiPoweredDescription => 'എ.ഐ. പ്രവർത്തിപ്പിച്ച വിവരണം';

  @override
  String get photoCapturedSuccessfully =>
      'ഫോട്ടോ വിജയകരമായി ക്യാപ്ചർ ചെയ്ത് സേവ് ചെയ്തു!';

  @override
  String get errorCapturingPhoto => 'ഫോട്ടോ ക്യാപ്ചർ ചെയ്യൽ പിശകുണ്ടായി';

  @override
  String get imageImportedSuccessfully => 'ഇമേജ് വിജയകരമായി ഇമ്പോർട്ട് ചെയ്തു!';

  @override
  String get errorImportingImage => 'ഇമേജ് ഇമ്പോർട്ട് ചെയ്യൽ പിശകുണ്ടായി';

  @override
  String get cannotSwitchCamera => 'ക്യാമറ സ്വിച്ച് ചെയ്യാൻ കഴിയില്ല';

  @override
  String get initializingCamera => 'ക്യാമറ പ്രാരംഭിക്കുന്നു...';

  @override
  String get cameraNotAvailable => 'ക്യാമറ ലഭ്യമല്ല';

  @override
  String get routeNotFound => 'റൂട്ട് കണ്ടെത്തിയില്ല';

  // Map & Walk Mode
  @override
  String get walkMode => 'നടക്കൽ മോഡ്';

  @override
  String get startWalk => 'നടക്കൽ ആരംഭിക്കുക';

  @override
  String get stopWalk => 'നടക്കൽ നിർത്തുക';

  @override
  String get capturePoint => 'പോയിന്റ് ക്യാപ്ചർ ചെയ്യുക';

  @override
  String get walkDistance => 'നടക്കൽ ദൂരം';

  @override
  String get points => 'പോയിന്റുകൾ';

  @override
  String get pointsCaptured => 'പോയിന്റുകൾ ക്യാപ്ചർ ചെയ്തു';

  @override
  String get pointCapture => 'പോയിന്റ് ക്യാപ്ചർ';

  @override
  String get area => 'പ്രദേശം';

  @override
  String get perimeter => 'ചുറ്റളവ്';

  @override
  String get areaName => 'പ്രദേശത്തിന്റെ പേര്';

  @override
  String get areaNameRequired => 'പ്രദേശത്തിന്റെ പേര് ആവശ്യമാണ്';

  @override
  String get pleaseEnterAreaName => 'ദയവായി പ്രദേശത്തിന്റെ പേര് നൽകുക';

  @override
  String get description => 'വിവരണം';

  @override
  String get optional => 'ഐച്ഛികം';

  @override
  String get capturedPoints => 'ക്യാപ്ചർ ചെയ്ത പോയിന്റുകൾ';

  @override
  String get saveArea => 'പ്രദേശം സേവ് ചെയ്യുക';

  @override
  String get savingArea => 'പ്രദേശം സേവ് ചെയ്യുന്നു';

  @override
  String get areaSavedSuccessfully => 'പ്രദേശം വിജയകരമായി സേവ് ചെയ്തു';

  @override
  String get walkModeStarted => 'നടക്കൽ മോഡ് ആരംഭിച്ചു';

  @override
  String get walkModeStopped => 'നടക്കൽ മോഡ് നിർത്തി';

  @override
  String get highAccuracyGPS => 'ഉയർന്ന കൃത്യത GPS പ്രവർത്തനക്ഷമമാക്കി';

  @override
  String get tapCaptureToAddPoints =>
      'പോയിന്റുകൾ ചേർക്കാൻ "ക്യാപ്ചർ" ടാപ് ചെയ്യുക';

  @override
  String get minimumDistance => 'കുറഞ്ഞ ദൂരം';

  @override
  String get distanceWalked => 'നടന്ന ദൂരം';

  @override
  String get normalView => 'സാധാരണ കാഴ്ച';

  @override
  String get satelliteView => 'ഉപഗ്രഹ കാഴ്ച';

  @override
  String get pointMustBeAway => 'പോയിന്റ് കുറഞ്ഞത്';

  @override
  String get moveAtLeast => 'കുറഞ്ഞത് നീക്കുക';

  @override
  String get fromLastPoint => 'അവസാന പോയിന്റിൽ നിന്ന്';

  @override
  String get pointTooClose => 'പോയിന്റ് വളരെ അടുത്താണ്';

  @override
  String get lowGPSAccuracy => 'കുറഞ്ഞ GPS കൃത്യത';

  @override
  String get moveToOpenArea =>
      'തുറന്ന ആകാശമുള്ള വ്യക്തമായ പ്രദേശത്തേക്ക് നീങ്ങുക';

  @override
  String get gettingBetterGPS =>
      'മികച്ച GPS ലഭിക്കുന്നു... ദയവായി കാത്തിരിക്കുക';

  @override
  String get pointCapturedSuccessfully => 'പോയിന്റ് വിജയകരമായി ക്യാപ്ചർ ചെയ്തു';

  @override
  String get distanceFromLastPoint => 'അവസാന പോയിന്റിൽ നിന്നുള്ള ദൂരം';

  @override
  String get navigatingToPoint => 'പോയിന്റിലേക്ക് നാവിഗേറ്റ് ചെയ്യുന്നു';

  @override
  String get allPointsCleared => 'എല്ലാ പോയിന്റുകളും പാതകളും ക്ലിയർ ചെയ്തു';

  @override
  String get currentPoints => 'നിലവിലുള്ള പോയിന്റുകൾ';

  @override
  String get pointsAdded => 'പോയിന്റുകൾ ചേർത്തു';

  @override
  String get noPointsCaptured => 'പോയിന്റുകൾ ക്യാപ്ചർ ചെയ്തിട്ടില്ല';

  @override
  String get clearAll => 'എല്ലാം ക്ലിയർ ചെയ്യുക';

  @override
  String get viewPoints => 'പോയിന്റുകൾ കാണുക';

  @override
  String get navigateTo => 'നാവിഗേറ്റ് ചെയ്യുക';

  @override
  String get meters => 'മീറ്റർ';

  @override
  String get squareMeters => 'ചതുരശ്ര മീറ്റർ';

  @override
  String get corners => 'കോണുകൾ';

  @override
  String get atLeastThreePoints =>
      'പ്രദേശം സേവ് ചെയ്യാൻ കുറഞ്ഞത് 3 പോയിന്റുകൾ ആവശ്യമാണ്';

  @override
  String get areaSummary => 'പ്രദേശ സംഗ്രഹം';

  @override
  String get walkStarted => 'നടക്കൽ ആരംഭിച്ചു';

  @override
  String get unableToDetermineLocation =>
      'നിലവിലുള്ള സ്ഥാനം നിർണ്ണയിക്കാനായില്ല';

  @override
  String get gpsError => 'GPS പിശക് സംഭവിച്ചു';

  @override
  String get pleaseCheckLocationSettings =>
      'ദയവായി നിങ്ങളുടെ ലൊക്കേഷൻ സെറ്റിംഗുകൾ പരിശോധിക്കുക';
}

class AppLocalizationsKn extends AppLocalizations {
  AppLocalizationsKn() : super('kn');

  @override
  String get appTitle => 'ಭೂ ನಕ್ಷೆ';

  @override
  String get landMapping => 'ಭೂ ನಕ್ಷೆ ತಯಾರಿಕೆ';

  @override
  String get home => 'ಮುಖ್ಯ';

  @override
  String get map => 'ನಕ್ಷೆ';

  @override
  String get camera => 'ಕ್ಯಾಮರ';

  @override
  String get settings => 'ಸೆಟ್ಟಿಂಗ್ಸ್';

  @override
  String get profile => 'ಪ್ರೊಫೈಲ್';

  @override
  String get location => 'ಸ್ಥಳ';

  @override
  String get latitude => 'ಅಕ್ಷಾಂಶ';

  @override
  String get longitude => 'ದೀರ್ಘಾಂಶ';

  @override
  String get accuracy => 'ನಿಖರತೆ';

  @override
  String get altitude => 'ಆಂತರಿಕ';

  @override
  String get getCurrentLocation => 'ಪ್ರಸ್ತುತ ಸ್ಥಳವನ್ನು ಪಡೆಯಿರಿ';

  @override
  String get locationPermissionRequired => 'ಸ್ಥಳದ ಅನುಮತಿ ಬೇಕು';

  @override
  String get enableLocationServices => 'ದಯವಿಟ್ಟು ಸ್ಥಳದ ಸೇವೆಗಳನ್ನು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get takePhoto => 'ಚಿತ್ರ ತೆಗೆಯಿರಿ';

  @override
  String get gallery => 'ಗ್ಯಾಲರಿ';

  @override
  String get captureImage => 'ಚಿತ್ರ ಪಡೆಯಿರಿ';

  @override
  String get analyzeImage => 'ಚಿತ್ರವನ್ನು ವಿಶ್ಲೇಷಿಸಿ';

  @override
  String get imageAnalysis => 'ಚಿತ್ರ ವಿಶ್ಲೇಷಣೆ';

  @override
  String get cameraPermissionRequired => 'ಕ್ಯಾಮರಾ ಅನುಮತಿ ಬೇಕು';

  @override
  String get analyzing => 'ವಿಶ್ಲೇಷಣೆ ನಡೆಯುತ್ತಿದೆ...';

  @override
  String get analysisComplete => 'ವಿಶ್ಲೇಷಣೆ ಪೂರ್ಣಗೊಂಡಿದೆ';

  @override
  String get landFeatures => 'ಭೂ ವಿಶೇಷತೆಗಳು';

  @override
  String get vegetation => 'ಸಸ್ಯಸಂಪತ್ತು';

  @override
  String get waterBodies => 'ನೀರಿನ ಸಂಗ್ರಹ';

  @override
  String get elevation => 'ಆಂತರಿಕ';

  @override
  String get soilType => 'ಮಣ್ಣಿನ ರೀತಿ';

  @override
  String get mapView => 'ನಕ್ಷೆ ವೀಕ್ಷಣೆ';

  @override
  String get addPoint => 'ಬಿಂದುವನ್ನು ಸೇರಿಸಿ';

  @override
  String get savedPoints => 'ಉಳಿಸಿದ ಬಿಂದುಗಳು';

  @override
  String get pointDetails => 'ಬಿಂದುವಿನ ವಿವರಗಳು';

  @override
  String get annotations => 'ಟಿಪ್ಪಣಿಗಳು';

  @override
  String get offlineMode => 'ಆಫ್ಲೈನ್ ಮೋಡ್';

  @override
  String get save => 'ಉಳಿಸಿ';

  @override
  String get export => 'ಎಕ್ಸ್ಪೋರ್ಟ್';

  @override
  String get delete => 'ಅಳಿಸಿ';

  @override
  String get sync => 'ಸಿಂಕ್';

  @override
  String get exportCsv => 'CSV ಎಕ್ಸ್ಪೋರ್ಟ್';

  @override
  String get exportJson => 'JSON ಎಕ್ಸ್ಪೋರ್ಟ್';

  @override
  String get exportPdf => 'PDF ಎಕ್ಸ್ಪೋರ್ಟ್';

  @override
  String get ok => 'ಸರಿ';

  @override
  String get cancel => 'ರದ್ದು ಮಾಡಿ';

  @override
  String get error => 'ತಪ್ಪು';

  @override
  String get success => 'ಯಶಸ್ಸು';

  @override
  String get loading => 'ಲೋಡ್ ಆಗುತ್ತಿದೆ...';

  @override
  String get noData => 'ಡೇಟಾ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get retry => 'ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get language => 'ಭಾಷೆ';

  @override
  String get selectLanguage => 'ಭಾಷೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get theme => 'ಥೀಮ್';

  @override
  String get selectTheme => 'ಥೀಮ್ ಆಯ್ಕೆ ಮಾಡಿ';

  @override
  String get darkMode => 'ಡಾರ್ಕ್ ಮೋಡ್';

  @override
  String get about => 'ಪ್ರತಿ';

  @override
  String get languageChanged => 'ಭಾಷೆ ಬದಲಾಯಿತು';

  @override
  String get system => 'ಸಿಸ್ಟಮ್';

  @override
  String get light => 'ಲೈಟ್';

  @override
  String get dark => 'ಡಾರ್ಕ್';

  @override
  String get search => 'ಹುಡುಕಿ';

  @override
  String get searchSavedPoints => 'ಉಳಿಸಿದ ಬಿಂದುಗಳನ್ನು ಹುಡುಕಿ';

  @override
  String get sortBy => 'ಸರಿಹೊಂದಿಸಿ';

  @override
  String get date => 'ದಿನಾಂಕ';

  @override
  String get name => 'ಹೆಸರು';

  @override
  String get ascending => 'ಆರೋಹಿ';

  @override
  String get descending => 'ಅವರೋಹಿ';

  @override
  String get close => 'ಮುಚ್ಚಿ';

  @override
  String get deletePoint => 'ಬಿಂದುವನ್ನು ತೆಗೆದುಹಾಕಿ';

  @override
  String get deleteConfirmation => 'ತೆಗೆದುಹಾಕಲು ಖಚಿತಪಡಿಸಿ';

  @override
  String get areYouSureDeletePoint =>
      'ನೀವು ಈ ಬಿಂದುವನ್ನು ತೆಗೆದುಹಾಕಲು ಖಚಿತವಾಗಿದ್ದೀರಾ?';

  @override
  String get pointDeletedSuccessfully =>
      'ಬಿಂದುವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ತೆಗೆದುಹಾಕಲಾಗಿದೆ';

  @override
  String get errorDeletingPoint => 'ಬಿಂದುವನ್ನು ತೆಗೆದುಹಾಕುವಲ್ಲಿ ತಪ್ಪು';

  @override
  String get errorLoadingSavedPoints =>
      'ಉಳಿಸಿದ ಬಿಂದುಗಳನ್ನು ಲೋಡ್ ಮಾಡುವಲ್ಲಿ ತಪ್ಪು';

  @override
  String get noPointsFound => 'ಬಿಂದುಗಳು ಕಂಡುಬಾರದಿದೆ';

  @override
  String get noSavedPointsYet => 'ಅದುವರೆಗೂ ಯಾವುದೇ ಬಿಂದುಗಳು ಉಳಿಸಲ್ಪಟ್ಟಿಲ್ಲ';

  @override
  String get tryAdjustingSearch =>
      'ಹುಡುಕುವಿಕೆಯನ್ನು ಸರಿಹೊಂದಿಸಿ ಮತ್ತೆ ಪ್ರಯತ್ನಿಸಿ';

  @override
  String get startCapturingPoints =>
      'ಬಿಂದುಗಳನ್ನು ಪತ್ತೆ ಹಚ್ಚುವುದನ್ನು ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get unnamedPoint => 'ಹೆಸರಿಲ್ಲದ ಬಿಂದುವು';

  @override
  String get analysisResults => 'ವಿಶ್ಲೇಷಣೆ ಫಲಿತಾಂಶಗಳು';

  @override
  String get landFeature => 'ಭೂಮಿಯ ವಿಶೇಷತೆ';

  @override
  String get vegetationCoverage => 'ಸಸ್ಯಸಂಪತ್ತು ಆವರಣ';

  @override
  String get waterCoverage => 'ನೀರಿನ ಆವರಣ';

  @override
  String get elevationEstimate => 'ಆಂತರಿಕ ಅಂದಾಜು';

  @override
  String get confidence => 'ವಿಶ್ವಾಸ';

  @override
  String get notes => 'ಟಿಪ್ಪಣಿಗಳು';

  @override
  String get useDarkTheme => 'ಡಾರ್ಕ್ ಥೀಮ್ ಬಳಸಿ';

  @override
  String get landMapVersion => 'ಭೂಮಿ ನಕ್ಷೆ ಆವೃತ್ತಿ';

  @override
  String get aiPoweredDescription => 'AI ಪ್ರವರ್ತಿತ ವಿವರಣೆ';

  @override
  String get photoCapturedSuccessfully =>
      'ಫೋಟೋ ಯಶಸ್ವಿಯಾಗಿ ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿ ಸೇವ್ ಮಾಡಲಾಗಿದೆ!';

  @override
  String get errorCapturingPhoto => 'ಫೋಟೋ ಕ್ಯಾಪ್ಚರ್ ಮಾಡುವಲ್ಲಿ ತಪ್ಪು';

  @override
  String get imageImportedSuccessfully =>
      'ಇಮೇಜ್ ಯಶಸ್ವಿಯಾಗಿ ಇಂಪೋರ್ಟ್ ಮಾಡಲಾಗಿದೆ!';

  @override
  String get errorImportingImage => 'ಇಮೇಜ್ ಇಂಪೋರ್ಟ್ ಮಾಡುವಲ್ಲಿ ತಪ್ಪು';

  @override
  String get cannotSwitchCamera => 'ಕ್ಯಾಮೆರಾ ಬದಲಾಯಿಸಲು ಸಾಧ್ಯವಿಲ್ಲ';

  @override
  String get initializingCamera => 'ಕ್ಯಾಮೆರಾ ಆರಂಭಿಸಲಾಗುತ್ತಿದೆ...';

  @override
  String get cameraNotAvailable => 'ಕ್ಯಾಮೆರಾ ಲಭ್ಯವಿಲ್ಲ';

  @override
  String get routeNotFound => 'ಮಾರ್ಗ ಕಂಡುಬಂದಿಲ್ಲ';

  // Map & Walk Mode
  @override
  String get walkMode => 'ನಡಿಗೆ ಮೋಡ್';

  @override
  String get startWalk => 'ನಡಿಗೆ ಪ್ರಾರಂಭಿಸಿ';

  @override
  String get stopWalk => 'ನಡಿಗೆ ನಿಲ್ಲಿಸಿ';

  @override
  String get capturePoint => 'ಪಾಯಿಂಟ್ ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿ';

  @override
  String get walkDistance => 'ನಡಿಗೆ ದೂರ';

  @override
  String get points => 'ಪಾಯಿಂಟ್‌ಗಳು';

  @override
  String get pointsCaptured => 'ಪಾಯಿಂಟ್‌ಗಳನ್ನು ಕ್ಯಾಪ್ಚರ್ ಮಾಡಲಾಗಿದೆ';

  @override
  String get pointCapture => 'ಪಾಯಿಂಟ್ ಕ್ಯಾಪ್ಚರ್';

  @override
  String get area => 'ಪ್ರದೇಶ';

  @override
  String get perimeter => 'ಪರಿಧಿ';

  @override
  String get areaName => 'ಪ್ರದೇಶದ ಹೆಸರು';

  @override
  String get areaNameRequired => 'ಪ್ರದೇಶದ ಹೆಸರು ಅಗತ್ಯವಿದೆ';

  @override
  String get pleaseEnterAreaName => 'ದಯವಿಟ್ಟು ಪ್ರದೇಶದ ಹೆಸರನ್ನು ನಮೂದಿಸಿ';

  @override
  String get description => 'ವಿವರಣೆ';

  @override
  String get optional => 'ಐಚ್ಛಿಕ';

  @override
  String get capturedPoints => 'ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿದ ಪಾಯಿಂಟ್‌ಗಳು';

  @override
  String get saveArea => 'ಪ್ರದೇಶವನ್ನು ಉಳಿಸಿ';

  @override
  String get savingArea => 'ಪ್ರದೇಶವನ್ನು ಉಳಿಸಲಾಗುತ್ತಿದೆ';

  @override
  String get areaSavedSuccessfully => 'ಪ್ರದೇಶವನ್ನು ಯಶಸ್ವಿಯಾಗಿ ಉಳಿಸಲಾಗಿದೆ';

  @override
  String get walkModeStarted => 'ನಡಿಗೆ ಮೋಡ್ ಪ್ರಾರಂಭವಾಗಿದೆ';

  @override
  String get walkModeStopped => 'ನಡಿಗೆ ಮೋಡ್ ನಿಲ್ಲಿಸಲಾಗಿದೆ';

  @override
  String get highAccuracyGPS => 'ಉನ್ನತ ನಿಖರತೆ GPS ಸಕ್ರಿಯಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get tapCaptureToAddPoints =>
      'ಪಾಯಿಂಟ್‌ಗಳನ್ನು ಸೇರಿಸಲು "ಕ್ಯಾಪ್ಚರ್" ಟ್ಯಾಪ್ ಮಾಡಿ';

  @override
  String get minimumDistance => 'ಕನಿಷ್ಠ ದೂರ';

  @override
  String get distanceWalked => 'ನಡೆದ ದೂರ';

  @override
  String get normalView => 'ಸಾಮಾನ್ಯ ನೋಟ';

  @override
  String get satelliteView => 'ಉಪಗ್ರಹ ನೋಟ';

  @override
  String get pointMustBeAway => 'ಪಾಯಿಂಟ್ ಕನಿಷ್ಠ';

  @override
  String get moveAtLeast => 'ಕನಿಷ್ಠ ಚಲಿಸಿ';

  @override
  String get fromLastPoint => 'ಕೊನೆಯ ಪಾಯಿಂಟ್‌ನಿಂದ';

  @override
  String get pointTooClose => 'ಪಾಯಿಂಟ್ ತುಂಬಾ ಹತ್ತಿರದಲ್ಲಿದೆ';

  @override
  String get lowGPSAccuracy => 'ಕಡಿಮೆ GPS ನಿಖರತೆ';

  @override
  String get moveToOpenArea => 'ತೆರೆದ ಆಕಾಶದೊಂದಿಗೆ ಸ್ಪಷ್ಟ ಪ್ರದೇಶಕ್ಕೆ ಹೋಗಿ';

  @override
  String get gettingBetterGPS => 'ಉತ್ತಮ GPS ಪಡೆಯುತ್ತಿದೆ... ದಯವಿಟ್ಟು ಕಾಯಿರಿ';

  @override
  String get pointCapturedSuccessfully => 'ಪಾಯಿಂಟ್ ಯಶಸ್ವಿಯಾಗಿ ಕ್ಯಾಪ್ಚರ್ ಆಗಿದೆ';

  @override
  String get distanceFromLastPoint => 'ಕೊನೆಯ ಪಾಯಿಂಟ್‌ನಿಂದ ದೂರ';

  @override
  String get navigatingToPoint => 'ಪಾಯಿಂಟ್‌ಗೆ ನ್ಯಾವಿಗೇಟ್ ಮಾಡುತ್ತಿದೆ';

  @override
  String get allPointsCleared =>
      'ಎಲ್ಲಾ ಪಾಯಿಂಟ್‌ಗಳು ಮತ್ತು ಮಾರ್ಗಗಳನ್ನು ತೆರವುಗೊಳಿಸಲಾಗಿದೆ';

  @override
  String get currentPoints => 'ಪ್ರಸ್ತುತ ಪಾಯಿಂಟ್‌ಗಳು';

  @override
  String get pointsAdded => 'ಪಾಯಿಂಟ್‌ಗಳನ್ನು ಸೇರಿಸಲಾಗಿದೆ';

  @override
  String get noPointsCaptured => 'ಯಾವುದೇ ಪಾಯಿಂಟ್‌ಗಳನ್ನು ಕ್ಯಾಪ್ಚರ್ ಮಾಡಿಲ್ಲ';

  @override
  String get clearAll => 'ಎಲ್ಲವನ್ನೂ ತೆರವುಗೊಳಿಸಿ';

  @override
  String get viewPoints => 'ಪಾಯಿಂಟ್‌ಗಳನ್ನು ನೋಡಿ';

  @override
  String get navigateTo => 'ನ್ಯಾವಿಗೇಟ್ ಮಾಡಿ';

  @override
  String get meters => 'ಮೀಟರ್‌ಗಳು';

  @override
  String get squareMeters => 'ಚದರ ಮೀಟರ್‌ಗಳು';

  @override
  String get corners => 'ಮೂಲೆಗಳು';

  @override
  String get atLeastThreePoints =>
      'ಪ್ರದೇಶವನ್ನು ಉಳಿಸಲು ಕನಿಷ್ಠ 3 ಪಾಯಿಂಟ್‌ಗಳು ಬೇಕಾಗುತ್ತವೆ';

  @override
  String get areaSummary => 'ಪ್ರದೇಶದ ಸಾರಾಂಶ';

  @override
  String get walkStarted => 'ನಡಿಗೆ ಪ್ರಾರಂಭವಾಗಿದೆ';

  @override
  String get unableToDetermineLocation =>
      'ಪ್ರಸ್ತುತ ಸ್ಥಾನವನ್ನು ನಿರ್ಧರಿಸಲು ಸಾಧ್ಯವಾಗಿಲ್ಲ';

  @override
  String get gpsError => 'GPS ದೋಷ ಸಂಭವಿಸಿದೆ';

  @override
  String get pleaseCheckLocationSettings =>
      'ದಯವಿಟ್ಟು ನಿಮ್ಮ ಸ್ಥಾನ ಸೆಟ್ಟಿಂಗ್‌ಗಳನ್ನು ಪರಿಶೀಲಿಸಿ';
}
