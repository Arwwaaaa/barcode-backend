import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';
import 'scanner_screen.dart';
import 'app_screen.dart';

void main() {
  runApp(const FoodAllergyApp());
}

class FoodAllergyApp extends StatelessWidget {
  const FoodAllergyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Rivo - فحص حساسية الطعام',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _currentIndex = 3; 

  final List<Widget> _screens = [
    const CustomPlaceholderScreen(title: 'الرئيسية'),
    const CustomPlaceholderScreen(title: 'الوجبات'),
    const CustomPlaceholderScreen(title: 'التمارين'),
    const ScannerScreen(), 
    const CustomPlaceholderScreen(title: 'التقدم'),
    const CustomPlaceholderScreen(title: 'ريفو'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}