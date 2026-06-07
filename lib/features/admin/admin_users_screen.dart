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
import '../../shared/models/reputation.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/error_card.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/role_gate.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/transit_app_bar.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  Map<String, String> _operatorNames = {}; // id → name
  bool _loading = true;
  bool _offline = false;
  String? _error;

  String _searchQuery = '';
  String? _roleFilter;
  bool _onlyBanned = false;
  _SortMode _sort = _SortMode.nameAsc;

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

      final results = await Future.wait([
        client
            .from('profiles')
            .select(
                'id, display_name, role, reputation_score, reputation_level, routes_created_count, created_at, is_banned, operator_id')
            .order('display_name'),
        client
            .from('operators')
            .select('id, name')
            .eq('is_active', true),
      ]);

      final ops = <String, String>{
        for (final o in (results[1] as List).cast<Map<String, dynamic>>())
          (o['id'] as String): (o['name'] as String? ?? ''),
      };

      setState(() {
        _allUsers = (results[0] as List).cast<Map<String, dynamic>>();
        _operatorNames = ops;
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
    final query = _searchQuery.toLowerCase().trim();
    _filteredUsers = _allUsers.where((u) {
      final name = (u['display_name'] as String? ?? '').toLowerCase();
      if (query.isNotEmpty && !name.contains(query)) return false;
      if (_roleFilter != null && u['role'] != _roleFilter) return false;
      if (_onlyBanned && u['is_banned'] != true) return false;
      return true;
    }).toList();
    // Orden.
    switch (_sort) {
      case _SortMode.nameAsc:
        _filteredUsers.sort((a, b) => (a['display_name'] as String? ?? '')
            .compareTo(b['display_name'] as String? ?? ''));
      case _SortMode.nameDesc:
        _filteredUsers.sort((a, b) => (b['display_name'] as String? ?? '')
            .compareTo(a['display_name'] as String? ?? ''));
      case _SortMode.xpDesc:
        _filteredUsers.sort((a, b) =>
            ((b['reputation_score'] as num?)?.toInt() ?? 0)
                .compareTo((a['reputation_score'] as num?)?.toInt() ?? 0));
      case _SortMode.xpAsc:
        _filteredUsers.sort((a, b) =>
            ((a['reputation_score'] as num?)?.toInt() ?? 0)
                .compareTo((b['reputation_score'] as num?)?.toInt() ?? 0));
      case _SortMode.newest:
        _filteredUsers.sort((a, b) => (b['created_at'] as String? ?? '')
            .compareTo(a['created_at'] as String? ?? ''));
    }
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
        _statsHeader(c),
        _searchBar(c, l10n),
        _filtersBar(c, l10n),
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
              : RefreshIndicator(
                  color: c.accent,
                  onRefresh: _loadUsers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: _filteredUsers.length,
                    itemBuilder: (context, index) =>
                        _buildUserCard(context, c, l10n, _filteredUsers[index]),
                  ),
                ),
        ),
      ],
    );
  }

  // ── Header con totales ─────────────────────────────────────
  Widget _statsHeader(TransitColorScheme c) {
    final total = _allUsers.length;
    final banned = _allUsers.where((u) => u['is_banned'] == true).length;
    final admins =
        _allUsers.where((u) => u['role'] == 'admin').length;
    final drivers =
        _allUsers.where((u) => u['role'] == 'driver').length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          Expanded(child: _statPill(c, Icons.people, '$total', 'Total', c.accent)),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.shield_outlined, '$admins',
                  'Admins', const Color(0xFFE91E63))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.directions_bus_outlined,
                  '$drivers', 'Conductores', const Color(0xFF2196F3))),
          const SizedBox(width: 8),
          Expanded(
              child: _statPill(c, Icons.block, '$banned', 'Baneados',
                  const Color(0xFFB71C1C))),
        ],
      ),
    );
  }

  Widget _statPill(TransitColorScheme c, IconData icon, String value,
      String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(value,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.textHi,
                  )),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: TransitTypography.bodySmall(c.textLo),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  // ── Buscador ───────────────────────────────────────────────
  Widget _searchBar(TransitColorScheme c, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(Icons.search, size: 18, color: c.textMid),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TransitTypography.bodyPrimary(c.textHi),
                decoration: InputDecoration(
                  hintText: l10n.adminUsersSearchHint,
                  hintStyle: TransitTypography.bodySecondary(c.textMid),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              IconButton(
                icon: Icon(Icons.close, size: 16, color: c.textMid),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _applyFilters();
                  });
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  // ── Chips de filtros + sort ────────────────────────────────
  Widget _filtersBar(TransitColorScheme c, AppLocalizations l10n) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final r in _roleOptions) ...[
            _filterChip(
              c,
              icon: r == null ? Icons.group : _roleIconFor(r),
              label: _roleFilterLabel(l10n, r),
              selected: _roleFilter == r,
              color: r == null ? c.accent : _roleColorFor(c, r),
              onTap: () => _onRoleFilterChanged(r),
            ),
            const SizedBox(width: 6),
          ],
          _filterChip(
            c,
            icon: Icons.block,
            label: 'Baneados',
            selected: _onlyBanned,
            color: const Color(0xFFB71C1C),
            onTap: () {
              setState(() {
                _onlyBanned = !_onlyBanned;
                _applyFilters();
              });
            },
          ),
          const SizedBox(width: 6),
          PopupMenuButton<_SortMode>(
            initialValue: _sort,
            position: PopupMenuPosition.under,
            onSelected: (v) {
              setState(() {
                _sort = v;
                _applyFilters();
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: _SortMode.nameAsc, child: Text('Nombre A-Z')),
              const PopupMenuItem(
                  value: _SortMode.nameDesc, child: Text('Nombre Z-A')),
              const PopupMenuItem(
                  value: _SortMode.xpDesc, child: Text('Más XP primero')),
              const PopupMenuItem(
                  value: _SortMode.xpAsc, child: Text('Menos XP primero')),
              const PopupMenuItem(
                  value: _SortMode.newest, child: Text('Más nuevos')),
            ],
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: c.bgRaised,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.border, width: 0.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort, size: 14, color: c.textMid),
                  const SizedBox(width: 4),
                  Text(_sortLabel(_sort),
                      style: TransitTypography.bodySmall(c.textHi)),
                  const SizedBox(width: 2),
                  Icon(Icons.arrow_drop_down, size: 16, color: c.textMid),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(
    TransitColorScheme c, {
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : c.bgRaised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : c.border,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : c.textMid),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? color : c.textHi,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }

  // ── Card de usuario ───────────────────────────────────────
  Widget _buildUserCard(BuildContext context, TransitColorScheme c,
      AppLocalizations l10n, Map<String, dynamic> user) {
    final name = user['display_name'] as String? ?? '?';
    final role = user['role'] as String? ?? 'passenger';
    final score = (user['reputation_score'] as num?)?.toInt() ?? 0;
    final isBanned = user['is_banned'] == true;
    final routesCount =
        (user['routes_created_count'] as num?)?.toInt() ?? 0;
    final operatorId = user['operator_id'] as String?;
    final operatorName =
        operatorId == null ? null : _operatorNames[operatorId];
    final rank = ReputationRank.forScore(score);
    final roleColor = _roleColorFor(c, role);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          await context.push('/admin/users/${user['id']}');
          if (mounted) await _loadUsers();
        },
        child: GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 12,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar con borde de color del rango
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: rank.color.withValues(alpha: 0.18),
                  border: Border.all(color: rank.color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: rank.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Datos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: TransitTypography.bodyPrimary(c.textHi),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isBanned) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.block,
                              size: 14, color: Color(0xFFB71C1C)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _miniBadge(c,
                            icon: _roleIconFor(role),
                            label: _roleLabel(l10n, role),
                            color: roleColor),
                        _miniBadge(c,
                            icon: rank.icon,
                            label: '$score XP',
                            color: rank.color),
                        if (routesCount > 0)
                          _miniBadge(c,
                              icon: Icons.route_outlined,
                              label: '$routesCount rutas',
                              color: c.textMid),
                        if (operatorName != null)
                          _miniBadge(c,
                              icon: Icons.apartment,
                              label: operatorName,
                              color: c.accent),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: c.textLo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _miniBadge(TransitColorScheme c,
      {required IconData icon,
      required String label,
      required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              )),
        ],
      ),
    );
  }

  IconData _roleIconFor(String role) {
    return switch (role) {
      'admin' => Icons.shield_outlined,
      'moderator' => Icons.gavel_outlined,
      'operatorAdmin' => Icons.apartment_outlined,
      'driver' => Icons.directions_bus_outlined,
      _ => Icons.person_outline,
    };
  }

  Color _roleColorFor(TransitColorScheme c, String role) {
    return switch (role) {
      'admin' => const Color(0xFFE91E63),
      'moderator' => const Color(0xFFFF9800),
      'operatorAdmin' => const Color(0xFF9C27B0),
      'driver' => const Color(0xFF2196F3),
      _ => c.textMid,
    };
  }

  String _sortLabel(_SortMode s) {
    return switch (s) {
      _SortMode.nameAsc => 'A-Z',
      _SortMode.nameDesc => 'Z-A',
      _SortMode.xpDesc => 'XP ↓',
      _SortMode.xpAsc => 'XP ↑',
      _SortMode.newest => 'Nuevos',
    };
  }
}

enum _SortMode { nameAsc, nameDesc, xpDesc, xpAsc, newest }

