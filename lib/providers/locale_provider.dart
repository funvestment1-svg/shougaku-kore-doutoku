import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// サポートされるロケール
enum SupportedLocale {
  ja('ja', 'Japanese', '日本語'),
  en('en', 'English', 'English');

  final String code;
  final String englishName;
  final String nativeName;

  const SupportedLocale(this.code, this.englishName, this.nativeName);
}

extension SupportedLocaleExt on SupportedLocale {
  Locale toLocale() => Locale(code);
}

/// ロケール管理プロバイダー
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

/// ロケール変更時に再構築するプロバイダー
final currentLocaleProvider = Provider<SupportedLocale>((ref) {
  final locale = ref.watch(localeProvider);
  return SupportedLocale.values.firstWhere(
    (l) => l.code == locale.languageCode,
    orElse: () => SupportedLocale.ja,
  );
});

/// ロケール Notifier
class LocaleNotifier extends StateNotifier<Locale> {
  static const String _localeKey = 'selected_locale';

  LocaleNotifier() : super(const Locale('ja')) {
    _loadLocale();
  }

  /// 保存されたロケール設定を読み込む
  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey) ?? 'ja';
      state = Locale(savedLocale);
    } catch (e) {
      // デフォルトは日本語
      state = const Locale('ja');
    }
  }

  /// ロケールを変更
  Future<void> setLocale(SupportedLocale locale) async {
    state = locale.toLocale();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.code);
    } catch (e) {
      // ローカル保存に失敗してもアプリは動作継続
      debugPrint('Failed to save locale preference: $e');
    }
  }

  /// ロケールを言語コードから設定
  Future<void> setLocaleByCode(String code) async {
    final locale = SupportedLocale.values
        .firstWhere((l) => l.code == code, orElse: () => SupportedLocale.ja);
    await setLocale(locale);
  }
}
