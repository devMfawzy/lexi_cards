import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ar'),
    Locale('en'),
  ];

  /// Application title, shown in the OS task switcher
  ///
  /// In en, this message translates to:
  /// **'Lexi Cards'**
  String get appTitle;

  /// Cancel button, used across dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button, used across dialogs
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Save button, used when editing an existing card
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Tooltip/title for starting a review session on one deck
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get study;

  /// AppBar title on the deck list screen
  ///
  /// In en, this message translates to:
  /// **'My Decks'**
  String get myDecksTitle;

  /// Tooltip for the stats icon on the deck list AppBar
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTooltip;

  /// Tooltip for the settings icon on the deck list AppBar
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// Empty state on the deck list screen
  ///
  /// In en, this message translates to:
  /// **'No decks yet. Tap + to create one.'**
  String get noDecksYet;

  /// Title of the combined-study header card, and its tooltip
  ///
  /// In en, this message translates to:
  /// **'Study all decks'**
  String get studyAllDecksHeader;

  /// Due-card count pill, on a deck row or the study-all header
  ///
  /// In en, this message translates to:
  /// **'{count} due'**
  String dueCount(int count);

  /// New-card count pill on a deck row
  ///
  /// In en, this message translates to:
  /// **'{count} new'**
  String newCount(int count);

  /// Title of the create-deck dialog
  ///
  /// In en, this message translates to:
  /// **'New deck'**
  String get newDeckTitle;

  /// Text field label in the create-deck dialog
  ///
  /// In en, this message translates to:
  /// **'Deck name'**
  String get deckNameLabel;

  /// Confirm button in the create-deck dialog
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Title of the delete-deck confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete deck?'**
  String get deleteDeckTitle;

  /// Body of the delete-deck confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This deletes \"{deckName}\" and all its cards. This cannot be undone.'**
  String deleteDeckBody(String deckName);

  /// AppBar title on a deck's card list screen
  ///
  /// In en, this message translates to:
  /// **'Cards'**
  String get cardsTitle;

  /// Empty state on the card list screen
  ///
  /// In en, this message translates to:
  /// **'No cards yet. Add one below.'**
  String get noCardsYet;

  /// Title of the card editor dialog, edit mode
  ///
  /// In en, this message translates to:
  /// **'Edit card'**
  String get editCardTitle;

  /// Title of the card editor dialog, create mode
  ///
  /// In en, this message translates to:
  /// **'New card'**
  String get newCardTitle;

  /// Label above the front rich-text field in the card editor
  ///
  /// In en, this message translates to:
  /// **'Front'**
  String get frontLabel;

  /// Label above the back rich-text field in the card editor
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backLabel;

  /// Confirm button in the card editor dialog, create mode
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Card state chip: not yet studied
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get cardStateNew;

  /// Card state chip: in initial learning steps
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get cardStateLearning;

  /// Card state chip: graduated to day-scale review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get cardStateReview;

  /// Card state chip: lapsed back into short steps
  ///
  /// In en, this message translates to:
  /// **'Relearning'**
  String get cardStateRelearning;

  /// Title of the delete-card confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete card?'**
  String get deleteCardTitle;

  /// Body of the delete-card confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get deleteCardBody;

  /// List preview placeholder for a card face that has an image but no text
  ///
  /// In en, this message translates to:
  /// **'📷 Image'**
  String get imagePlaceholder;

  /// AppBar title when reviewing across every deck
  ///
  /// In en, this message translates to:
  /// **'Study All'**
  String get studyAllTitle;

  /// Debug-only tooltip for the fast-forward review testing tool
  ///
  /// In en, this message translates to:
  /// **'Dev: skip ahead 15 min'**
  String get devSkipAheadTooltip;

  /// Headline shown when a review session's queue is empty
  ///
  /// In en, this message translates to:
  /// **'All caught up!'**
  String get allCaughtUp;

  /// Review session completion summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Reviewed 1 card.} other{Reviewed {count} cards.}}'**
  String reviewedCount(int count);

  /// Button to reveal a flashcard's back face
  ///
  /// In en, this message translates to:
  /// **'Show Answer'**
  String get showAnswer;

  /// SM-2 rating button: failed recall
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get ratingAgain;

  /// SM-2 rating button: recalled with difficulty
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get ratingHard;

  /// SM-2 rating button: recalled correctly
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get ratingGood;

  /// SM-2 rating button: recalled easily
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get ratingEasy;

  /// Abbreviated day count shown under a rating button (e.g. next review in 4d)
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String durationDays(int count);

  /// Abbreviated hour count shown under a rating button
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String durationHours(int count);

  /// Abbreviated minute count shown under a rating button
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String durationMinutes(int count);

  /// AppBar title on the stats screen
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// Empty state on the stats screen
  ///
  /// In en, this message translates to:
  /// **'No stats yet. Add some cards and start reviewing.'**
  String get noStatsYet;

  /// Stat tile label: current consecutive-day review streak
  ///
  /// In en, this message translates to:
  /// **'Day streak'**
  String get dayStreak;

  /// Stat tile label: longest consecutive-day review streak
  ///
  /// In en, this message translates to:
  /// **'Longest streak'**
  String get longestStreak;

  /// Stat tile label: percentage of reviews not rated Again
  ///
  /// In en, this message translates to:
  /// **'Retention'**
  String get retention;

  /// Stat tile label: cards past the New state, out of total
  ///
  /// In en, this message translates to:
  /// **'Cards learned'**
  String get cardsLearned;

  /// Bar chart title: reviews done per day, last week
  ///
  /// In en, this message translates to:
  /// **'Reviews — last 7 days'**
  String get reviewsLast7Days;

  /// Bar chart title: cards coming due per day, next week
  ///
  /// In en, this message translates to:
  /// **'Due — next 7 days'**
  String get dueNext7Days;

  /// AppBar title on the settings screen
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Switch label for the daily study reminder notification
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get dailyReminderTitle;

  /// Switch subtitle for the daily study reminder notification
  ///
  /// In en, this message translates to:
  /// **'Get nudged to review your due cards'**
  String get dailyReminderSubtitle;

  /// Row label for the reminder time picker
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// Button to fire a one-off test notification
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get sendTestNotification;

  /// Error shown when enabling the daily reminder is denied notification permission
  ///
  /// In en, this message translates to:
  /// **'Notifications permission was denied. Enable it in system settings to use reminders.'**
  String get reminderPermissionDenied;

  /// Error shown when sending a test notification is denied permission
  ///
  /// In en, this message translates to:
  /// **'Notifications permission was denied.'**
  String get testPermissionDenied;

  /// Confirmation shown after successfully sending a test notification
  ///
  /// In en, this message translates to:
  /// **'Test notification sent — it should arrive in a few seconds.'**
  String get testNotificationSent;

  /// Row label for the language picker
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageTitle;

  /// Language picker option: follow the device's language setting
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// Language picker option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Language picker option, shown in its own script (Arabic endonym)
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
