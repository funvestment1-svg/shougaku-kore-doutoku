// NOTE: NotificationSettingsNotifier cannot be unit-tested in isolation because
// NotificationService() immediately accesses FirebaseMessaging.instance (via a
// static field initializer), which requires a real Firebase app.
// Tests that cover the full notifier behaviour belong in integration tests.
// This file tests the pure data model, NotificationSettings.

import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/providers/notification_provider.dart';

void main() {
  // ── NotificationSettings ──────────────────────────────────────────────────

  group('NotificationSettings', () {
    test('default values are correct', () {
      const s = NotificationSettings();
      expect(s.dailyReminder, isTrue);
      expect(s.reportReady, isTrue);
      expect(s.reminderHour, 19);
      expect(s.reminderMinute, 0);
    });

    test('copyWith preserves unchanged fields', () {
      const original = NotificationSettings(
        dailyReminder: false,
        reportReady: false,
        reminderHour: 9,
        reminderMinute: 30,
      );

      final updated = original.copyWith(dailyReminder: true);
      expect(updated.dailyReminder, isTrue);    // changed
      expect(updated.reportReady, isFalse);     // preserved
      expect(updated.reminderHour, 9);          // preserved
      expect(updated.reminderMinute, 30);       // preserved
    });

    test('copyWith with no arguments returns equal object', () {
      const s = NotificationSettings(
        dailyReminder: false,
        reportReady: true,
        reminderHour: 8,
        reminderMinute: 15,
      );
      final copy = s.copyWith();
      expect(copy.dailyReminder, s.dailyReminder);
      expect(copy.reportReady, s.reportReady);
      expect(copy.reminderHour, s.reminderHour);
      expect(copy.reminderMinute, s.reminderMinute);
    });

    test('copyWith can change all fields', () {
      const original = NotificationSettings();
      final updated = original.copyWith(
        dailyReminder: false,
        reportReady: false,
        reminderHour: 6,
        reminderMinute: 45,
      );
      expect(updated.dailyReminder, isFalse);
      expect(updated.reportReady, isFalse);
      expect(updated.reminderHour, 6);
      expect(updated.reminderMinute, 45);
    });

    test('constructor stores all parameters correctly', () {
      const s = NotificationSettings(
        dailyReminder: false,
        reportReady: true,
        reminderHour: 22,
        reminderMinute: 59,
      );
      expect(s.dailyReminder, isFalse);
      expect(s.reportReady, isTrue);
      expect(s.reminderHour, 22);
      expect(s.reminderMinute, 59);
    });
  });
}
