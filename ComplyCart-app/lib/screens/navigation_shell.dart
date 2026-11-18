import 'package:flutter/material.dart';
import 'sellers_screen.dart';
import 'analyze_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/premium_animated_header.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  final List<Widget> _views = [
    const VerifiedSellersView(),
    const UrlAnalyzerView(),
    const LabelScannerView(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isScanner = _selectedIndex == 2;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: isScanner 
          ? null 
          : PremiumAnimatedHeader(
              title: 'ComplyCart AI',
              onProfileTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
      body: Padding(
        padding: EdgeInsets.only(
          top: isScanner ? 0 : MediaQuery.of(context).padding.top + kToolbarHeight + 12,
        ),
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            const VerifiedSellersView(),
            const UrlAnalyzerView(),
            LabelScannerView(isActive: _selectedIndex == 2),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
