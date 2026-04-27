import 'package:flutter/material.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page1.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page2.dart';
import 'package:fyp_ui_design/screens/dope_pages/dope_page3.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';


class OnBoardingScreen extends StatefulWidget {
  const OnBoardingScreen({super.key});

  @override
  State<OnBoardingScreen> createState() => _OnBoardingScreenState();
}

class _OnBoardingScreenState extends State<OnBoardingScreen> {
  final PageController _pageController = PageController();
  bool isLastPage = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: const Alignment(0, 0.65),
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                isLastPage = index == 2;
              });
            },
            children: const [
              Intro_Page1(),
              Intro_Page2(),
              Intro_Page3(),
            ],
          ),

          /// Bottom controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {
                    _pageController.jumpToPage(2);
                  },
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                SmoothPageIndicator(
                  controller: _pageController,
                  count: 3,
                  effect: const SwapEffect(
                    activeDotColor: Colors.blue,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    if (isLastPage) {
                      Navigator.pushReplacementNamed(
                        context,
                        '/choose-role',
                      );
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  child: Text(
                    isLastPage ? 'Done' : 'Next',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
