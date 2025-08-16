// ignore: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:shopmate_ai/homescreen.dart';
void main() {
  runApp(ShopMateAI());
}

class ShopMateAI extends StatelessWidget {
  const ShopMateAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopMate.AI',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Color(0xFFF5F5F5), // off-white background
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Color(0xFF1A1A1A), // not pure black
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
        ),
      ),

      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
