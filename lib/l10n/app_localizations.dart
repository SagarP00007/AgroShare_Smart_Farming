import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// JSON-based app localizations for Indian languages.
/// Use [L.tr(context, key)] or [AppLocalizations.of(context)?.tr(key)].
class AppLocalizations {
  AppLocalizations(this._locale, this._strings);

  final Locale _locale;
  final Map<String, String> _strings;

  static AppLocalizations? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedL10n>()?.data;
  }

  String tr(String key, {String? fallback}) {
    return _strings[key] ?? fallback ?? key;
  }

  Locale get locale => _locale;

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('kn'),
    Locale('ta'),
    Locale('te'),
    Locale('bn'),
    Locale('mr'),
    Locale('gu'),
    Locale('ml'),
    Locale('pa'),
    Locale('or'),
    Locale('ur'),
  ];

  static const String _basePath = 'assets/translations';

  static Future<AppLocalizations> load(Locale locale) async {
    final langCode = locale.languageCode;
    final fallback = langCode == 'en'
        ? null
        : await _loadJson(const Locale('en'));
    Map<String, String> strings;
    try {
      strings = await _loadJson(locale);
      if (fallback != null) {
        for (final e in fallback.entries) {
          strings.putIfAbsent(e.key, () => e.value);
        }
      }
    } catch (_) {
      strings = fallback ?? {};
    }
    return AppLocalizations(locale, strings);
  }

  static Future<Map<String, String>> _loadJson(Locale locale) async {
    final path = '$_basePath/${locale.languageCode}.json';
    final str = await rootBundle.loadString(path);
    final map = json.decode(str) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v ?? k).toString()));
  }
}

/// InheritedWidget to expose [AppLocalizations] down the tree.
class InheritedL10n extends InheritedWidget {
  const InheritedL10n({super.key, required this.data, required super.child});

  final AppLocalizations data;

  @override
  bool updateShouldNotify(InheritedL10n old) => data.locale != old.data.locale;
}

/// Extension for concise [AppLocalizations.tr] usage.
extension L10nContext on BuildContext {
  String tr(String key, {String? fallback}) {
    return AppLocalizations.of(this)?.tr(key, fallback: fallback) ?? key;
  }
}

/// Short alias: use L.tr(context, 'key') in the app.
abstract class L {
  static String tr(BuildContext context, String key, {String? fallback}) {
    return context.tr(key, fallback: fallback);
  }
}
