import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_spacing.dart';
import '../../core/theme/transit_typography.dart';
import '../../l10n/generated/app_localizations.dart';
import '../models/stop_model.dart';
import 'glass_card.dart';
import 'pressable.dart';
import 'transit_button.dart';

class RouteSearchBar extends ConsumerStatefulWidget {
  const RouteSearchBar({
    super.key,
    this.availableStops,
    this.onSearch,
    this.onSearchWith,
  });

  final List<StopModel>? availableStops;
  final VoidCallback? onSearch;
  final void Function(StopModel? origin, StopModel? destination, bool useMyLocation)? onSearchWith;

  @override
  ConsumerState<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends ConsumerState<RouteSearchBar> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  List<StopModel> _fromSuggestions = [];
  List<StopModel> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;
  bool _useMyLocation = false;
  StopModel? _selectedOrigin;
  StopModel? _selectedDestination;
  bool? _locationPermissionDenied;

  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(() {
      if (!_fromFocus.hasFocus) {
        setState(() => _showFromSuggestions = false);
      }
    });
    _toFocus.addListener(() {
      if (!_toFocus.hasFocus) {
        setState(() => _showToSuggestions = false);
      }
    });
    _fromController.addListener(_onFromTextChanged);
    _toController.addListener(_onToTextChanged);
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Geolocator.checkPermission();
    if (mounted) {
      setState(() {
        _locationPermissionDenied =
            status == LocationPermission.denied ||
            status == LocationPermission.deniedForever;
      });
    }
  }

  void _onFromTextChanged() {
    if (_useMyLocation && _fromController.text.isEmpty) return;
    if (_useMyLocation && _fromController.text != '📍 ${AppLocalizations.of(context).myLocation}') {
      setState(() {
        _useMyLocation = false;
        _selectedOrigin = null;
      });
    }
  }

  void _onToTextChanged() {
    if (_toController.text.isEmpty) {
      setState(() => _selectedDestination = null);
    }
  }

  @override
  void dispose() {
    _fromController.removeListener(_onFromTextChanged);
    _toController.removeListener(_onToTextChanged);
    _fromController.dispose();
    _toController.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _filterFrom(String query) {
    if (widget.availableStops == null || query.length < 2) {
      setState(() {
        _fromSuggestions = [];
        _showFromSuggestions = false;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _fromSuggestions = widget.availableStops!
          .where((s) => s.name.toLowerCase().contains(q))
          .take(4)
          .toList();
      _showFromSuggestions = _fromSuggestions.isNotEmpty;
    });
  }

  void _filterTo(String query) {
    if (widget.availableStops == null || query.length < 2) {
      setState(() {
        _toSuggestions = [];
        _showToSuggestions = false;
      });
      return;
    }
    final q = query.toLowerCase();
    setState(() {
      _toSuggestions = widget.availableStops!
          .where((s) => s.name.toLowerCase().contains(q))
          .take(4)
          .toList();
      _showToSuggestions = _toSuggestions.isNotEmpty;
    });
  }

  void _handleSearch() {
    if (widget.onSearchWith != null) {
      widget.onSearchWith!(
        _useMyLocation ? null : _selectedOrigin,
        _selectedDestination,
        _useMyLocation,
      );
    } else {
      widget.onSearch?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);
    final l10n = AppLocalizations.of(context);
    final locationDenied = _locationPermissionDenied == true;

    return GlassCard(
      blur: 20,
      fillOpacity: 0.06,
      borderRadius: TransitSpacing.radiusXl + 4,
      padding: const EdgeInsets.all(TransitSpacing.space16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // My location toggle
          if (locationDenied)
            Tooltip(
              message: l10n.locationDisabledTooltip,
              child: _buildLocationChip(c, l10n, disabled: true),
            )
          else
            _buildLocationChip(c, l10n),
          const SizedBox(height: TransitSpacing.space8),
          // From field
          Row(
            children: [
              Container(
                width: TransitSpacing.space10,
                height: TransitSpacing.space10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.accent.withValues(alpha: 0.3),
                  border: Border.all(
                    color: c.accent,
                    width: TransitSpacing.strokeNormal + 0.5,
                  ),
                ),
              ),
              const SizedBox(width: TransitSpacing.space12),
              Expanded(
                child: _buildTextField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  hint: l10n.routeSearchFromHint,
                  colors: c,
                  onChanged: _filterFrom,
                  readOnly: _useMyLocation,
                ),
              ),
            ],
          ),
          if (_showFromSuggestions)
            _buildSuggestionsList(
              _fromSuggestions,
              c,
              (stop) {
                _fromController.text = stop.name;
                _selectedOrigin = stop;
                setState(() {
                  _showFromSuggestions = false;
                  _useMyLocation = false;
                });
              },
            ),
          // Vertical connector
          Row(
            children: [
              SizedBox(
                width: TransitSpacing.space10,
                child: Center(
                  child: Container(
                    width: TransitSpacing.strokeThin + 0.5,
                    height: TransitSpacing.space16,
                    color: c.accent.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
          // To field
          Row(
            children: [
              Container(
                width: TransitSpacing.space8,
                height: TransitSpacing.space8,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius:
                      BorderRadius.circular(TransitSpacing.radiusXs),
                ),
              ),
              const SizedBox(width: TransitSpacing.space12 + 1),
              Expanded(
                child: _buildTextField(
                  controller: _toController,
                  focusNode: _toFocus,
                  hint: l10n.routeSearchToHint,
                  colors: c,
                  onChanged: _filterTo,
                ),
              ),
            ],
          ),
          if (_showToSuggestions)
            _buildSuggestionsList(
              _toSuggestions,
              c,
              (stop) {
                _toController.text = stop.name;
                _selectedDestination = stop;
                setState(() => _showToSuggestions = false);
              },
            ),
          const SizedBox(height: TransitSpacing.space16),
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: l10n.searchButtonLabel,
              onPressed: _handleSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationChip(
    TransitColorScheme c,
    AppLocalizations l10n, {
    bool disabled = false,
  }) {
    final isActive = _useMyLocation && !disabled;
    return Pressable(
      enabled: !disabled,
      onTap: () {
        if (disabled) return;
        setState(() {
          _useMyLocation = !_useMyLocation;
          if (_useMyLocation) {
            _fromController.text = '📍 ${l10n.myLocation}';
            _selectedOrigin = null;
            _showFromSuggestions = false;
          } else {
            _fromController.clear();
            _selectedOrigin = null;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space12,
          vertical: TransitSpacing.space8,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? c.accent.withValues(alpha: 0.15)
              : disabled
                  ? c.bgSurface.withValues(alpha: 0.5)
                  : c.bgSurface.withValues(alpha: 0.0),
          borderRadius: BorderRadius.circular(TransitSpacing.radiusXl + 8),
          border: Border.all(
            color: isActive
                ? c.accent.withValues(alpha: 0.4)
                : disabled
                    ? c.border.withValues(alpha: 0.2)
                    : c.border.withValues(alpha: 0.3),
            width: TransitSpacing.strokeNormal,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.my_location,
              size: 18,
              color: isActive
                  ? c.accent
                  : disabled
                      ? c.textDisabled
                      : c.textMid,
            ),
            const SizedBox(width: TransitSpacing.space8),
            Text(
              l10n.useMyLocation,
              style: TransitTypography.bodySecondary(
                isActive
                    ? c.accent
                    : disabled
                        ? c.textDisabled
                        : c.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required TransitColorScheme colors,
    required ValueChanged<String> onChanged,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      readOnly: readOnly,
      onChanged: onChanged,
      style: TransitTypography.bodyPrimary(colors.textHi),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TransitTypography.bodyPrimary(colors.textLo),
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.border.withValues(alpha: 0.3)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: colors.accent.withValues(alpha: 0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: TransitSpacing.space4,
          vertical: TransitSpacing.space10,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildSuggestionsList(
    List<StopModel> suggestions,
    TransitColorScheme colors,
    ValueChanged<StopModel> onSelect,
  ) {
    return Container(
      margin: const EdgeInsets.only(
        left: TransitSpacing.space20 + 2,
        top: TransitSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(
          color: colors.border,
          width: TransitSpacing.strokeThin,
        ),
        borderRadius: BorderRadius.circular(TransitSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((stop) {
          return InkWell(
            onTap: () => onSelect(stop),
            splashFactory: NoSplash.splashFactory,
            borderRadius: BorderRadius.circular(TransitSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TransitSpacing.space10,
                vertical: TransitSpacing.space8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      stop.name,
                      style: TransitTypography.bodySecondary(colors.textHi),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    stop.officialCode,
                    style: TransitTypography.bodySmall(colors.textMid),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
