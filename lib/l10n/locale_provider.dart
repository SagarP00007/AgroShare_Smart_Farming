import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_localizations.dart';

/// Provides [LocaleProvider] down the tree so screens can call setLocale.
class LocaleProviderInherited extends InheritedWidget {
  const LocaleProviderInherited({
    super.key,
    required this.provider,
    required super.child,
  });

  final LocaleProvider provider;

  static LocaleProvider? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<LocaleProviderInherited>()?.provider;
  }

  @override
  bool updateShouldNotify(LocaleProviderInherited old) => provider != old.provider;
}

const String _localeKey = 'app_locale';

/// Provides current [Locale] and [AppLocalizations], notifies when locale changes.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider(this._prefs) {
    _locale = _loadSavedLocale();
  }

  final SharedPreferences _prefs;
  late Locale _locale;
  AppLocalizations? _localizations;

  Locale get locale => _locale;
  AppLocalizations? get localizations => _localizations;

  static Locale _loadSavedLocaleFromPrefs(SharedPreferences prefs) {
    final code = prefs.getString(_localeKey);
    if (code != null && code.isNotEmpty) {
      return Locale(code);
    }
    return const Locale('en');
  }

  Locale _loadSavedLocale() {
    return _loadSavedLocaleFromPrefs(_prefs);
  }

  Future<void> loadLocalizations() async {
    _localizations = await AppLocalizations.load(_locale);
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;
    _locale = newLocale;
    await _prefs.setString(_localeKey, newLocale.languageCode);
    _localizations = await AppLocalizations.load(_locale);
    notifyListeners();
  }

  /// Call once after SharedPreferences is ready (e.g. in main after Firebase init).
  static Future<LocaleProvider> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final provider = LocaleProvider(prefs);
      try {
        await provider.loadLocalizations();
      } catch (e) {
        // ignore: avoid_print
        print('Warning loading localizations: $e');
      }
      return provider;
    } catch (e) {
      // ignore: avoid_print
      print('Warning initializing SharedPreferences for LocaleProvider: $e');
      final prefs = await SharedPreferences.getInstance();
      return LocaleProvider(prefs);
    }
  }
}
