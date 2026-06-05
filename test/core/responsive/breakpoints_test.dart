import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:transitly/core/responsive/breakpoints.dart';

/// Sub P2.5-01: tests para el sistema de breakpoints.
void main() {
  Widget testWrapper({required Size size, required Widget child}) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    );
  }

  testWidgets('isMobile returns true for width < 600', (tester) async {
    late bool result;
    await tester.pumpWidget(testWrapper(
      size: const Size(360, 800),
      child: Builder(
        builder: (c) {
          result = Breakpoints.isMobile(c);
          return const SizedBox();
        },
      ),
    ));
    expect(result, isTrue);
  });

  testWidgets('isTablet returns true for 600 <= width < 1024', (tester) async {
    late bool result;
    await tester.pumpWidget(testWrapper(
      size: const Size(800, 1024),
      child: Builder(
        builder: (c) {
          result = Breakpoints.isTablet(c);
          return const SizedBox();
        },
      ),
    ));
    expect(result, isTrue);
  });

  testWidgets('isDesktop returns true for width >= 1024', (tester) async {
    late bool result;
    await tester.pumpWidget(testWrapper(
      size: const Size(1440, 900),
      child: Builder(
        builder: (c) {
          result = Breakpoints.isDesktop(c);
          return const SizedBox();
        },
      ),
    ));
    expect(result, isTrue);
  });

  testWidgets('isWideDesktop returns true for width >= 1440', (tester) async {
    late bool result;
    await tester.pumpWidget(testWrapper(
      size: const Size(1920, 1080),
      child: Builder(
        builder: (c) {
          result = Breakpoints.isWideDesktop(c);
          return const SizedBox();
        },
      ),
    ));
    expect(result, isTrue);
  });

  testWidgets('shouldUseSideNav respects desktop, tablet, landscape',
      (tester) async {
    // Móvil portrait → bottom nav.
    late bool mobilePortrait;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(360, 800)),
      child: Builder(
        builder: (c) {
          mobilePortrait = Breakpoints.shouldUseSideNav(c);
          return const SizedBox();
        },
      ),
    ));
    expect(mobilePortrait, isFalse);

    // Desktop → side nav.
    late bool desktop;
    await tester.pumpWidget(MediaQuery(
      data: const MediaQueryData(size: Size(1440, 900)),
      child: Builder(
        builder: (c) {
          desktop = Breakpoints.shouldUseSideNav(c);
          return const SizedBox();
        },
      ),
    ));
    expect(desktop, isTrue);
  });
}
