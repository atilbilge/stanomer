// lib/core/utils/rbac_utils.dart
//
// Role-Based Access Control (RBAC) utility functions for Stanomer B2B2C.
//
// Business rules:
//  - If the active user is a TENANT and the property is managed by an AGENCY
//    (property.agencyId != null), tenants may only VIEW payments (read-only).
//    Declaring payments, uploading receipts or marking as paid is DISABLED.
//  - In all other cases (direct landlord-tenant, no agency), tenants can
//    declare payments as usual.

import '../../features/property/domain/property.dart';

class RbacUtils {
  RbacUtils._(); // static-only utility class

  /// Returns true if the tenant can declare/mark a payment for this property.
  ///
  /// [activeRole] — the user's current active role string ('landlord', 'tenant', 'agency')
  /// [property]  — the property the payment belongs to
  static bool canTenantDeclarePayment({
    required String? activeRole,
    required Property property,
  }) {
    if (activeRole != 'tenant') return true; // Non-tenant users unaffected
    // Tenant under agency-managed property → read-only
    if (property.agencyId != null) return false;
    return true;
  }

  /// Returns true if the current user (by role) can manage (approve/reject) payments.
  ///
  /// Agency users can manage payments for their managed properties.
  /// Landlords can manage their own properties.
  /// Tenants never manage payments.
  static bool canManagePayments({required String? activeRole}) {
    return activeRole == 'landlord' || activeRole == 'agency';
  }

  /// Returns true if this user role has access to the agency dashboard.
  static bool isAgencyUser({required String? role}) {
    return role == 'agency';
  }
}
