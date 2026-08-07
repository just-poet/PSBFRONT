import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings_hi.dart';
import 'strings_pa.dart';
import 'strings_te.dart';

/// Languages the app ships with.
enum AppLanguage {
  english('en', 'English', 'English'),
  hindi('hi', 'Hindi', 'हिन्दी'),
  punjabi('pa', 'Punjabi', 'ਪੰਜਾਬੀ'),
  telugu('te', 'Telugu', 'తెలుగు');

  const AppLanguage(this.code, this.englishName, this.nativeName);

  /// ISO code stored in preferences.
  final String code;

  /// Name in English, for the settings row summary.
  final String englishName;

  /// Name in its own script, which is how language pickers normally read.
  final String nativeName;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}

/// Holds the selected language and translates UI strings.
///
/// Deliberately not `flutter_localizations` + ARB: that would mean rewriting
/// every one of the ~750 `Text('...')` call sites to reference generated
/// accessors, which is a large mechanical change with a lot of room to break
/// working screens. [tr] takes the English string as its own key and returns it
/// unchanged when there is no translation, so a missed string degrades to
/// English rather than to a blank or a crash.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const String _key = 'finix_language';
  static const MethodChannel _appChannel =
      MethodChannel('com.finix.hardware/app');

  /// Current language. Widgets can listen to rebuild in place.
  final ValueNotifier<AppLanguage> language =
      ValueNotifier<AppLanguage>(AppLanguage.english);

  bool get isHindi => language.value == AppLanguage.hindi;

  /// Dictionary for the active language, or null for English (which is the
  /// source text and needs no lookup).
  Map<String, String>? get _dictionary {
    switch (language.value) {
      case AppLanguage.hindi:
        return hindiStrings;
      case AppLanguage.punjabi:
        return punjabiStrings;
      case AppLanguage.telugu:
        return teluguStrings;
      case AppLanguage.english:
        return null;
    }
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      language.value = AppLanguage.fromCode(prefs.getString(_key));
    } catch (_) {
      // No SharedPreferences implementation (web preview): stay on English.
    }
  }

  Future<void> setLanguage(AppLanguage next) async {
    language.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, next.code);
    } catch (_) {}
  }

  /// Closes and relaunches the app so every screen is rebuilt in the new
  /// language.
  ///
  /// Returns false when the platform cannot do it — desktop, web, or an older
  /// build without the native handler — so the caller can fall back to
  /// rebuilding the widget tree in place instead of leaving the user staring at
  /// a half-translated screen.
  Future<bool> restartApp() async {
    try {
      final ok = await _appChannel.invokeMethod<bool>('restart');
      return ok == true;
    } catch (_) {
      return false;
    }
  }

  /// Translates [source] for the active language.
  ///
  /// Returns [source] untouched when the language is English, when no
  /// translation exists, or when the string carries digits — amounts, dates,
  /// account numbers and percentages must stay in Latin numerals.
  String tr(String source) {
    final dictionary = _dictionary;
    if (dictionary == null) return source;

    final translated = dictionary[source];
    if (translated != null) return translated;

    // Trim-insensitive second attempt: several screens pad labels with
    // whitespace or a trailing arrow.
    final trimmed = source.trim();
    if (trimmed != source) {
      final alt = dictionary[trimmed];
      if (alt != null) return source.replaceFirst(trimmed, alt);
    }

    // Backend values often end in a year or a number — a goal named
    // "Europe Trip 2027", say. Translate the words and keep the digits, rather
    // than leaving the whole label in English because of the suffix.
    final withNumber = RegExp(r'^(.*?)([\s\-]+[0-9][0-9.,/]*)$').firstMatch(trimmed);
    if (withNumber != null) {
      final head = dictionary[withNumber.group(1)!.trim()];
      if (head != null) return '$head${withNumber.group(2)}';
    }
    return source;
  }
}

/// Shorthand used across the screens.
String tr(String source) => LocaleService.instance.tr(source);
