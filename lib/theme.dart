import 'package:flutter/material.dart';

class CustomTheme {
  static const lightThemeFont = "ComicNeue";
  static const darkThemeFont = "Poppins";

  // Light theme
  static ThemeData lightTheme() {
    const Color appBarBackgroundColor = Color(0xff1B1B1B);
    const Color lightColor = Color(0xffDD9D21);
    return ThemeData(
      primaryColor: appBarBackgroundColor,
      brightness: Brightness.light,
      useMaterial3: true,
      fontFamily: lightThemeFont,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: appBarBackgroundColor,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontSize: 23,
        ),
      ),
      scaffoldBackgroundColor: appBarBackgroundColor,
    );
  }

  // Dark theme
  static ThemeData darkTheme() {
    const Color appBarBackgroundColor = Color(0xff1B1B1B);
    const Color darkColor = Color(0xffDD9D21);
    return ThemeData(
      primaryColor: appBarBackgroundColor,
      brightness: Brightness.dark,
      useMaterial3: true,
      fontFamily: darkThemeFont,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: appBarBackgroundColor,
        indicatorColor: darkColor,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: appBarBackgroundColor,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          color: Colors.white,
          fontSize: 23,
        ),
      ),
      scaffoldBackgroundColor: appBarBackgroundColor,
    );
  }
}
