/// 🏪 STORE PAGE - Modern Store UI with Giant CTA
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import 'store_screen.dart';

class StorePage extends StatefulWidget {
  final MonetizationManager monetization;
  final String? initialCategory; // ✅ NEW: Support initial category selection

  const StorePage({
    super.key,
    required this.monetization,
    this.initialCategory,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  Widget build(BuildContext context) {
    // Wrap the existing StoreScreen with optional initial category
    return StoreScreen(initialCategory: widget.initialCategory);
  }
}

