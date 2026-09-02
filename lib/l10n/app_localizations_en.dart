// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lexi Cards';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get study => 'Study';

  @override
  String get myDecksTitle => 'My Decks';

  @override
  String get statsTooltip => 'Stats';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get noDecksYet => 'No decks yet. Tap + to create one.';

  @override
  String get studyAllDecksHeader => 'Study all decks';

  @override
  String dueCount(int count) {
    return '$count due';
  }

  @override
  String newCount(int count) {
    return '$count new';
  }

  @override
  String get newDeckTitle => 'New deck';

  @override
  String get renameDeckTitle => 'Rename deck';

  @override
  String get deckNameLabel => 'Deck name';

  @override
  String get create => 'Create';

  @override
  String get browseCards => 'Browse cards';

  @override
  String get deleteDeckTitle => 'Delete deck?';

  @override
  String deleteDeckBody(String deckName) {
    return 'This deletes \"$deckName\" and all its cards. This cannot be undone.';
  }

  @override
  String get cardsTitle => 'Cards';

  @override
  String get noCardsYet => 'No cards yet. Add one below.';

  @override
  String get editCardTitle => 'Edit card';

  @override
  String get newCardTitle => 'New card';

  @override
  String get frontLabel => 'Front';

  @override
  String get backLabel => 'Back';

  @override
  String get add => 'Add';

  @override
  String get cardStateNew => 'New';

  @override
  String get cardStateLearning => 'Learning';

  @override
  String get cardStateReview => 'Review';

  @override
  String get cardStateRelearning => 'Relearning';

  @override
  String get deleteCardTitle => 'Delete card?';

  @override
  String get deleteCardBody => 'This cannot be undone.';

  @override
  String get imagePlaceholder => '📷 Image';

  @override
  String get imageTooLarge => 'That image is too large to add to a card. Try a smaller one.';

  @override
  String get studyAllTitle => 'Study All';

  @override
  String get devSkipAheadTooltip => 'Dev: skip ahead 15 min';

  @override
  String get allCaughtUp => 'All caught up!';

  @override
  String reviewedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Reviewed $count cards.',
      one: 'Reviewed 1 card.',
    );
    return '$_temp0';
  }

  @override
  String get showAnswer => 'Show Answer';

  @override
  String get ratingAgain => 'Again';

  @override
  String get ratingHard => 'Hard';

  @override
  String get ratingGood => 'Good';

  @override
  String get ratingEasy => 'Easy';

  @override
  String durationDays(int count) {
    return '${count}d';
  }

  @override
  String durationHours(int count) {
    return '${count}h';
  }

  @override
  String durationMinutes(int count) {
    return '${count}m';
  }

  @override
  String get statsTitle => 'Stats';

  @override
  String get noStatsYet => 'No stats yet. Add some cards and start reviewing.';

  @override
  String get dayStreak => 'Day streak';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String get retention => 'Retention';

  @override
  String get cardsLearned => 'Cards learned';

  @override
  String get reviewsLast7Days => 'Reviews — last 7 days';

  @override
  String get dueNext7Days => 'Due — next 7 days';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get dailyReminderTitle => 'Daily reminder';

  @override
  String get dailyReminderSubtitle => 'Get nudged to review your due cards';

  @override
  String get timeLabel => 'Time';

  @override
  String get sendTestNotification => 'Send test notification';

  @override
  String get reminderPermissionDenied =>
      'Notifications permission was denied. Enable it in system settings to use reminders.';

  @override
  String get testPermissionDenied => 'Notifications permission was denied.';

  @override
  String get testNotificationSent => 'Test notification sent — it should arrive in a few seconds.';

  @override
  String get languageTitle => 'Language';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get syncTitle => 'Sync';

  @override
  String get syncNotConnected => 'Not connected';

  @override
  String get syncExplainer =>
      'Your decks and progress are kept in a private folder in your Google Drive. Lexi Cards can\'t see any other file there.';

  @override
  String get syncConnectAccount => 'Connect Google account';

  @override
  String get syncDisconnect => 'Disconnect';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncAccountLabel => 'Account';

  @override
  String syncLastSynced(String time) {
    return 'Last synced $time';
  }

  @override
  String get syncNever => 'Not synced yet';

  @override
  String get syncUninstallWarning =>
      'Removing Lexi Cards from your Google Drive deletes this copy. It keeps your devices in step — it isn\'t a permanent backup.';

  @override
  String get syncConnected => 'Account connected.';

  @override
  String get syncDisconnected => 'Account disconnected.';

  @override
  String get syncUpToDate => 'Already up to date.';

  @override
  String syncChangesApplied(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Synced — $count changes',
      one: 'Synced — 1 change',
    );
    return '$_temp0';
  }

  @override
  String get syncNeedsAccount => 'Connect a Google account first.';

  @override
  String get syncRemoteBusy => 'Another device is syncing right now. Try again in a moment.';

  @override
  String get syncSnapshotTooNew =>
      'This data was synced by a newer version of Lexi Cards. Update the app to continue syncing.';
}
