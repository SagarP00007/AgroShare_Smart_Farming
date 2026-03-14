import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/app_localizations.dart';
import 'l10n/locale_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

/// Root widget for the AgroShare application.
/// Supports multiple Indian languages via JSON translations.
class AgroShareApp extends StatelessWidget {
  const AgroShareApp({super.key, required this.localeProvider});

  final LocaleProvider localeProvider;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: localeProvider,
      builder: (context, _) {
        final loc = localeProvider.localizations;
        return LocaleProviderInherited(
          provider: localeProvider,
          child: MaterialApp(
            title: loc?.tr('app_title') ?? 'AgroShare',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              return InheritedL10n(
                data: loc ?? AppLocalizations(localeProvider.locale, {}),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: StreamBuilder(
              stream: AuthService.instance.authStateChanges,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                if (snapshot.hasData) {
                  return const MainShell();
                }
                return const LoginScreen();
              },
            ),
          ),
        );
      },
    );
  }
}
