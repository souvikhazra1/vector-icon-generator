import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vector_icon_generator/change_notifiers/dark_mode_notifier.dart';
import 'package:vector_icon_generator/change_notifiers/download_progress_notifier.dart';
import 'package:vector_icon_generator/change_notifiers/icon_color_notifier.dart';
import 'package:vector_icon_generator/constants.dart';
import 'package:vector_icon_generator/pages/main_page.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => IconColorNotifier()),
      ChangeNotifierProvider(create: (context) => DownloadProgressNotifier()),
      ChangeNotifierProvider(create: (context) => DarkModeNotifier()),
    ],
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vector Icon Generator',
      theme: ThemeData(
        primarySwatch: Constants.lightSwatch,
        fontFamily: Constants.fontFamily,
      ),
      darkTheme: ThemeData(
        primarySwatch: Constants.darkSwatch,
        brightness: Brightness.dark,
        fontFamily: Constants.fontFamily,
        primaryColor: Constants.darkSwatch,
        toggleableActiveColor: Constants.lightSwatch,
        canvasColor: Colors.black,
        dividerColor: Colors.grey.shade800,
      ),
      themeMode: Provider.of<DarkModeNotifier>(context).darkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainPage(),
    );
  }
}

