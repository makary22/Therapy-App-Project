import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../home/HomeScreen.dart' show HomeScreen;

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<_PageData> pages = [
    _PageData(
      image: 'assets/icon/Mindfulness-cuate 1.png',
      title: 'Welcome to Safe Space',
      description:
          "Your safe place to share, reflect, and feel better. Let's take care of your mental well-being together",
    ),
    _PageData(
      image: 'assets/icon/Bipolar disorder-cuate 1.png',
      title: 'Know Your Feelings',
      description:
          "Pay attention to your daily emotions. Understanding your feelings helps you take better care of your mental health",
    ),
    _PageData(
      image: 'assets/icon/Learning-cuate 1.png',
      title: 'Ready to Reflect?',
      description:
          "Start tracking your emotions and receive supportive insights every day and let AI help you reflect, grow, and feel better.",
    ),
  ];

  Future<void> finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("seenOnboarding", true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onLogin() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Login tapped')));
  }

  void _goNext() {
    if (_currentIndex >= pages.length - 1) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _skipToLast() {
    if (_currentIndex >= pages.length - 1) return;

    _pageController.animateToPage(
      pages.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentIndex <= 0) return;

    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastPage = _currentIndex == pages.length - 1;
    final ctaWidth = (size.width * 0.62).clamp(220.0, 280.0).toDouble();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF96D0F6), Color(0xFFD6CEFF), Color(0xFFD6CEFF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: _currentIndex > 0
                    ? IconButton(
                        onPressed: _goBack,
                        icon: const Icon(
                          Icons.arrow_back,
                          size: 28,
                          color: Color(0xFF1F2642),
                        ),
                      )
                    : const SizedBox(height: 48, width: 48),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final page = pages[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: size.height * 0.4,
                            child: Image.asset(page.image),
                          ),

                          const SizedBox(height: 30),

                          Text(
                            page.title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF252648),
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF4D4F73),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => _Dot(isActive: _currentIndex == index),
                ),
              ),

              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: isLastPage
                    ? Column(
                        children: [
                          SizedBox(
                            width: ctaWidth,
                            child: ElevatedButton(
                              onPressed: finishOnboarding,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1F2D4A),
                                foregroundColor: Colors.white,
                                minimumSize: Size(ctaWidth, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Get Started",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3B3F61),
                                ),
                              ),
                              GestureDetector(
                                onTap: _onLogin,
                                child: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2A2E4D),
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: _skipToLast,
                            child: const Text(
                              "Skip",
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFF292A4E),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _goNext,
                            child: const Text(
                              "Next",
                              style: TextStyle(
                                fontSize: 20,
                                color: Color(0xFF292A4E),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _PageData {
  final String image;
  final String title;
  final String description;

  _PageData({
    required this.image,
    required this.title,
    required this.description,
  });
}

class _Dot extends StatelessWidget {
  final bool isActive;

  const _Dot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 12,
      width: isActive ? 28 : 12,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? const Color(0xFF3198D3) : const Color(0xFFA6AFEA),
      ),
    );
  }
}
