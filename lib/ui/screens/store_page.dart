/// 🏪 STORE PAGE - Modern Store UI with Giant CTA
/// Part of the new tab navigation system
library;

import 'package:flutter/material.dart';
import '../../game/systems/monetization_manager.dart';
import 'store_screen.dart';

class StorePage extends StatefulWidget {
  final MonetizationManager monetization;

  const StorePage({
    super.key,
    required this.monetization,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  @override
  Widget build(BuildContext context) {
    // For now, wrap the existing StoreScreen
    // In Phase 4, we'll redesign this to fit the new navigation paradigm
    return const StoreScreen();
  }
}

