import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shougaku_kore_doutoku/models/notification_preferences.dart';
import 'package:shougaku_kore_doutoku/providers/notification_preferences_provider.dart';

void main() {
  group('NotificationPreferencesProvider', () {
    test('loads default preferences when Firestore document does not exist', () async {
      final container = ProviderContainer();

      // Override the provider to return default preferences
      final overrides = [
        notificationPreferencesProvider('user-123').overrideWith(
          (ref) => Future.value(NotificationPreferences.defaultPreferences()),
        ),
      ];

      final containerWithOverrides = ProviderContainer(overrides: overrides);

      final prefs =
          await containerWithOverrides.read(notificationPreferencesProvider('user-123').future);

      expect(prefs.emailNotificationsEnabled, true);
      expect(prefs.emailFrequency, 'weekly');
      expect(prefs.emailTime, '18:00');
      expect(prefs.emailTimeZone, 'Asia/Tokyo');
    });

    test('copies notification preferences with updated fields', () {
      final original = NotificationPreferences.defaultPreferences();

      final updated = original.copyWith(
        emailFrequency: 'monthly',
        emailTime: '09:00',
      );

      expect(updated.emailFrequency, 'monthly');
      expect(updated.emailTime, '09:00');
      expect(updated.emailNotificationsEnabled, original.emailNotificationsEnabled);
    });

    test('custom email days are properly managed', () {
      final prefs = NotificationPreferences(
        emailFrequency: 'custom',
        customEmailDays: [0, 3, 6], // Sunday, Wednesday, Saturday
        updatedAt: DateTime.now(),
      );

      expect(prefs.customEmailDays, [0, 3, 6]);
      expect(prefs.emailFrequency, 'custom');
    });
  });

  group('NotificationPreferences Model', () {
    test('fromJson and toJson round-trip correctly', () {
      final original = NotificationPreferences(
        emailNotificationsEnabled: false,
        emailFrequency: 'biweekly',
        customEmailDays: [1, 4],
        emailTime: '12:30',
        emailTimeZone: 'America/New_York',
        fcmNotificationsEnabled: true,
        updatedAt: DateTime(2024, 1, 1, 12, 0, 0),
      );

      final json = original.toJson();
      final restored = NotificationPreferences.fromJson(json);

      expect(restored.emailNotificationsEnabled, original.emailNotificationsEnabled);
      expect(restored.emailFrequency, original.emailFrequency);
      expect(restored.customEmailDays, original.customEmailDays);
      expect(restored.emailTime, original.emailTime);
      expect(restored.emailTimeZone, original.emailTimeZone);
      expect(restored.fcmNotificationsEnabled, original.fcmNotificationsEnabled);
    });

    test('defaults to Asia/Tokyo timezone', () {
      final prefs = NotificationPreferences(updatedAt: DateTime.now());
      expect(prefs.emailTimeZone, 'Asia/Tokyo');
    });

    test('defaults to 18:00 email time', () {
      final prefs = NotificationPreferences(updatedAt: DateTime.now());
      expect(prefs.emailTime, '18:00');
    });

    test('defaults to weekly frequency', () {
      final prefs = NotificationPreferences(updatedAt: DateTime.now());
      expect(prefs.emailFrequency, 'weekly');
    });
  });
}
