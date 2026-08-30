// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'Lexi Cards';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get save => 'حفظ';

  @override
  String get study => 'دراسة';

  @override
  String get myDecksTitle => 'مجموعاتي';

  @override
  String get statsTooltip => 'الإحصائيات';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get noDecksYet => 'لا توجد مجموعات بعد. اضغط + لإنشاء واحدة.';

  @override
  String get studyAllDecksHeader => 'دراسة كل المجموعات';

  @override
  String dueCount(int count) {
    return '$count مستحقة';
  }

  @override
  String newCount(int count) {
    return '$count جديدة';
  }

  @override
  String get newDeckTitle => 'مجموعة جديدة';

  @override
  String get renameDeckTitle => 'إعادة تسمية المجموعة';

  @override
  String get deckNameLabel => 'اسم المجموعة';

  @override
  String get create => 'إنشاء';

  @override
  String get browseCards => 'تصفح البطاقات';

  @override
  String get deleteDeckTitle => 'حذف المجموعة؟';

  @override
  String deleteDeckBody(String deckName) {
    return 'سيؤدي هذا إلى حذف \"$deckName\" وجميع بطاقاتها. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get cardsTitle => 'البطاقات';

  @override
  String get noCardsYet => 'لا توجد بطاقات بعد. أضف واحدة أدناه.';

  @override
  String get editCardTitle => 'تعديل البطاقة';

  @override
  String get newCardTitle => 'بطاقة جديدة';

  @override
  String get frontLabel => 'الوجه الأمامي';

  @override
  String get backLabel => 'الوجه الخلفي';

  @override
  String get add => 'إضافة';

  @override
  String get cardStateNew => 'جديدة';

  @override
  String get cardStateLearning => 'قيد التعلم';

  @override
  String get cardStateReview => 'مراجعة';

  @override
  String get cardStateRelearning => 'إعادة تعلم';

  @override
  String get deleteCardTitle => 'حذف البطاقة؟';

  @override
  String get deleteCardBody => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get imagePlaceholder => '📷 صورة';

  @override
  String get studyAllTitle => 'دراسة الكل';

  @override
  String get devSkipAheadTooltip => 'تطوير: تخطي 15 دقيقة';

  @override
  String get allCaughtUp => 'لقد أنجزت كل شيء!';

  @override
  String reviewedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تمت مراجعة $count بطاقة.',
      many: 'تمت مراجعة $count بطاقة.',
      few: 'تمت مراجعة $count بطاقات.',
      two: 'تمت مراجعة بطاقتين.',
      one: 'تمت مراجعة بطاقة واحدة.',
      zero: 'لم تتم مراجعة أي بطاقة.',
    );
    return '$_temp0';
  }

  @override
  String get showAnswer => 'إظهار الإجابة';

  @override
  String get ratingAgain => 'إعادة';

  @override
  String get ratingHard => 'صعب';

  @override
  String get ratingGood => 'جيد';

  @override
  String get ratingEasy => 'سهل';

  @override
  String durationDays(int count) {
    return '$countي';
  }

  @override
  String durationHours(int count) {
    return '$countس';
  }

  @override
  String durationMinutes(int count) {
    return '$countد';
  }

  @override
  String get statsTitle => 'الإحصائيات';

  @override
  String get noStatsYet =>
      'لا توجد إحصائيات بعد. أضف بعض البطاقات وابدأ المراجعة.';

  @override
  String get dayStreak => 'أيام متتالية';

  @override
  String get longestStreak => 'أطول تتابع';

  @override
  String get retention => 'نسبة الاحتفاظ';

  @override
  String get cardsLearned => 'البطاقات المتعلمة';

  @override
  String get reviewsLast7Days => 'المراجعات — آخر 7 أيام';

  @override
  String get dueNext7Days => 'المستحقة — الأيام السبعة القادمة';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get dailyReminderTitle => 'تذكير يومي';

  @override
  String get dailyReminderSubtitle => 'احصل على تنبيه لمراجعة بطاقاتك المستحقة';

  @override
  String get timeLabel => 'الوقت';

  @override
  String get sendTestNotification => 'إرسال إشعار تجريبي';

  @override
  String get reminderPermissionDenied =>
      'تم رفض إذن الإشعارات. فعّله من إعدادات النظام لاستخدام التذكيرات.';

  @override
  String get testPermissionDenied => 'تم رفض إذن الإشعارات.';

  @override
  String get testNotificationSent =>
      'تم إرسال الإشعار التجريبي — يجب أن يصل خلال ثوانٍ قليلة.';

  @override
  String get languageTitle => 'اللغة';

  @override
  String get languageSystemDefault => 'إعداد النظام';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';
}
