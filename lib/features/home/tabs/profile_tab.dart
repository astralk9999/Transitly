import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/auth/auth_repository.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/user_provider.dart';
import '../../../shared/widgets/responsive_scaffold.dart';
import '../widgets/profile_about_section.dart';
import '../widgets/profile_accessibility_section.dart';
import '../widgets/profile_appearance_section.dart';
import '../widgets/profile_contributions_section.dart';
import '../widgets/profile_header_card.dart';
import '../widgets/profile_location_section.dart';
import '../widgets/profile_notifications_section.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final padding = ResponsiveScaffold.screenPadding(context);
    final isAuthenticated =
        ref.watch(authStateProvider).valueOrNull is AuthAuthenticated;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: ContentConstraints(
        maxWidth: 600,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.all(padding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    ProfileHeaderCard(user: user),
                    const SizedBox(height: 16),
                    const ProfileAppearanceSection(),
                    const SizedBox(height: 16),
                    const ProfileLocationSection(),
                    // Contribuciones solo tras autenticar — sin login no hay
                    // datos reales y mostrar mock confunde al usuario.
                    if (isAuthenticated) ...[
                      const SizedBox(height: 16),
                      ProfileContributionsSection(user: user),
                    ],
                    const SizedBox(height: 16),
                    const ProfileNotificationsSection(),
                    const SizedBox(height: 16),
                    const ProfileAccessibilitySection(),
                    const SizedBox(height: 16),
                    const ProfileAboutSection(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
