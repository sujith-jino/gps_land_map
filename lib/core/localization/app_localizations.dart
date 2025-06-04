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
      <String>['en', 'ta'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'ta':
      return AppLocalizationsTa();
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
  String get latitude => 'அட்சாங்சம்';

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
}
