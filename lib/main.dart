import 'package:flutter/material.dart';
import 'package:handspeaks/pages/Sign_to_abled/HomePage.dart';
import 'package:handspeaks/pages/Selection_page.dart';
import 'package:handspeaks/pages/Splash_page.dart';
import 'package:handspeaks/theme/app_theme.dart';

import 'bluetooth/bluetooth_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: AppTheme.lightTheme,
        home: SplashPage(),
    );
  }
}
