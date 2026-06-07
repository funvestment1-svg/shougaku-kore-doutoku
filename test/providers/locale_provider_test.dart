import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shougaku_kore_doutoku/providers/locale_provider.dart';

/// Pump the event loop once to let fire-and-forget _loadLocale complete.
Future<void> _pump() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(() {
    // Reset SharedPreferences to a clean state before each test
    SharedPreferences.setMockInitialValues({});
  });

  // ── LocaleNotifier ────────────────────────────────────────────────────────

  group('LocaleNotifier', () {
    test('default locale is ja', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider); // trigger _loadLocale
      await _pump();
      expect(container.read(localeProvider), const Locale('ja'));
    });

    test('setLocale changes state and persists to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider); // initialize
      await _pump();

      await container.read(localeProvider.notifier).setLocale(SupportedLocale.en);
      expect(container.read(localeProvider), const Locale('en'));

      // Verify persisted
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_locale'), 'en');
    });

    test('setLocaleByCode changes locale to en', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocaleByCode('en');
      expect(container.read(localeProvider), const Locale('en'));
    });

    test('setLocaleByCode with unknown code defaults to ja', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocaleByCode('fr');
      expect(container.read(localeProvider), const Locale('ja'));
    });

    test('saved locale is restored on re-create', () async {
      // Seed SharedPreferences with a saved value
      SharedPreferences.setMockInitialValues({'selected_locale': 'en'});

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider); // trigger _loadLocale
      await _pump();
      expect(container.read(localeProvider), const Locale('en'));
    });
  });

  // ── currentLocaleProvider ─────────────────────────────────────────────────

  group('currentLocaleProvider', () {
    test('maps ja locale to SupportedLocale.ja', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(localeProvider); // trigger _loadLocale (default ja)
      await _pump();
      expect(container.read(currentLocaleProvider), SupportedLocale.ja);
    });

    test('maps en locale to SupportedLocale.en', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(localeProvider.notifier).setLocale(SupportedLocale.en);
      expect(container.read(currentLocaleProvider), SupportedLocale.en);
    });

    test('maps unknown locale code to SupportedLocale.ja', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Manually force an unsupported locale
      // (setLocaleByCode defaults unknown to ja)
      await container.read(localeProvider.notifier).setLocaleByCode('zz');
      expect(container.read(currentLocaleProvider), SupportedLocale.ja);
    });
  });

  // ── SupportedLocale enum ──────────────────────────────────────────────────

  group('SupportedLocale', () {
    test('toLocale returns Locale with correct code', () {
      expect(SupportedLocale.ja.toLocale(), const Locale('ja'));
      expect(SupportedLocale.en.toLocale(), const Locale('en'));
    });

    test('enum has correct metadata', () {
      expect(SupportedLocale.ja.code, 'ja');
      expect(SupportedLocale.ja.nativeName, '日本語');
      expect(SupportedLocale.en.code, 'en');
      expect(SupportedLocale.en.englishName, 'English');
    });
  });
}
