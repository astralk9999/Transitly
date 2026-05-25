import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/transit_animations.dart';
import '../../core/theme/transit_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_button.dart';
import 'onboarding_page_data.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _pageController;
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

  List<OnboardingPageData> _buildPages(AppLocalizations l10n, Color c) {
    return [
      OnboardingPageData(
        title: l10n.onboardingPage1Title,
        description: l10n.onboardingPage1Description,
        icon: Icons.directions_bus_rounded,
        accentColor: c,
      ),
      OnboardingPageData(
        title: l10n.onboardingPage2Title,
        description: l10n.onboardingPage2Description,
        icon: Icons.groups_rounded,
        accentColor: c,
      ),
      OnboardingPageData(
        title: l10n.onboardingPage3Title,
        description: l10n.onboardingPage3Description,
        icon: Icons.cloud_download_rounded,
        accentColor: c,
      ),
    ];
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _goHome() {
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('hasSeenOnboarding', true),
    );
    context.go('/home/inicio');
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: TransitAnimations.normal,
        curve: TransitAnimations.transitEaseOut,
      );
    } else {
      _goHome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final pages = _buildPages(l10n, c.accent);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      body: SmokeBackground(
        isDark: isDark,
        child: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: _onPageChanged,
                        itemCount: pages.length,
                        itemBuilder: (context, index) {
                          final page = pages[index];
                          return _OnboardingPage(page: page, isDark: isDark);
                        },
                      ),
                    ),
                    _buildDots(pages.length, c),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: SizedBox(
                        width: double.infinity,
                        child: TransitButton(
                          label: isLast
                              ? l10n.onboardingGetStarted
                              : l10n.onboardingNext,
                          onPressed: _nextPage,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
              Positioned(
                top: 0,
                right: 4,
                child: TextButton(
                  onPressed: _goHome,
                  style: TextButton.styleFrom(
                    foregroundColor: c.textMid,
                  ),
                  child: Text(
                    l10n.onboardingSkip.toUpperCase(),
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots(int count, TransitColorScheme c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == _currentPage;
        return AnimatedContainer(
          duration: TransitAnimations.normal,
          curve: TransitAnimations.transitEaseOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive ? c.accent : c.textLo,
          ),
        );
      }),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.page, required this.isDark});

  final OnboardingPageData page;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final c = TransitColorScheme.of(isDark);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: c.accent.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Icon(
              page.icon,
              size: 48,
              color: c.accent,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DM Sans', 
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: c.textHi,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'DM Sans', 
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: c.textMid,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
