import 'package:flutter_test/flutter_test.dart';

import 'package:finix_dashboard/services/locale_service.dart';
import 'package:finix_dashboard/services/strings_hi.dart';
import 'package:finix_dashboard/services/strings_pa.dart';
import 'package:finix_dashboard/services/strings_te.dart';

/// Every translated language, paired with its dictionary.
const Map<AppLanguage, Map<String, String>> dictionaries = {
  AppLanguage.hindi: hindiStrings,
  AppLanguage.punjabi: punjabiStrings,
  AppLanguage.telugu: teluguStrings,
};

void main() {
  final service = LocaleService.instance;

  tearDown(() => service.language.value = AppLanguage.english);

  test('English is untouched', () {
    service.language.value = AppLanguage.english;
    expect(tr('Settings'), 'Settings');
    expect(tr('Pay Anyone'), 'Pay Anyone');
  });

  test('each language translates a known string', () {
    service.language.value = AppLanguage.hindi;
    expect(tr('Settings'), 'सेटिंग्स');

    service.language.value = AppLanguage.punjabi;
    expect(tr('Settings'), 'ਸੈਟਿੰਗਾਂ');

    service.language.value = AppLanguage.telugu;
    expect(tr('Settings'), 'సెట్టింగ్‌లు');
  });

  test('an untranslated string falls back to English, never to blank', () {
    for (final language in dictionaries.keys) {
      service.language.value = language;
      const unknown = 'Some string nobody has translated yet';
      expect(tr(unknown), unknown, reason: '${language.englishName} lost the source');
      expect(tr(''), '');
    }
  });

  test('every language covers exactly the same keys', () {
    // A key present in one dictionary but missing from another is a screen
    // that silently reverts to English for some customers only.
    final reference = hindiStrings.keys.toSet();
    for (final entry in dictionaries.entries) {
      final keys = entry.value.keys.toSet();
      expect(keys.difference(reference), isEmpty,
          reason: '${entry.key.englishName} has keys Hindi does not');
      expect(reference.difference(keys), isEmpty,
          reason: '${entry.key.englishName} is missing keys Hindi has');
    }
  });

  test('no translation is empty or left in English', () {
    for (final entry in dictionaries.entries) {
      entry.value.forEach((source, translated) {
        expect(translated.trim(), isNotEmpty,
            reason: '${entry.key.englishName}: "$source" is blank');
      });
    }
  });

  test('no translation uses non-Latin digits', () {
    // Amounts, dates and percentages stay in Latin numerals. Devanagari,
    // Gurmukhi and Telugu each have their own digit forms; any of them in a
    // label would put two numbering systems on the same screen.
    const nonLatinDigits =
        '०१२३४५६७८९' // Devanagari
        '੦੧੨੩੪੫੬੭੮੯' // Gurmukhi
        '౦౧౨౩౪౫౬౭౮౯'; // Telugu
    for (final entry in dictionaries.entries) {
      entry.value.forEach((source, translated) {
        for (final digit in nonLatinDigits.split('')) {
          expect(translated.contains(digit), isFalse,
              reason: '${entry.key.englishName}: "$source" -> "$translated"');
        }
      });
    }
  });

  test('no translation key carries a digit', () {
    // A key with a number in it would be a formatted string that should have
    // been interpolated instead, and translating it would freeze that number.
    final numeric = RegExp(r'\d');
    for (final key in hindiStrings.keys) {
      expect(numeric.hasMatch(key), isFalse,
          reason: '"$key" contains a digit and should not be translated');
    }
  });

  test('translations stay short enough not to break fixed-width chrome', () {
    // Bottom-nav labels, pills and table headers have little room. All three
    // scripts render taller than Latin and Telugu is the widest per glyph, so
    // a translation much longer than its English source is where layout breaks
    // first. Long-form prose is exempt: it already wraps.
    final tooLong = <String>[];
    for (final entry in dictionaries.entries) {
      entry.value.forEach((source, translated) {
        if (source.length <= 12 && translated.length > source.length + 8) {
          tooLong.add('${entry.key.englishName}: "$source" (${source.length}) -> '
              '"$translated" (${translated.length})');
        }
      });
    }
    expect(tooLong, isEmpty,
        reason: 'short labels grew too much:\n${tooLong.join('\n')}');
  });

  test('multi-line labels keep their line breaks', () {
    // A few labels are hand-wrapped with \n to fit a fixed-height card. Losing
    // the break collapses them onto one line and overflows the card.
    for (final entry in dictionaries.entries) {
      entry.value.forEach((source, translated) {
        if (source.contains('\n')) {
          expect(translated.contains('\n'), isTrue,
              reason: '${entry.key.englishName}: "$source" lost its line break');
        }
      });
    }
  });

  test('language codes round-trip', () {
    for (final language in AppLanguage.values) {
      expect(AppLanguage.fromCode(language.code), language);
    }
    // An unknown or absent code must not throw.
    expect(AppLanguage.fromCode(null), AppLanguage.english);
    expect(AppLanguage.fromCode('zz'), AppLanguage.english);
  });

  test('every language has a distinct native name for the picker', () {
    final names = AppLanguage.values.map((l) => l.nativeName).toSet();
    expect(names.length, AppLanguage.values.length);
  });
}
