import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User-selected locale. `null` means follow the system locale.
final localeProvider = StateProvider<Locale?>((ref) => null);
