import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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
  static const List<Locale> supportedLocales = <Locale>[Locale('ar')];

  /// No description provided for @appTitle.
  ///
  /// In ar, this message translates to:
  /// **'دروس'**
  String get appTitle;

  /// No description provided for @commonSave.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// No description provided for @commonSearch.
  ///
  /// In ar, this message translates to:
  /// **'بحث'**
  String get commonSearch;

  /// No description provided for @commonLoading.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ التحميل...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ ما'**
  String get commonError;

  /// No description provided for @commonRetry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get commonRetry;

  /// No description provided for @commonName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get commonName;

  /// No description provided for @commonNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات'**
  String get commonNotes;

  /// No description provided for @commonDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get commonDate;

  /// No description provided for @commonNone.
  ///
  /// In ar, this message translates to:
  /// **'لا شيء'**
  String get commonNone;

  /// No description provided for @commonRequired.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get commonRequired;

  /// No description provided for @commonYes.
  ///
  /// In ar, this message translates to:
  /// **'نعم'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In ar, this message translates to:
  /// **'لا'**
  String get commonNo;

  /// No description provided for @commonConfirmDelete.
  ///
  /// In ar, this message translates to:
  /// **'هل أنت متأكد من الحذف؟'**
  String get commonConfirmDelete;

  /// No description provided for @commonOptional.
  ///
  /// In ar, this message translates to:
  /// **'اختياري'**
  String get commonOptional;

  /// No description provided for @commonBack.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// No description provided for @commonEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات بعد'**
  String get commonEmpty;

  /// No description provided for @authWelcome.
  ///
  /// In ar, this message translates to:
  /// **'أهلاً بك في دروس'**
  String get authWelcome;

  /// No description provided for @authSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق إدارة الدروس الخصوصية'**
  String get authSubtitle;

  /// No description provided for @authSignin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get authSignin;

  /// No description provided for @authSignup.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب جديد'**
  String get authSignup;

  /// No description provided for @authEmail.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get authEmail;

  /// No description provided for @authPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get authPassword;

  /// No description provided for @authFullName.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get authFullName;

  /// No description provided for @authSignInButton.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get authSignInButton;

  /// No description provided for @authSignUpButton.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authSignUpButton;

  /// No description provided for @authHaveAccount.
  ///
  /// In ar, this message translates to:
  /// **'لديك حساب؟ سجّل الدخول'**
  String get authHaveAccount;

  /// No description provided for @authNoAccount.
  ///
  /// In ar, this message translates to:
  /// **'ليس لديك حساب؟ أنشئ حساباً'**
  String get authNoAccount;

  /// No description provided for @authInvalidCredentials.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدخول غير صحيحة'**
  String get authInvalidCredentials;

  /// No description provided for @authWrongFlow.
  ///
  /// In ar, this message translates to:
  /// **'يبدو أن هذا الحساب غير مكتمل — تحقق من الإعداد'**
  String get authWrongFlow;

  /// No description provided for @authCheckEmail.
  ///
  /// In ar, this message translates to:
  /// **'أرسلنا رابط التأكيد — تحقق من بريدك الإلكتروني'**
  String get authCheckEmail;

  /// No description provided for @authInvalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'عنوان البريد الإلكتروني غير صحيح'**
  String get authInvalidEmail;

  /// No description provided for @authRateLimited.
  ///
  /// In ar, this message translates to:
  /// **'طلبات كثيرة — حاول مجدداً بعد قليل'**
  String get authRateLimited;

  /// No description provided for @authUserExists.
  ///
  /// In ar, this message translates to:
  /// **'هذا البريد مسجّل مسبقاً — سجّل الدخول'**
  String get authUserExists;

  /// No description provided for @authEmailNotConfirmed.
  ///
  /// In ar, this message translates to:
  /// **'يرجى تأكيد بريدك الإلكتروني أولاً'**
  String get authEmailNotConfirmed;

  /// No description provided for @authForgotPassword.
  ///
  /// In ar, this message translates to:
  /// **'نسيت كلمة المرور؟'**
  String get authForgotPassword;

  /// No description provided for @authResetDialogTitle.
  ///
  /// In ar, this message translates to:
  /// **'استعادة كلمة المرور'**
  String get authResetDialogTitle;

  /// No description provided for @authResetSent.
  ///
  /// In ar, this message translates to:
  /// **'إذا كان البريد مسجلاً، ستصلك رسالة بها رابط إعادة تعيين كلمة المرور'**
  String get authResetSent;

  /// No description provided for @authResetButton.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرابط'**
  String get authResetButton;

  /// No description provided for @onboardingTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعداد المركز'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'اختر طريقة العمل'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingSingle.
  ///
  /// In ar, this message translates to:
  /// **'معلم واحد — أدير دروسي بنفسي'**
  String get onboardingSingle;

  /// No description provided for @onboardingMulti.
  ///
  /// In ar, this message translates to:
  /// **'عدة معلمين — أنا المدير وأضيف معلمين'**
  String get onboardingMulti;

  /// No description provided for @onboardingCreatorName.
  ///
  /// In ar, this message translates to:
  /// **'اسمك'**
  String get onboardingCreatorName;

  /// No description provided for @onboardingTokenTitle.
  ///
  /// In ar, this message translates to:
  /// **'رمز الدعوة'**
  String get onboardingTokenTitle;

  /// No description provided for @onboardingTokenHint.
  ///
  /// In ar, this message translates to:
  /// **'الصق رمز الدعوة الذي وصلك من المدير'**
  String get onboardingTokenHint;

  /// No description provided for @onboardingTokenSubmit.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام إلى المركز'**
  String get onboardingTokenSubmit;

  /// No description provided for @onboardingWelcomeSingle.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز حسابك — أضف المواد والطلاب من الشاشة الرئيسية'**
  String get onboardingWelcomeSingle;

  /// No description provided for @onboardingWelcomeMulti.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز حسابك كمدير — أضف المعلمين من الإعدادات'**
  String get onboardingWelcomeMulti;

  /// No description provided for @navHome.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get navHome;

  /// No description provided for @navSchedule.
  ///
  /// In ar, this message translates to:
  /// **'الجدول'**
  String get navSchedule;

  /// No description provided for @navStudents.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get navStudents;

  /// No description provided for @navSubjects.
  ///
  /// In ar, this message translates to:
  /// **'المواد'**
  String get navSubjects;

  /// No description provided for @navFees.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط'**
  String get navFees;

  /// No description provided for @navSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get navSettings;

  /// No description provided for @homeTodaySessions.
  ///
  /// In ar, this message translates to:
  /// **'جلسات اليوم'**
  String get homeTodaySessions;

  /// No description provided for @homeNoSessions.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات اليوم'**
  String get homeNoSessions;

  /// No description provided for @homeMarkPresent.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get homeMarkPresent;

  /// No description provided for @homeMarkAbsent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get homeMarkAbsent;

  /// No description provided for @homeMarkRescheduled.
  ///
  /// In ar, this message translates to:
  /// **'مؤجّلة'**
  String get homeMarkRescheduled;

  /// No description provided for @homeStudent.
  ///
  /// In ar, this message translates to:
  /// **'الطالب'**
  String get homeStudent;

  /// No description provided for @homeSubject.
  ///
  /// In ar, this message translates to:
  /// **'المادة'**
  String get homeSubject;

  /// No description provided for @homeLocation.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get homeLocation;

  /// No description provided for @homeAttendanceSaved.
  ///
  /// In ar, this message translates to:
  /// **'تم تسجيل الحضور'**
  String get homeAttendanceSaved;

  /// No description provided for @homeAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'إعلانات'**
  String get homeAnnouncements;

  /// No description provided for @studentsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الطلاب'**
  String get studentsTitle;

  /// No description provided for @studentsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد طلاب بعد — أضف أول طالب'**
  String get studentsEmpty;

  /// No description provided for @studentsAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة طالب'**
  String get studentsAddTitle;

  /// No description provided for @studentsEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل طالب'**
  String get studentsEditTitle;

  /// No description provided for @studentsGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف'**
  String get studentsGrade;

  /// No description provided for @studentsBirthYear.
  ///
  /// In ar, this message translates to:
  /// **'سنة الميلاد'**
  String get studentsBirthYear;

  /// No description provided for @studentsParentName.
  ///
  /// In ar, this message translates to:
  /// **'اسم ولي الأمر'**
  String get studentsParentName;

  /// No description provided for @studentsParentPhone.
  ///
  /// In ar, this message translates to:
  /// **'هاتف ولي الأمر'**
  String get studentsParentPhone;

  /// No description provided for @studentsLocation.
  ///
  /// In ar, this message translates to:
  /// **'مكان الدرس الافتراضي'**
  String get studentsLocation;

  /// No description provided for @studentsLocationHome.
  ///
  /// In ar, this message translates to:
  /// **'عند الطالب'**
  String get studentsLocationHome;

  /// No description provided for @studentsLocationTeacher.
  ///
  /// In ar, this message translates to:
  /// **'عند المعلم'**
  String get studentsLocationTeacher;

  /// No description provided for @studentsAssignedTeacher.
  ///
  /// In ar, this message translates to:
  /// **'المعلم المسؤول'**
  String get studentsAssignedTeacher;

  /// No description provided for @studentsParentLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط ولي الأمر'**
  String get studentsParentLink;

  /// No description provided for @studentsParentLinkEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ رابطاً ليطلع ولي الأمر على الحضور والأقساط'**
  String get studentsParentLinkEmpty;

  /// No description provided for @studentsGenerateLink.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء رابط'**
  String get studentsGenerateLink;

  /// No description provided for @studentsCopyLink.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get studentsCopyLink;

  /// No description provided for @studentsLinkCopied.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرابط'**
  String get studentsLinkCopied;

  /// No description provided for @studentsSubjectsAssigned.
  ///
  /// In ar, this message translates to:
  /// **'المواد المسجّلة'**
  String get studentsSubjectsAssigned;

  /// No description provided for @studentsDetailTests.
  ///
  /// In ar, this message translates to:
  /// **'الاختبارات'**
  String get studentsDetailTests;

  /// No description provided for @studentsDetailNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get studentsDetailNotes;

  /// No description provided for @studentsDetailSlots.
  ///
  /// In ar, this message translates to:
  /// **'أوقات الجلسات'**
  String get studentsDetailSlots;

  /// No description provided for @studentsNoSubjects.
  ///
  /// In ar, this message translates to:
  /// **'لم تُسجَّل مواد بعد — عدّل الطالب لإضافة مواد'**
  String get studentsNoSubjects;

  /// No description provided for @subjectsTitle.
  ///
  /// In ar, this message translates to:
  /// **'المواد'**
  String get subjectsTitle;

  /// No description provided for @subjectsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مواد — أضف أول مادة'**
  String get subjectsEmpty;

  /// No description provided for @subjectsAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مادة'**
  String get subjectsAddTitle;

  /// No description provided for @subjectsEditTitle.
  ///
  /// In ar, this message translates to:
  /// **'تعديل مادة'**
  String get subjectsEditTitle;

  /// No description provided for @subjectsStudentsCount.
  ///
  /// In ar, this message translates to:
  /// **'عدد الطلاب'**
  String get subjectsStudentsCount;

  /// No description provided for @subjectsGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف'**
  String get subjectsGrade;

  /// No description provided for @scheduleTitle.
  ///
  /// In ar, this message translates to:
  /// **'جدول الجلسات'**
  String get scheduleTitle;

  /// No description provided for @scheduleAddSlot.
  ///
  /// In ar, this message translates to:
  /// **'إضافة موعد'**
  String get scheduleAddSlot;

  /// No description provided for @scheduleDay.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get scheduleDay;

  /// No description provided for @scheduleStart.
  ///
  /// In ar, this message translates to:
  /// **'البداية'**
  String get scheduleStart;

  /// No description provided for @scheduleEnd.
  ///
  /// In ar, this message translates to:
  /// **'النهاية'**
  String get scheduleEnd;

  /// No description provided for @scheduleLocation.
  ///
  /// In ar, this message translates to:
  /// **'المكان'**
  String get scheduleLocation;

  /// No description provided for @scheduleActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get scheduleActive;

  /// No description provided for @scheduleAllStudents.
  ///
  /// In ar, this message translates to:
  /// **'كل الطلاب'**
  String get scheduleAllStudents;

  /// No description provided for @scheduleSelectStudent.
  ///
  /// In ar, this message translates to:
  /// **'اختر الطالب'**
  String get scheduleSelectStudent;

  /// No description provided for @scheduleWeeklyTitle.
  ///
  /// In ar, this message translates to:
  /// **'جدول الأسبوع'**
  String get scheduleWeeklyTitle;

  /// No description provided for @schedulePrevWeek.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع السابق'**
  String get schedulePrevWeek;

  /// No description provided for @scheduleNextWeek.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع التالي'**
  String get scheduleNextWeek;

  /// No description provided for @scheduleThisWeek.
  ///
  /// In ar, this message translates to:
  /// **'هذا الأسبوع'**
  String get scheduleThisWeek;

  /// No description provided for @scheduleNoSlots.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات هذا اليوم'**
  String get scheduleNoSlots;

  /// No description provided for @scheduleRecurringSlot.
  ///
  /// In ar, this message translates to:
  /// **'موعد متكرر'**
  String get scheduleRecurringSlot;

  /// No description provided for @studentsDetailAttendance.
  ///
  /// In ar, this message translates to:
  /// **'سجل الحضور'**
  String get studentsDetailAttendance;

  /// No description provided for @studentsNoAttendance.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات مسجّلة بعد'**
  String get studentsNoAttendance;

  /// No description provided for @feesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الأقساط'**
  String get feesTitle;

  /// No description provided for @feesMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get feesMonth;

  /// No description provided for @feesAmount.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ'**
  String get feesAmount;

  /// No description provided for @feesPaid.
  ///
  /// In ar, this message translates to:
  /// **'المدفوع'**
  String get feesPaid;

  /// No description provided for @feesRemaining.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي'**
  String get feesRemaining;

  /// No description provided for @feesStatusPaid.
  ///
  /// In ar, this message translates to:
  /// **'مسدّد'**
  String get feesStatusPaid;

  /// No description provided for @feesStatusPartial.
  ///
  /// In ar, this message translates to:
  /// **'مسدّد جزئياً'**
  String get feesStatusPartial;

  /// No description provided for @feesStatusUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مسدّد'**
  String get feesStatusUnpaid;

  /// No description provided for @feesAddFee.
  ///
  /// In ar, this message translates to:
  /// **'إضافة قسط'**
  String get feesAddFee;

  /// No description provided for @feesAddPayment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل دفعة'**
  String get feesAddPayment;

  /// No description provided for @feesPaymentMethod.
  ///
  /// In ar, this message translates to:
  /// **'طريقة الدفع'**
  String get feesPaymentMethod;

  /// No description provided for @feesMethodCash.
  ///
  /// In ar, this message translates to:
  /// **'نقداً'**
  String get feesMethodCash;

  /// No description provided for @feesMethodTransfer.
  ///
  /// In ar, this message translates to:
  /// **'تحويل'**
  String get feesMethodTransfer;

  /// No description provided for @feesMethodOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get feesMethodOther;

  /// No description provided for @feesDueDate.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الاستحقاق'**
  String get feesDueDate;

  /// No description provided for @feesMonthInvalid.
  ///
  /// In ar, this message translates to:
  /// **'صيغة الشهر YYYY-MM'**
  String get feesMonthInvalid;

  /// No description provided for @feesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أقساط بعد'**
  String get feesEmpty;

  /// No description provided for @feesSelectStudent.
  ///
  /// In ar, this message translates to:
  /// **'اختر الطالب'**
  String get feesSelectStudent;

  /// No description provided for @testsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الاختبارات'**
  String get testsTitle;

  /// No description provided for @testsAddTitle.
  ///
  /// In ar, this message translates to:
  /// **'إضافة اختبار'**
  String get testsAddTitle;

  /// No description provided for @testsType.
  ///
  /// In ar, this message translates to:
  /// **'النوع'**
  String get testsType;

  /// No description provided for @testsTypeMonthly.
  ///
  /// In ar, this message translates to:
  /// **'شهري'**
  String get testsTypeMonthly;

  /// No description provided for @testsTypeMidterm.
  ///
  /// In ar, this message translates to:
  /// **'منتصف الفصل'**
  String get testsTypeMidterm;

  /// No description provided for @testsTypeFinal.
  ///
  /// In ar, this message translates to:
  /// **'نهائي'**
  String get testsTypeFinal;

  /// No description provided for @testsTypeQuiz.
  ///
  /// In ar, this message translates to:
  /// **'اختبار قصير'**
  String get testsTypeQuiz;

  /// No description provided for @testsTypeOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get testsTypeOther;

  /// No description provided for @testsScore.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة'**
  String get testsScore;

  /// No description provided for @testsMaxScore.
  ///
  /// In ar, this message translates to:
  /// **'الدرجة الكاملة'**
  String get testsMaxScore;

  /// No description provided for @testsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اختبارات بعد'**
  String get testsEmpty;

  /// No description provided for @notesTitle.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get notesTitle;

  /// No description provided for @notesAddHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب ملاحظة عن الطالب...'**
  String get notesAddHint;

  /// No description provided for @notesEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات بعد'**
  String get notesEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @settingsTheme.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get settingsTheme;

  /// No description provided for @settingsThemePick.
  ///
  /// In ar, this message translates to:
  /// **'اختر تصميم التطبيق'**
  String get settingsThemePick;

  /// No description provided for @settingsThemeFusayfesa.
  ///
  /// In ar, this message translates to:
  /// **'فسيفساء'**
  String get settingsThemeFusayfesa;

  /// No description provided for @settingsThemeFusayfesaSub.
  ///
  /// In ar, this message translates to:
  /// **'فاتح دافئ بلمسات ملوّنة'**
  String get settingsThemeFusayfesaSub;

  /// No description provided for @settingsThemeSukoon.
  ///
  /// In ar, this message translates to:
  /// **'سكون'**
  String get settingsThemeSukoon;

  /// No description provided for @settingsThemeSukoonSub.
  ///
  /// In ar, this message translates to:
  /// **'داكن هادئ بأناقة بسيطة'**
  String get settingsThemeSukoonSub;

  /// No description provided for @settingsProfile.
  ///
  /// In ar, this message translates to:
  /// **'الحساب'**
  String get settingsProfile;

  /// No description provided for @settingsLogout.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get settingsLogout;

  /// No description provided for @settingsTeachers.
  ///
  /// In ar, this message translates to:
  /// **'المعلمون'**
  String get settingsTeachers;

  /// No description provided for @settingsAddTeacher.
  ///
  /// In ar, this message translates to:
  /// **'إضافة معلم جديد'**
  String get settingsAddTeacher;

  /// No description provided for @settingsTeacherEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد المعلم'**
  String get settingsTeacherEmail;

  /// No description provided for @settingsTeacherPassword.
  ///
  /// In ar, this message translates to:
  /// **'كلمة المرور'**
  String get settingsTeacherPassword;

  /// No description provided for @settingsTeacherFullName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المعلم'**
  String get settingsTeacherFullName;

  /// No description provided for @settingsTeacherCreated.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء حساب المعلم — شارك معه بيانات الدخول'**
  String get settingsTeacherCreated;

  /// No description provided for @settingsInviteLink.
  ///
  /// In ar, this message translates to:
  /// **'رابط دعوة'**
  String get settingsInviteLink;

  /// No description provided for @settingsCopy.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get settingsCopy;

  /// No description provided for @settingsSchoolMode.
  ///
  /// In ar, this message translates to:
  /// **'نمط المركز'**
  String get settingsSchoolMode;

  /// No description provided for @settingsSingleMode.
  ///
  /// In ar, this message translates to:
  /// **'معلم واحد'**
  String get settingsSingleMode;

  /// No description provided for @settingsMultiMode.
  ///
  /// In ar, this message translates to:
  /// **'عدة معلمين'**
  String get settingsMultiMode;

  /// No description provided for @settingsShareCredentials.
  ///
  /// In ar, this message translates to:
  /// **'شارك بيانات الدخول مع المعلم'**
  String get settingsShareCredentials;

  /// No description provided for @settingsTeachersEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد معلمون بعد — أضف معلمك الأول'**
  String get settingsTeachersEmpty;

  /// No description provided for @settingsTeacherActive.
  ///
  /// In ar, this message translates to:
  /// **'مفعّل'**
  String get settingsTeacherActive;

  /// No description provided for @settingsTeacherDisabled.
  ///
  /// In ar, this message translates to:
  /// **'موقوف'**
  String get settingsTeacherDisabled;

  /// No description provided for @settingsTeacherStatusUpdated.
  ///
  /// In ar, this message translates to:
  /// **'تم تحديث حالة المعلم'**
  String get settingsTeacherStatusUpdated;

  /// No description provided for @accountDisabledTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحساب موقوف'**
  String get accountDisabledTitle;

  /// No description provided for @accountDisabledMessage.
  ///
  /// In ar, this message translates to:
  /// **'أوقف المدير هذا الحساب. تواصل مع مدير المركز لتفعيله.'**
  String get accountDisabledMessage;

  /// No description provided for @homeAddAnnouncement.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إعلان'**
  String get homeAddAnnouncement;

  /// No description provided for @homeAnnouncementHint.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نص الإعلان...'**
  String get homeAnnouncementHint;

  /// No description provided for @homeAnnouncementAdded.
  ///
  /// In ar, this message translates to:
  /// **'تم نشر الإعلان'**
  String get homeAnnouncementAdded;

  /// No description provided for @portalTitle.
  ///
  /// In ar, this message translates to:
  /// **'بوابة ولي الأمر'**
  String get portalTitle;

  /// No description provided for @portalTokenLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز الدخول'**
  String get portalTokenLabel;

  /// No description provided for @portalEnter.
  ///
  /// In ar, this message translates to:
  /// **'عرض البيانات'**
  String get portalEnter;

  /// No description provided for @portalInvalid.
  ///
  /// In ar, this message translates to:
  /// **'الرمز غير صحيح أو منتهي'**
  String get portalInvalid;

  /// No description provided for @portalStudentName.
  ///
  /// In ar, this message translates to:
  /// **'الطالب'**
  String get portalStudentName;

  /// No description provided for @portalGrade.
  ///
  /// In ar, this message translates to:
  /// **'الصف'**
  String get portalGrade;

  /// No description provided for @portalSubjects.
  ///
  /// In ar, this message translates to:
  /// **'المواد'**
  String get portalSubjects;

  /// No description provided for @portalSchedule.
  ///
  /// In ar, this message translates to:
  /// **'مواعيد الجلسات'**
  String get portalSchedule;

  /// No description provided for @portalAttendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور (آخر 30 يوماً)'**
  String get portalAttendance;

  /// No description provided for @portalAttendancePercent.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الحضور'**
  String get portalAttendancePercent;

  /// No description provided for @portalLatestFee.
  ///
  /// In ar, this message translates to:
  /// **'آخر قسط'**
  String get portalLatestFee;

  /// No description provided for @portalRecentTests.
  ///
  /// In ar, this message translates to:
  /// **'آخر الاختبارات'**
  String get portalRecentTests;

  /// No description provided for @portalNotes.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات المعلّم'**
  String get portalNotes;

  /// No description provided for @portalAnnouncements.
  ///
  /// In ar, this message translates to:
  /// **'إعلانات'**
  String get portalAnnouncements;

  /// No description provided for @portalNoData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات بعد'**
  String get portalNoData;

  /// No description provided for @portalToday.
  ///
  /// In ar, this message translates to:
  /// **'اليوم'**
  String get portalToday;

  /// No description provided for @portalTotalSessions.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الجلسات'**
  String get portalTotalSessions;

  /// No description provided for @portalPresent.
  ///
  /// In ar, this message translates to:
  /// **'حاضر'**
  String get portalPresent;

  /// No description provided for @portalAbsent.
  ///
  /// In ar, this message translates to:
  /// **'غائب'**
  String get portalAbsent;

  /// No description provided for @portalRescheduled.
  ///
  /// In ar, this message translates to:
  /// **'مؤجّلة'**
  String get portalRescheduled;

  /// No description provided for @notificationsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإشعارات'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد إشعارات'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAll.
  ///
  /// In ar, this message translates to:
  /// **'تعليم الكل كمقروء'**
  String get notificationsMarkAll;

  /// No description provided for @notificationsNotification.
  ///
  /// In ar, this message translates to:
  /// **'إشعار'**
  String get notificationsNotification;

  /// No description provided for @notificationsUnreadCount.
  ///
  /// In ar, this message translates to:
  /// **'غير مقروء'**
  String get notificationsUnreadCount;

  /// No description provided for @notificationsLatest.
  ///
  /// In ar, this message translates to:
  /// **'آخر التحديثات'**
  String get notificationsLatest;

  /// No description provided for @reportsTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقرير شهري'**
  String get reportsTitle;

  /// No description provided for @reportsSubmit.
  ///
  /// In ar, this message translates to:
  /// **'عرض التقرير'**
  String get reportsSubmit;

  /// No description provided for @reportsMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر'**
  String get reportsMonth;

  /// No description provided for @reportsAttendance.
  ///
  /// In ar, this message translates to:
  /// **'الحضور'**
  String get reportsAttendance;

  /// No description provided for @reportsNoAttendance.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد جلسات مسجّلة في هذا الشهر'**
  String get reportsNoAttendance;

  /// No description provided for @reportsFee.
  ///
  /// In ar, this message translates to:
  /// **'القسط'**
  String get reportsFee;

  /// No description provided for @reportsNoFee.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد قسط مضاف لهذا الشهر'**
  String get reportsNoFee;

  /// No description provided for @reportsTests.
  ///
  /// In ar, this message translates to:
  /// **'الاختبارات'**
  String get reportsTests;

  /// No description provided for @reportsNoTests.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد اختبارات في هذا الشهر'**
  String get reportsNoTests;

  /// No description provided for @reportsNotes.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظات'**
  String get reportsNotes;

  /// No description provided for @reportsNoNotes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات في هذا الشهر'**
  String get reportsNoNotes;

  /// No description provided for @reportsGeneratedAt.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ التوليد'**
  String get reportsGeneratedAt;

  /// No description provided for @portalNotifications.
  ///
  /// In ar, this message translates to:
  /// **'تنبيهات ولي الأمر'**
  String get portalNotifications;

  /// No description provided for @portalNotificationsHint.
  ///
  /// In ar, this message translates to:
  /// **'سيصلك تنبيه عند تحديث المعلّم لبيانات الطالب'**
  String get portalNotificationsHint;

  /// No description provided for @weekMon.
  ///
  /// In ar, this message translates to:
  /// **'الاثنين'**
  String get weekMon;

  /// No description provided for @weekTue.
  ///
  /// In ar, this message translates to:
  /// **'الثلاثاء'**
  String get weekTue;

  /// No description provided for @weekWed.
  ///
  /// In ar, this message translates to:
  /// **'الأربعاء'**
  String get weekWed;

  /// No description provided for @weekThu.
  ///
  /// In ar, this message translates to:
  /// **'الخميس'**
  String get weekThu;

  /// No description provided for @weekFri.
  ///
  /// In ar, this message translates to:
  /// **'الجمعة'**
  String get weekFri;

  /// No description provided for @weekSat.
  ///
  /// In ar, this message translates to:
  /// **'السبت'**
  String get weekSat;

  /// No description provided for @weekSun.
  ///
  /// In ar, this message translates to:
  /// **'الأحد'**
  String get weekSun;
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
      <String>['ar'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
