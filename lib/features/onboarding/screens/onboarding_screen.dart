import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../services/storage_service.dart';
import '../../shared/widgets/custom_button.dart';
import '../../auth/screens/login_screen.dart';
import '../models/onboarding_page.dart';
import '../widgets/onboarding_page_widget.dart';
import '../widgets/page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<OnboardingPageData> _getPages(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return [
      OnboardingPageData(
        title: l10n?.onboardingPage1Title ?? 'Welcome to Lavendia',
        subtitle: l10n?.onboardingPage1Subtitle ?? 'Track Your Laundry',
        description: l10n?.onboardingPage1Description ??
            'Keep track of your laundry orders in real-time with easy status updates and notifications',
        icon: Icons.local_laundry_service,
        color: AppColors.primary,
      ),
      OnboardingPageData(
        title: l10n?.onboardingPage2Title ?? 'Easy QR Pickup',
        subtitle: l10n?.onboardingPage2Subtitle ?? 'Scan & Collect',
        description: l10n?.onboardingPage2Description ??
            'Show your QR code when picking up your laundry for quick and secure collection',
        icon: Icons.qr_code_2,
        color: AppColors.secondary,
      ),
      OnboardingPageData(
        title: l10n?.onboardingPage3Title ?? 'Stay Informed',
        subtitle: l10n?.onboardingPage3Subtitle ?? 'Real-Time Notifications',
        description: l10n?.onboardingPage3Description ??
            'Receive instant updates when your laundry status changes from washing to ready for pickup',
        icon: Icons.notifications_active,
        color: AppColors.info,
      ),
    ];
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    await StorageService().saveOnboardingCompleted(true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pages = _getPages(context);
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    l10n?.onboardingSkip ?? 'Skip',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  return OnboardingPageWidget(pageData: pages[index]);
                },
              ),
            ),

            // Page indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: PageIndicator(
                currentPage: _currentPage,
                pageCount: pages.length,
              ),
            ),

            // Navigation button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: CustomButton(
                text: isLastPage
                    ? (l10n?.onboardingGetStarted ?? 'Get Started')
                    : (l10n?.onboardingNext ?? 'Next'),
                onPressed: _nextPage,
                icon: isLastPage ? Icons.arrow_forward : Icons.navigate_next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
