import 'package:flutter/material.dart';
import 'package:glass/glass.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';

import '../tabs/illustration_tab.dart';
import '../tabs/device_tab.dart';
import '../tabs/home_tab.dart';
import '../theme/app_colors.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF0EBF4),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background gradient

          SafeArea(
            child: Column(
              children: [
                _buildInvisibleAppBar(),
                const SizedBox(height: 8),
                _buildTabBar(),

                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: const [
                      HomeTab(),
                      DeviceTab(),
                      IllustrationTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ).asGlass(
          enabled: true,
          tintColor: Colors.transparent,
          clipBorderRadius: BorderRadius.circular(25.0),
          frosted: true,
          blurX: 200,
          blurY: 100
      ),
    );
  }

  // -----------------------------------------------------
  // TOP TITLE
  // -----------------------------------------------------
  Widget _buildInvisibleAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HandSpeaks',
              style: TextStyle(
                fontFamily: "Urbanist",
                fontWeight: FontWeight.w700,
                fontSize: 25,
              ),
            ),
            Container(
              child: Text(
                'PRO',
                style: TextStyle(
                  fontFamily: "Urbanist",
                  fontWeight: FontWeight.w700,
                  fontSize: 25,
                    color: AppColors.pureWhite,
                ),
              ),
              decoration: BoxDecoration(
                borderRadius:BorderRadius.circular(10.0),
                border: Border.all(
                  width: 2.0,          // border thickness
                ),
                color: AppColors.pureBlack
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------
  // FIXED CUSTOM TAB BAR
  // -----------------------------------------------------
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            _buildTabButton("Translate", 0, Icons.translate),
            _buildTabButton("Connect", 1, Icons.bluetooth_connected),
            _buildTabButton("Illustration", 2, Icons.sign_language),
          ],
        ),
      ).asGlass(
        enabled: true,
        tintColor: Colors.transparent,
        clipBorderRadius: BorderRadius.circular(14.0),
        frosted: true,
        blurX: 200,
        blurY: 50,
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isActive = _currentPage == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.all(4), // Add small margin for spacing
          decoration: BoxDecoration(
            color: isActive ? AppColors.pureBlack : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : AppColors.pureBlack,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: "Urbanist",
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isActive ? Colors.white : AppColors.pureBlack,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }



}
