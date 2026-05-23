import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/utils/app_logger.dart';
import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/models/enums.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/reputation_badge.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/smoke_background.dart';
import '../../shared/widgets/transit_app_bar.dart';
import '../../shared/widgets/transit_chip.dart';
import '../../shared/widgets/transit_input.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _loading = true;
  bool _offline = false;
  String? _error;

  String _searchQuery = '';
  String? _roleFilter;

  Timer? _debounce;
  final _searchController = TextEditingController();

  static const _roleOptions = <String?>[
    null,
    'passenger',
    'driver',
    'operatorAdmin',
    'moderator',
    'admin',
  ];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
      _offline = false;
    });

    try {
      final client = ref.read(supabaseClientProvider);
      final session = client.auth.currentSession;
      if (session == null) {
        setState(() {
          _loading = false;
          _offline = true;
          _allUsers = [];
          _filteredUsers = [];
        });
        return;
      }

      final rows = await client
          .from('profiles')
          .select('id, display_name, email, role, reputation_score, reputation_level')
          .order('display_name');

      setState(() {
        _allUsers = rows.cast<Map<String, dynamic>>();
        _loading = false;
        _applyFilters();
      });
    } catch (e) {
      AppLogger.warn('admin_users_screen: load failed', e.toString());
      setState(() {
        _loading = false;
        _error = '';
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchQuery = value;
        _applyFilters();
      });
    });
  }

  void _onRoleFilterChanged(String? role) {
    setState(() {
      _roleFilter = _roleFilter == role ? null : role;
      _applyFilters();
    });
  }

  void _applyFilters() {
    _filteredUsers = _allUsers.where((u) {
      final name = (u['display_name'] as String? ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      if (query.isNotEmpty && !name.contains(query)) return false;
      if (_roleFilter != null) {
        final role = u['role'] as String?;
        if (role != _roleFilter) return false;
      }
      return true;
    }).toList();
  }

  String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
        'admin' => l10n.adminUsersRoleAdmin,
        'moderator' => l10n.adminUsersRoleModerator,
        'operatorAdmin' => l10n.adminUsersRoleOperatorAdmin,
        'driver' => l10n.adminUsersRoleDriver,
        _ => l10n.adminUsersRolePassenger,
      };

  String _roleFilterLabel(AppLocalizations l10n, String? role) => switch (role) {
        null => l10n.adminUsersRoleAll,
        'admin' => l10n.adminUsersRoleAdmin,
        'moderator' => l10n.adminUsersRoleModerator,
        'operatorAdmin' => l10n.adminUsersRoleOperatorAdmin,
        'driver' => l10n.adminUsersRoleDriver,
        _ => l10n.adminUsersRolePassenger,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return RoleGate(
      allow: const [UserRole.admin],
      child: Scaffold(
        backgroundColor: c.bgRoot,
        body: Stack(
          children: [
            Positioned.fill(
              child: SmokeBackground(color: c.accent, isDark: isDark),
            ),
            Column(
              children: [
                TransitAppBar(title: l10n.adminUsersTitle),
                Expanded(child: _buildContent(c, l10n)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(TransitColorScheme c, AppLocalizations l10n) {
    if (_loading) {
      return ShimmerSkeleton.list(
        context: context,
        count: 6,
        builder: () => ShimmerSkeleton.routeCard(context),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ErrorCard(l10n.adminUsersError, onRetry: _loadUsers),
        ),
      );
    }

    if (_offline) {
      return EmptyState(
        l10n.adminUsersNoConnection,
        l10n.adminUsersOffline,
        icon: Icons.cloud_off,
      );
    }

    if (_allUsers.isEmpty) {
      return EmptyState(
        l10n.adminUsersNoConnection,
        l10n.adminUsersEmpty,
        icon: Icons.people_outline,
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TransitInput(
            hint: l10n.adminUsersSearchHint,
            controller: _searchController,
            onChanged: _onSearchChanged,
            prefix: const Icon(Icons.search),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _roleOptions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final role = _roleOptions[index];
              final isSelected = _roleFilter == role;
              return TransitChip(
                _roleFilterLabel(l10n, role),
                color: isSelected ? c.accent : c.textLo,
                onTap: () => _onRoleFilterChanged(role),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filteredUsers.isEmpty
              ? EmptyState(
                  l10n.adminUsersNoResults,
                  _searchQuery.isNotEmpty
                      ? l10n.adminUsersNoMatchSearch(_searchQuery)
                      : l10n.adminUsersNoMatchRole,
                  icon: Icons.search_off,
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = _filteredUsers[index];
                    final name = user['display_name'] as String? ?? '?';
                    final email = user['email'] as String? ?? '';
                    final role = user['role'] as String? ?? 'passenger';
                    final repLevel =
                        user['reputation_level'] as String? ?? 'new';

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _filteredUsers.length - 1 ? 8 : 0,
                      ),
                      child: GlassCard(
                        blur: 12,
                        fillOpacity: 0.05,
                        borderRadius: 12,
                        padding: const EdgeInsets.all(12),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: c.accent.withValues(alpha: 0.12),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.ibmPlexMono(
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TransitTypography.bodyPrimary(c.textHi),
                          ),
                          subtitle: Text(
                            email,
                            style: TransitTypography.bodySecondary(c.textMid),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TransitChip(_roleLabel(l10n, role)),
                              const SizedBox(width: 8),
                              ReputationBadge(
                                ReputationLevel.fromString(repLevel),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
