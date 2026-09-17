import 'package:concentric_transition/concentric_transition.dart';
import 'package:flutter/material.dart';

import 'package:durus/l10n/l10n_ext.dart';

/// First-run intro, adapted from the MIT-licensed fluttertemplates.dev
/// "Concentric Animation Onboarding" sample (same widget, same values):
/// full-screen pages with the next page's color blooming in as a growing
/// circle. Durus differences: Arabic RTL content, brand colors, finite
/// pages (itemCount), per-page skip and a final ابدأ button. Shown once
/// per install by [IntroGate] (see router.dart), before sign-in.
class IntroScreen extends StatelessWidget {
  const IntroScreen({super.key, required this.onDone});

  /// Called (once) when the user finishes or skips the intro.
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = [
      _IntroPageData(
        icon: Icons.school_outlined,
        title: l10n.introTitle1,
        subtitle: l10n.introSub1,
        bgColor: const Color(0xFF0A3B2E),
        textColor: Colors.white,
      ),
      _IntroPageData(
        icon: Icons.fact_check_outlined,
        title: l10n.introTitle2,
        subtitle: l10n.introSub2,
        bgColor: const Color(0xFF0E7C66),
        textColor: Colors.white,
      ),
      _IntroPageData(
        icon: Icons.family_restroom_outlined,
        title: l10n.introTitle3,
        subtitle: l10n.introSub3,
        bgColor: const Color(0xFFFAF8F4),
        textColor: const Color(0xFF14213D),
      ),
    ];
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: ConcentricPageView(
        colors: [for (final p in pages) p.bgColor],
        radius: screenWidth * 0.1,
        itemCount: pages.length,
        scaleFactor: 2,
        nextButtonBuilder: (context) => Padding(
          // Visual centering, mirrored for RTL (forward points left).
          padding: const EdgeInsets.only(right: 3),
          child: Icon(Icons.chevron_left, size: screenWidth * 0.08),
        ),
        // Optional second parameter keeps this compatible whether the
        // package calls itemBuilder with (index) or (index, value).
        itemBuilder: (index, [value]) {
          final page = pages[index % pages.length];
          return SafeArea(
            child: _IntroPage(
              page: page,
              isLast: index % pages.length == pages.length - 1,
              onDone: onDone,
            ),
          );
        },
      ),
    );
  }
}

class _IntroPageData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color bgColor;
  final Color textColor;

  const _IntroPageData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.bgColor,
    required this.textColor,
  });
}

class _IntroPage extends StatelessWidget {
  final _IntroPageData page;
  final bool isLast;
  final VoidCallback onDone;

  const _IntroPage({
    required this.page,
    required this.isLast,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final screenHeight = MediaQuery.of(context).size.height;
    final light = page.bgColor.computeLuminance() > 0.5;
    final buttonBg = light ? const Color(0xFF0E7C66) : Colors.white;
    final buttonFg = light ? Colors.white : const Color(0xFF0A3B2E);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: page.textColor,
            ),
            child: Icon(
              page.icon,
              size: screenHeight * 0.09,
              color: page.bgColor,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: page.textColor,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: page.textColor.withValues(alpha: 0.85),
              fontSize: 16,
              height: 1.7,
            ),
          ),
          const SizedBox(height: 40),
          if (isLast)
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: buttonBg,
                foregroundColor: buttonFg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 14,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              onPressed: onDone,
              child: Text(l10n.introStart),
            )
          else
            TextButton(
              style: TextButton.styleFrom(foregroundColor: page.textColor),
              onPressed: onDone,
              child: Text(
                l10n.introSkip,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          // Room for the package's floating next button.
          const SizedBox(height: 72),
        ],
      ),
    );
  }
}
