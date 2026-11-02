import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    super.key, 
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.green,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home, size: 20), label: 'الرئيسية'),
            BottomNavigationBarItem(icon: Icon(Icons.restaurant, size: 20), label: 'الوجبات'),
            BottomNavigationBarItem(icon: Icon(Icons.fitness_center, size: 20), label: 'التمارين'),
            BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner, size: 20), label: 'مسح الباركود'),
            BottomNavigationBarItem(icon: Icon(Icons.show_chart, size: 20), label: 'التقدم'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline, size: 20), label: 'ريفو'),
          ],
        ),
      ),
    );
  }
}