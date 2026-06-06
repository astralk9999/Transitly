import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

      // profiles NO tiene columna `email` — el email vive en
      // auth.users. Pedirlo provocaba 42703. routes_created_count y
      // created_at se incluyen para mostrar más info en el sheet.
      final rows = await client
          .from('profiles')
          .select(
              'id, display_name, role, reputation_score, reputation_level, routes_created_count, created_at')
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
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Column(
              children: [
                TransitAppBar(title: l10n.adminUsersTitle, transparent: true),
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
                    final role = user['role'] as String? ?? 'passenger';
                    // reputation_level en BD es INTEGER (0..6), no
                    // string. Lo derivamos del score igual que
                    // UserModel.fromJson.
                    final score = (user['reputation_score'] as num?)?.toInt() ?? 0;
                    final repLevel = score >= 500
                        ? 'expert'
                        : score >= 50
                            ? 'trusted'
                            : score >= 10
                                ? 'contributor'
                                : 'new';

                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: index < _filteredUsers.length - 1 ? 8 : 0,
                      ),
                      child: GlassCard(
                        blur: 12,
                        fillOpacity: 0.05,
                        borderRadius: 12,
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          // Tap → pantalla detalle. Al volver
                          // (sea pop o gesto back) recargamos para
                          // reflejar cualquier mutación (rol, XP,
                          // rango) sin necesidad de salir/entrar.
                          onTap: () async {
                            await context.push('/admin/users/${user['id']}');
                            if (mounted) await _loadUsers();
                          },
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                            '$score XP',
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

  void _showUserSheet(
      Map<String, dynamic> user, AppLocalizations l10n, TransitColorScheme c) {
    final userId = user['id'] as String;
    final name = user['display_name'] as String? ?? '?';
    final currentRole = user['role'] as String? ?? 'passenger';
    final score = (user['reputation_score'] as num?)?.toInt() ?? 0;
    final routesCreated =
        (user['routes_created_count'] as num?)?.toInt() ?? 0;
    final createdAt = user['created_at'] as String?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20,
              20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(name, style: TransitTypography.heading(c.textHi)),
              const SizedBox(height: 4),
              Text(
                'ID: ${userId.substring(0, 8)}...',
                style: TransitTypography.bodySmall(c.textLo),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _statChip(c, Icons.star_rounded, '$score XP'),
                  _statChip(c, Icons.route_outlined,
                      '$routesCreated rutas'),
                  if (createdAt != null)
                    _statChip(c, Icons.calendar_today,
                        createdAt.substring(0, 10)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Rol',
                  style: TransitTypography.bodyPrimary(c.textHi)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final r in const [
                    'passenger',
                    'driver',
                    'operatorAdmin',
                    'moderator',
                    'admin'
                  ])
                    ChoiceChip(
                      label: Text(_roleLabel(l10n, r)),
                      selected: currentRole == r,
                      onSelected: (_) async {
                        Navigator.pop(ctx);
                        await _changeRole(userId, r);
                      },
                      selectedColor: c.accent.withValues(alpha: 0.3),
                      backgroundColor: c.bgRaised,
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Text('XP',
                  style: TransitTypography.bodyPrimary(c.textHi)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _addXp(userId, 50);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+50 XP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _addXp(userId, 500);
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('+500 XP'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _addXp(userId, -50);
                    },
                    icon: const Icon(Icons.remove, size: 16),
                    label: const Text('-50 XP'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.stateCancelled,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _resetScore(userId);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset 0'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.stateCancelled,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _statChip(TransitColorScheme c, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.bgRaised,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c.textMid),
          const SizedBox(width: 6),
          Text(label, style: TransitTypography.bodySmall(c.textMid)),
        ],
      ),
    );
  }

  Future<void> _changeRole(String userId, String role) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({'role': role}).eq('id', userId);
      messenger.showSnackBar(SnackBar(content: Text('Rol → $role')));
      await _loadUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addXp(String userId, int delta) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(supabaseClientProvider);
      // add_xp() es la SQL function que ya recalcula level y dispara
      // notificaciones xp_earned / rank_up.
      await client.rpc('add_xp',
          params: {'p_user_id': userId, 'p_xp': delta});
      messenger.showSnackBar(SnackBar(content: Text('${delta >= 0 ? '+' : ''}$delta XP')));
      await _loadUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _resetScore(String userId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final client = ref.read(supabaseClientProvider);
      await client.from('profiles').update({
        'reputation_score': 0,
        'reputation_level': 0,
      }).eq('id', userId);
      messenger.showSnackBar(const SnackBar(content: Text('XP reseteado')));
      await _loadUsers();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
