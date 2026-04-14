import 'package:flutter/material.dart';

import '../../core/theme/transit_colors.dart';
import '../../core/theme/transit_typography.dart';
import '../models/stop_model.dart';
import 'transit_button.dart';

class RouteSearchBar extends StatefulWidget {
  const RouteSearchBar({
    super.key,
    this.availableStops,
    this.onSearch,
  });

  final List<StopModel>? availableStops;
  final VoidCallback? onSearch;

  @override
  State<RouteSearchBar> createState() => _RouteSearchBarState();
}

class _RouteSearchBarState extends State<RouteSearchBar> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  List<StopModel> _fromSuggestions = [];
  List<StopModel> _toSuggestions = [];
  bool _showFromSuggestions = false;
  bool _showToSuggestions = false;

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
  }

  @override
  void dispose() {
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final c = TransitColorScheme.of(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.bgSurface,
        border: Border.all(color: c.border, width: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // From field
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: c.textMid, width: 1.5),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTextField(
                  controller: _fromController,
                  focusNode: _fromFocus,
                  hint: 'Desde...',
                  colors: c,
                  onChanged: _filterFrom,
                ),
              ),
            ],
          ),
          // Suggestions for From
          if (_showFromSuggestions)
            _buildSuggestionsList(
              _fromSuggestions,
              c,
              (stop) {
                _fromController.text = stop.name;
                setState(() => _showFromSuggestions = false);
              },
            ),
          // Vertical connector
          Row(
            children: [
              SizedBox(
                width: 8,
                child: Center(
                  child: Container(
                    width: 1,
                    height: 16,
                    color: c.border,
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
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: c.accent,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: _buildTextField(
                  controller: _toController,
                  focusNode: _toFocus,
                  hint: 'Hasta...',
                  colors: c,
                  onChanged: _filterTo,
                ),
              ),
            ],
          ),
          // Suggestions for To
          if (_showToSuggestions)
            _buildSuggestionsList(
              _toSuggestions,
              c,
              (stop) {
                _toController.text = stop.name;
                setState(() => _showToSuggestions = false);
              },
            ),
          const SizedBox(height: 16),
          // Search button
          SizedBox(
            width: double.infinity,
            child: TransitButton(
              label: 'BUSCAR RUTA',
              onPressed: widget.onSearch,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required TransitColorScheme colors,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TransitTypography.bodyPrimary(colors.textHi),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TransitTypography.bodyPrimary(colors.textLo),
        filled: true,
        fillColor: colors.bgInput,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
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
      margin: const EdgeInsets.only(left: 20, top: 2),
      decoration: BoxDecoration(
        color: colors.bgSurface,
        border: Border.all(color: colors.border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: suggestions.map((stop) {
          return InkWell(
            onTap: () => onSelect(stop),
            splashFactory: NoSplash.splashFactory,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
