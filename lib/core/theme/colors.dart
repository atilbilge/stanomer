import 'package:flutter/material.dart';

/// Stanomer Design System v4.0 (Kasım 2026)
/// Single Source of Truth: BRAND_GUIDELINES.md

abstract class SColors {
  // Marka (logodan ölçüldü: #1B5888, #40945D)
  static const brand        = Color(0xFF1B5888);
  static const brandPressed = Color(0xFF12406A);
  static const brandSurface = Color(0xFFE5EEF6);
  static const logoGreen    = Color(0xFF40945D); // yalnızca grafik ve ikon

  // Durum
  static const successText    = Color(0xFF2A6E43);
  static const successSurface = Color(0xFFE6F3EA);
  static const alert          = Color(0xFFB5432E);
  static const alertText      = Color(0xFFA33C29);
  static const alertSurface   = Color(0xFFFBEAE6);
  static const pendingText    = Color(0xFF8A5206);
  static const pendingSurface = Color(0xFFFBF1DC);
  static const pendingGraphic = Color(0xFFE0A63A);

  // Nötr
  static const bgPage        = Color(0xFFF8F7F5);
  static const bgCard        = Color(0xFFFFFFFF);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSecondary = Color(0xFF4A4A4A);
  static const textTertiary  = Color(0xFF666666);
  static const borderDefault = Color(0xFFE5E3DF);
  static const borderInput   = Color(0xFF8A8A8A);
}

abstract class SColorsDark {
  static const bgPage = Color(0xFF0D1828);
  static const bgCard = Color(0xFF142238);
  static const brand = Color(0xFF6FA6DA);
  static const successText = Color(0xFF5DBB7E);
  static const alertText = Color(0xFFE5806C);
  static const pendingText = Color(0xFFE3B04F);
  static const textPrimary = Color(0xFFE8EEF5);
  static const textSecondary = Color(0xFF9DAEC2);
  static const borderDefault = Color(0xFF25374F);
}

abstract class SShadows {
  static const card = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 0, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static const sheet = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
  ];
}

/// Backward compatibility layer for StanomerColors
abstract class StanomerColors {
  // Brand (logodan ölçüldü)
  static const brandPrimary = SColors.brand;
  static const brandPrimaryPressed = SColors.brandPressed;
  static const brandPrimarySurface = SColors.brandSurface;
  static const logoGreen = SColors.logoGreen;

  // Success / Paid
  static const successPrimary = SColors.successText;
  static const successPressed = Color(0xFF1F5734);
  static const successSurface = SColors.successSurface;

  // Alert / Overdue
  static const alertPrimary = SColors.alert;
  static const alertPressed = SColors.alertText;
  static const alertSurface = SColors.alertSurface;

  // Status
  static const statusPaid = SColors.successText;
  static const statusPaidSurface = SColors.successSurface;
  static const statusPending = SColors.pendingText;
  static const statusPendingSurface = SColors.pendingSurface;
  static const statusPartial = SColors.brand;
  static const statusPartialSurface = SColors.brandSurface;

  // Text
  static const textPrimary = SColors.textPrimary;
  static const textSecondary = SColors.textSecondary;
  static const textTertiary = SColors.textTertiary;
  static const textDisabled = Color(0x521A1A1A); // 32% opacity
  static const textInverse = Color(0xFFFFFFFF);

  // Surface
  static const bgPage = SColors.bgPage;
  static const bgCard = SColors.bgCard;
  static const borderDefault = SColors.borderDefault;
  static const borderPrimary = SColors.borderDefault;
  static const borderInput = SColors.borderInput;
  static const borderFocused = SColors.brand;

  // Neutral Role Helpers (Design System v4: Roller renkle değil ikon ve etiketle ayrılır)
  static const landlord = SColors.brand;
  static const landlordPressed = SColors.brandPressed;
  static const landlordSurface = SColors.brandSurface;

  static const tenant = SColors.logoGreen;
  static const tenantPressed = Color(0xFF1F5734);
  static const tenantSurface = SColors.successSurface;

  static Color getRoleColor(String? role) => SColors.brand;
  static Color getRoleSurfaceColor(String? role) => SColors.brandSurface;
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
  static const card = SShadows.card;
  static const sheet = SShadows.sheet;
  static const fab = [
    BoxShadow(color: Color(0x521B5888), blurRadius: 16, offset: Offset(0, 4)),
  ];
}
