import 'package:flutter/material.dart';

abstract class StanomerColors {
  // Brand (logodan)
  static const brandPrimary = Color(0xFF1A5EB8);
  static const brandPrimaryPressed = Color(0xFF0E3D80);
  static const brandPrimarySurface = Color(0xFFE6EEF9);

  // Success / Paid (logodan)
  static const successPrimary = Color(0xFF2DB87A);
  static const successPressed = Color(0xFF1D8A5A);
  static const successSurface = Color(0xFFE6F7F0);

  // Alert / Overdue
  static const alertPrimary = Color(0xFFC8503A);
  static const alertPressed = Color(0xFFA83D29);
  static const alertSurface = Color(0xFFFDF0EE);

  // Status
  static const statusPaid = Color(0xFF2DB87A);
  static const statusPaidSurface = Color(0xFFE6F7F0);
  static const statusPending = Color(0xFFB06C10);
  static const statusPendingSurface = Color(0xFFFEF6E8);
  static const statusPartial = Color(0xFF1A5EB8);
  static const statusPartialSurface = Color(0xFFE6EEF9);

  // Text
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textTertiary = Color(0xFF767676);
  static const textDisabled = Color(0x521A1A1A); // 32% opacity
  static const textInverse = Color(0xFFFFFFFF);

  // Surface
  static const bgPage = Color(0xFFF8F7F5);
  static const bgCard = Color(0xFFFFFFFF);
  static const borderDefault = Color(0xFFEBEBEB);
  static const borderPrimary = Color(0xFFEBEBEB);
  static const borderInput = Color(0xFFC8C8C8);
  static const borderFocused = Color(0xFF1A5EB8);

  // Role Colors (Airbnb logic)
  static const landlord = Color(0xFF1A5EB8);        // Blue
  static const landlordPressed = Color(0xFF0E3D80);
  static const landlordSurface = Color(0xFFE6EEF9);
  
  static const tenant = Color(0xFF2DB87A);          // Green
  static const tenantPressed = Color(0xFF1D8A5A);
  static const tenantSurface = Color(0xFFE6F7F0);

  static Color getRoleColor(String? role) {
    if (role == 'landlord') return landlord;
    if (role == 'tenant') return tenant;
    return brandPrimary;
  }

  static Color getRoleSurfaceColor(String? role) {
    if (role == 'landlord') return landlordSurface;
    if (role == 'tenant') return tenantSurface;
    return brandPrimarySurface;
  }
}

abstract class StanomerRadius {
  static const xs = Radius.circular(4);
  static const sm = Radius.circular(6);
  static const md = Radius.circular(8);
  static const lg = Radius.circular(10);
  static const xl = Radius.circular(16);
  static const full = Radius.circular(9999);
}

abstract class StanomerShadows {
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 1, offset: Offset(0, 1)), // Updated slightly for v3
  ];
  static const sheet = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const fab = [
    BoxShadow(color: Color(0x521A5EB8), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
