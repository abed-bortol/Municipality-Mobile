import 'package:flutter/widgets.dart';

/// Lightweight bilingual strings, mirroring the website's `t()` keys
/// (`LanguageContext.tsx`) and the inline texts of `LoginPage.tsx`.
/// Add new keys here as screens are ported.
class AppStrings {
  const AppStrings._(this.languageCode);

  final String languageCode;

  static const supportedLocales = [Locale('en'), Locale('ar')];

  static AppStrings of(BuildContext context) =>
      AppStrings._(Localizations.localeOf(context).languageCode);

  bool get isAr => languageCode == 'ar';

  String _t(String key) => _strings[key]![isAr ? 'ar' : 'en']!;

  // App
  String get appTitle => _t('appTitle');
  String get appSubtitle => _t('appSubtitle');
  String get country => _t('country');
  String get municipality => _t('municipality');
  String get directorate => _t('directorate');
  String get loading => _t('loading');
  String get otherLanguage => _t('otherLanguage');
  String get footer => _t('footer');

  // Auth
  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get signOut => _t('signOut');
  String get signInTitle => _t('signInTitle');
  String get signInSubtitle => _t('signInSubtitle');
  String get signUpTitle => _t('signUpTitle');
  String get signUpSubtitle => _t('signUpSubtitle');
  String get email => _t('email');
  String get password => _t('password');
  String get confirmPassword => _t('confirmPassword');
  String get fullName => _t('fullName');
  String get fullNameHint => _t('fullNameHint');
  String get phone => _t('phone');
  String get optional => _t('optional');
  String get district => _t('district');
  String get showPassword => _t('showPassword');
  String get hidePassword => _t('hidePassword');
  String get signingIn => _t('signingIn');
  String get creatingAccount => _t('creatingAccount');
  String get createAccountAndEnter => _t('createAccountAndEnter');
  String get errEmailRequired => _t('errEmailRequired');
  String get errEmailInvalid => _t('errEmailInvalid');
  String get errPasswordRequired => _t('errPasswordRequired');
  String get errNameRequired => _t('errNameRequired');
  String get errPasswordShort => _t('errPasswordShort');
  String get errPasswordMismatch => _t('errPasswordMismatch');
  String get errNetwork => _t('errNetwork');
  String get errInvalidCredentials => _t('errInvalidCredentials');
  String get errAccountDeactivated => _t('errAccountDeactivated');
  String get errUserExists => _t('errUserExists');
  String get errUnexpected => _t('errUnexpected');
  String get signInSuccess => _t('signInSuccess');
  String get signUpSuccess => _t('signUpSuccess');
  String get signedOut => _t('signedOut');
  String get sessionExpired => _t('sessionExpired');
  String get signOutConfirmTitle => _t('signOutConfirmTitle');
  String get signOutConfirmBody => _t('signOutConfirmBody');
  String get cancel => _t('cancel');

  String role(String apiRole) => _roles[apiRole]?[isAr ? 'ar' : 'en'] ?? apiRole;

  String districtName(String district) =>
      isAr ? (_districtsAr[district] ?? district) : district;

  /// `TRIPOLI_DISTRICTS` from the website's APIConst.ts.
  static const districts = [
    'Al-Tal',
    'Al-Mina',
    'Bab Al-Tabbaneh',
    'Jabal Mohsen',
    'Abu Samra',
    'Al-Qobbeh',
    'Dam w Farez',
    'Beddawi',
    'Zahrieh',
    'Maarad',
    'Mina Port',
    'Haddadine',
    'Swayqa',
    'Azmi Street',
    'Bab Al-Ramel',
  ];

  static const _districtsAr = {
    'Al-Tal': 'التل',
    'Al-Mina': 'الميناء',
    'Bab Al-Tabbaneh': 'باب التبانة',
    'Jabal Mohsen': 'جبل محسن',
    'Abu Samra': 'أبي سمراء',
    'Al-Qobbeh': 'القبة',
    'Dam w Farez': 'ضم وفرز',
    'Beddawi': 'البداوي',
    'Zahrieh': 'الزاهرية',
    'Maarad': 'المعرض',
    'Mina Port': 'مرفأ الميناء',
    'Haddadine': 'الحدادين',
    'Swayqa': 'السويقة',
    'Azmi Street': 'شارع عزمي',
    'Bab Al-Ramel': 'باب الرمل',
  };

  static const _roles = {
    'CITIZEN': {'en': 'Citizen', 'ar': 'مواطن مبلّغ'},
    'HEALTH_OFFICER': {'en': 'Health Officer', 'ar': 'مراقب صحي'},
    'ADMINISTRATOR': {'en': 'Administrator', 'ar': 'مدير صحي بلدي'},
  };

  static const _strings = <String, Map<String, String>>{
    'appTitle': {'en': 'Tripoli HealthPulse', 'ar': 'نبض طرابلس الصحي'},
    'appSubtitle': {
      'en': 'Smart Public Health Surveillance & Reporting',
      'ar': 'المنظومة الذكية للرصد والإبلاغ عن الصحة العامة',
    },
    'country': {'en': 'Lebanon', 'ar': 'لبنان'},
    'municipality': {
      'en': 'MUNICIPALITY OF GREATER TRIPOLI',
      'ar': 'بلدية طرابلس الكبرى',
    },
    'directorate': {
      'en': 'Greater Tripoli Health Directorate',
      'ar': 'بلدية طرابلس الكبرى • الرقابة الصحية',
    },
    'loading': {'en': 'Loading…', 'ar': 'جارٍ التحميل…'},
    'otherLanguage': {'en': 'العربية', 'ar': 'English'},
    'footer': {
      'en': 'Tripoli HealthPulse System • Tripoli Municipality, North Lebanon',
      'ar': 'منظومة نبض طرابلس الصحي • بلدية طرابلس، شمال لبنان',
    },
    'signIn': {'en': 'Sign In', 'ar': 'تسجيل الدخول'},
    'signUp': {'en': 'Sign Up', 'ar': 'إنشاء حساب'},
    'signOut': {'en': 'Sign Out', 'ar': 'تسجيل الخروج'},
    'signInTitle': {'en': 'Sign In to Portal', 'ar': 'تسجيل الدخول للمنظومة'},
    'signInSubtitle': {
      'en': 'Enter your credentials to access health surveillance dashboard',
      'ar': 'أدخل بياناتك للوصول إلى لوحة المتابعة والرصد الصحي',
    },
    'signUpTitle': {'en': 'Create New Account', 'ar': 'إنشاء حساب جديد'},
    'signUpSubtitle': {
      'en': 'Register your profile in the live Tripoli health database',
      'ar': 'سجّل حسابك في قاعدة البيانات المباشرة لمدينة طرابلس',
    },
    'email': {'en': 'Email Address', 'ar': 'البريد الإلكتروني'},
    'password': {'en': 'Password', 'ar': 'كلمة المرور'},
    'confirmPassword': {'en': 'Confirm Password', 'ar': 'تأكيد كلمة المرور'},
    'fullName': {'en': 'Full Name', 'ar': 'الاسم الكامل'},
    'fullNameHint': {'en': 'e.g. Samer Karami', 'ar': 'مثال: سامر كرامي'},
    'phone': {'en': 'Phone', 'ar': 'رقم الهاتف'},
    'optional': {'en': 'optional', 'ar': 'اختياري'},
    'district': {'en': 'District in Tripoli', 'ar': 'الحي في طرابلس'},
    'showPassword': {'en': 'Show password', 'ar': 'إظهار كلمة المرور'},
    'hidePassword': {'en': 'Hide password', 'ar': 'إخفاء كلمة المرور'},
    'signingIn': {'en': 'Signing In...', 'ar': 'جاري التحقق...'},
    'creatingAccount': {'en': 'Creating Account...', 'ar': 'جاري التسجيل...'},
    'createAccountAndEnter': {
      'en': 'Create Account & Enter',
      'ar': 'إنشاء الحساب ودخول المنظومة',
    },
    'errEmailRequired': {
      'en': 'Please enter your email.',
      'ar': 'يرجى إدخال البريد الإلكتروني.',
    },
    'errEmailInvalid': {
      'en': 'Please enter a valid email address.',
      'ar': 'يرجى إدخال بريد إلكتروني صالح.',
    },
    'errPasswordRequired': {
      'en': 'Please enter your password.',
      'ar': 'يرجى إدخال كلمة المرور.',
    },
    'errNameRequired': {
      'en': 'Please provide full name.',
      'ar': 'يرجى إدخال الاسم الكامل.',
    },
    'errPasswordShort': {
      'en': 'Password must be at least 6 characters.',
      'ar': 'يجب أن تتكون كلمة المرور من 6 أحرف على الأقل.',
    },
    'errPasswordMismatch': {
      'en': 'Passwords do not match.',
      'ar': 'كلمتا المرور غير متطابقتين.',
    },
    'errNetwork': {
      'en': 'Cannot reach the server. Check your connection and try again.',
      'ar': 'تعذّر الاتصال بالخادم. تحقق من اتصالك وحاول مجدداً.',
    },
    'errInvalidCredentials': {
      'en': 'Invalid email or password.',
      'ar': 'البريد الإلكتروني أو كلمة المرور غير صحيحة.',
    },
    'errAccountDeactivated': {
      'en': 'This account has been deactivated. Contact the Health Directorate.',
      'ar': 'تم تعطيل هذا الحساب. يرجى التواصل مع مديرية الصحة.',
    },
    'errUserExists': {
      'en': 'An account with this email or phone already exists.',
      'ar': 'يوجد حساب مسجل بهذا البريد الإلكتروني أو رقم الهاتف.',
    },
    'errUnexpected': {
      'en': 'Something went wrong. Please try again.',
      'ar': 'حدث خطأ ما. يرجى المحاولة مجدداً.',
    },
    'signInSuccess': {
      'en': 'Signed in successfully! Welcome to Tripoli HealthPulse.',
      'ar': 'تم تسجيل الدخول بنجاح! مرحباً بك في نبض طرابلس الصحي.',
    },
    'signUpSuccess': {
      'en': 'Citizen account registered successfully!',
      'ar': 'تم إنشاء حساب المواطن بنجاح وتسجيل الدخول.',
    },
    'signedOut': {
      'en': 'Logged out successfully.',
      'ar': 'تم تسجيل الخروج بنجاح.',
    },
    'sessionExpired': {
      'en': 'Your session has expired. Please sign in again.',
      'ar': 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
    },
    'signOutConfirmTitle': {'en': 'Sign out?', 'ar': 'تسجيل الخروج؟'},
    'signOutConfirmBody': {
      'en': 'You will need to sign in again to access the portal.',
      'ar': 'ستحتاج إلى تسجيل الدخول مجدداً للوصول إلى المنظومة.',
    },
    'cancel': {'en': 'Cancel', 'ar': 'إلغاء'},
  };
}
