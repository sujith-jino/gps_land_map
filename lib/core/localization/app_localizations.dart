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
}
