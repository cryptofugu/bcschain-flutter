import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'src/configuration_service.dart';
import 'src/pages/intro_page.dart';
import 'src/pages/screen_lock_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var configurationService = ConfigurationService(prefs);
  bool? isWalletSetup = configurationService.didSetupBCSWallet();
  runApp(
    MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('ru', ''), 
      ],
      theme: ThemeData(
        primaryColor: Color(0xffbb9f89),
        buttonColor: Color(0xffbb9f89),
        indicatorColor: Color(0xffbb9f89),
        scaffoldBackgroundColor: Color(0xff27262e),
        unselectedWidgetColor: Color(0xffbb9f89),
        textTheme: TextTheme(
          bodyText1: TextStyle(),
          bodyText2: TextStyle(),
          caption: TextStyle(),
          button: TextStyle()
        ).apply(
          bodyColor: Color(0xffbb9f89), 
          displayColor: Color(0xffbb9f89) 
        ),
      ),
      home: (!isWalletSetup) ? IntroPage() : ScreenLockPage()
    )
  );
}