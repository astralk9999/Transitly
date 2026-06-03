import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../../data/supabase/supabase_client_provider.dart';
import '../../data/user_routes/user_routes_repository.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/glass_card.dart';
import '../../shared/widgets/pressable.dart';
import '../../shared/widgets/shimmer_skeleton.dart';
import '../../shared/widgets/status_badge.dart';

const _serviceTypes = [
  ('all', 'Todas'),
  ('urban', 'Urbano'),
  ('interurban', 'Interurbano'),
  ('long_distance', 'Larga distancia'),
];

const _sortOptions = [
  ('recent', 'Más recientes'),
  ('votes', 'Más votadas'),
  ('views', 'Más vistas'),
];

class CommunityRoutesScreen extends ConsumerStatefulWidget {
  const CommunityRoutesScreen({super.key});

  @override
  ConsumerState<CommunityRoutesScreen> createState() =>
      _CommunityRoutesScreenState();
}

class _CommunityRoutesScreenState extends ConsumerState<CommunityRoutesScreen> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  List<UserRouteModel> _routes = [];
  String _selectedType = 'all';
  String _selectedSort = 'recent';
  bool _loading = false;
  bool _hasMore = true;
  int _page = 0;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
    _fetchFirstPage();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loading &&
        _hasMore) {
      _fetchNextPage();
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _resetAndFetch);
  }

  void _resetAndFetch() {
    setState(() {
      _routes = [];
      _page = 0;
      _hasMore = true;
    });
    _fetchFirstPage();
  }

  Future<void> _fetchFirstPage() async {
    setState(() => _loading = true);
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final results = await repo.searchPublic(
        query: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        serviceType: _selectedType != 'all' ? _selectedType : null,
        limit: _pageSize,
        offset: 0,
      );
      if (mounted) {
        setState(() {
          _routes = _sortRoutes(results);
          _page = 1;
          _hasMore = results.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchNextPage() async {
    setState(() => _loading = true);
    final repo = ref.read(userRoutesRepositoryProvider);
    if (repo == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final offset = _page * _pageSize;
      final results = await repo.searchPublic(
        query: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        serviceType: _selectedType != 'all' ? _selectedType : null,
        limit: _pageSize,
        offset: offset,
      );
      if (mounted) {
        setState(() {
          _routes.addAll(_sortRoutes(results));
          _page++;
          _hasMore = results.length >= _pageSize;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserRouteModel> _sortRoutes(List<UserRouteModel> routes) {
    return switch (_selectedSort) {
      'votes' => List.of(routes)..sort((a, b) => b.voteCount.compareTo(a.voteCount)),
      'views' => List.of(routes)..sort((a, b) => b.viewCount.compareTo(a.viewCount)),
      _ => List.of(routes)..sort((a, b) {
          final da = a.createdAt ?? a.publishedAt ?? DateTime(2020);
          final db = b.createdAt ?? b.publishedAt ?? DateTime(2020);
          return db.compareTo(da);
        }),
    };
  }

  void _onTypeChanged(String type) {
    setState(() => _selectedType = type);
    _resetAndFetch();
  }

  void _onSortChanged(String sort) {
    setState(() {
      _selectedSort = sort;
      _routes = _sortRoutes(_routes);
    });
  }

  Color _hexToColor(String hex) {
    try {
      final h = hex.replaceFirst('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFF977DDF);
    }
  }

  String _serviceTypeLabel(String type) {
    return switch (type) {
      'urban' => 'Urbano',
      'interurban' => 'Interurbano',
      'long_distance' => 'Larga distancia',
      _ => type,
    };
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return 'hace ${diff.inDays ~/ 30} meses';
    if (diff.inDays > 0) return 'hace ${diff.inDays}d';
    if (diff.inHours > 0) return 'hace ${diff.inHours}h';
    if (diff.inMinutes > 0) return 'hace ${diff.inMinutes}min';
    return 'ahora';
  }

  int _approvalPercent(UserRouteModel route) {
    final total = route.voteCount + route.reportCount;
    if (total == 0) return 100;
    return ((route.voteCount / total) * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final session = ref.read(supabaseClientProvider).auth.currentSession;

    if (session == null) {
      return Scaffold(
        backgroundColor: c.bgRoot,
        body: EmptyState(
          'Inicia sesión para ver la comunidad',
          'Conéctate para descubrir rutas creadas por otros usuarios',
          icon: Icons.people_outline,
          actionLabel: 'Iniciar sesión',
          onAction: () => context.push('/sign-in'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: c.bgRoot,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildSearchBar(c),
            _buildChipsRow(c),
            _buildSortRow(c),
            Expanded(
              child: _routes.isEmpty && _loading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 6,
                      itemBuilder: (_, __) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: ShimmerSkeleton.routeCard(context),
                      ),
                    )
                  : _routes.isEmpty
                      ? const EmptyState(
                          'Sin resultados',
                          'No se encontraron rutas públicas',
                          icon: Icons.route_outlined,
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _routes.length + (_loading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index >= _routes.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child:
                                    Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildRouteCard(c, _routes[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: GlassCard(
        blur: 16,
        fillOpacity: 0.05,
        borderRadius: 12,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: c.textHi),
              onPressed: () => context.pop(),
            ),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: TransitTypography.bodyPrimary(c.textHi),
                cursorColor: c.accent,
                decoration: InputDecoration(
                  hintText: 'Buscar rutas...',
                  hintStyle: TransitTypography.bodyPrimary(c.textLo),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            if (_searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: c.textMid, size: 20),
                onPressed: _searchController.clear,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipsRow(TransitColorScheme c) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _serviceTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (type, label) = _serviceTypes[index];
          final selected = type == _selectedType;
          return Pressable(
            onTap: () => _onTypeChanged(type),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? c.accent.withValues(alpha: 0.15) : c.bgRaised,
                border: Border.all(
                  color: selected ? c.accent : c.border,
                  width: 0.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TransitTypography.bodySmall(
                  selected ? c.accent : c.textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortRow(TransitColorScheme c) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          _SortButton(
            c: c,
            label: _sortOptions.firstWhere((e) => e.$1 == _selectedSort).$2,
            onTap: () {
              final idx = _sortOptions.indexWhere((e) => e.$1 == _selectedSort);
              final next = _sortOptions[(idx + 1) % _sortOptions.length];
              _onSortChanged(next.$1);
            },
          ),
          const Spacer(),
          Text(
            '${_routes.length} rutas',
            style: TransitTypography.bodySmall(c.textLo),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(TransitColorScheme c, UserRouteModel route) {
    final color = _hexToColor(route.routeColor);
    final approval = _approvalPercent(route);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: () => context.push('/community/route/${route.id}'),
        child: GlassCard(
          blur: 12,
          fillOpacity: 0.05,
          borderRadius: 10,
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      bottomLeft: Radius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                route.name,
                                style:
                                    TransitTypography.routeName(c.textHi),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            StatusBadge(
                              _serviceTypeLabel(route.serviceType),
                              color,
                            ),
                          ],
                        ),
                        if (route.description != null &&
                            route.description!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            route.description!,
                            style: TransitTypography.bodySecondary(c.textMid),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (route.totalDistanceKm != null) ...[
                              Icon(Icons.route_outlined,
                                  size: 13, color: c.textLo),
                              const SizedBox(width: 2),
                              Text(
                                '${route.totalDistanceKm!.toStringAsFixed(1)} km',
                                style:
                                    TransitTypography.bodySmall(c.textLo),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Text(
                              _timeAgo(route.createdAt),
                              style: TransitTypography.bodySmall(c.textLo),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.thumb_up_alt_outlined,
                                size: 13, color: c.textLo),
                            const SizedBox(width: 2),
                            Text(
                              '$approval%',
                              style: TransitTypography.bodySmall(c.textLo),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.favorite,
                                size: 14, color: c.stateCancelled),
                            const SizedBox(width: 4),
                            Text(
                              '${route.voteCount}',
                              style:
                                  TransitTypography.bodySmall(c.textMid),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.visibility,
                                size: 14, color: c.textMid),
                            const SizedBox(width: 4),
                            Text(
                              '${route.viewCount}',
                              style:
                                  TransitTypography.bodySmall(c.textMid),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: c.textMid, size: 20),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.c, required this.label, this.onTap});
  final TransitColorScheme c;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: c.bgRaised,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: c.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TransitTypography.bodySmall(c.textMid)),
            const SizedBox(width: 4),
            Icon(Icons.swap_vert, size: 14, color: c.textMid),
          ],
        ),
      ),
    );
  }
}
