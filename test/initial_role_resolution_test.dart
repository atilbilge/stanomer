import 'package:flutter_test/flutter_test.dart';

enum InitialRoleOutcome {
  autoTenant,
  autoLandlord,
  userSelection,
  alreadySet,
}

InitialRoleOutcome resolveInitialRole({
  required bool initialRoleSet,
  required String? metaRole,
  required bool isExistingLandlord,
  required bool isExistingTenant,
  required bool hasTenantInvite,
  required bool hasLandlordInvite,
}) {
  if (initialRoleSet || metaRole != null) {
    return InitialRoleOutcome.alreadySet;
  }
  if (isExistingLandlord || isExistingTenant) {
    return InitialRoleOutcome.alreadySet;
  }

  if (hasTenantInvite && !hasLandlordInvite) {
    return InitialRoleOutcome.autoTenant;
  } else if (hasLandlordInvite && !hasTenantInvite) {
    return InitialRoleOutcome.autoLandlord;
  } else {
    return InitialRoleOutcome.userSelection;
  }
}

void main() {
  group('Invitation-based Initial Role Resolution Tests', () {
    test('User invited ONLY as tenant defaults to tenant on first login', () {
      final outcome = resolveInitialRole(
        initialRoleSet: false,
        metaRole: null,
        isExistingLandlord: false,
        isExistingTenant: false,
        hasTenantInvite: true,
        hasLandlordInvite: false,
      );
      expect(outcome, equals(InitialRoleOutcome.autoTenant));
    });

    test('User invited ONLY as landlord defaults to landlord on first login', () {
      final outcome = resolveInitialRole(
        initialRoleSet: false,
        metaRole: null,
        isExistingLandlord: false,
        isExistingTenant: false,
        hasTenantInvite: false,
        hasLandlordInvite: true,
      );
      expect(outcome, equals(InitialRoleOutcome.autoLandlord));
    });

    test('User with BOTH tenant and landlord invites must select role', () {
      final outcome = resolveInitialRole(
        initialRoleSet: false,
        metaRole: null,
        isExistingLandlord: false,
        isExistingTenant: false,
        hasTenantInvite: true,
        hasLandlordInvite: true,
      );
      expect(outcome, equals(InitialRoleOutcome.userSelection));
    });

    test('User with NEITHER invite must select role on first login', () {
      final outcome = resolveInitialRole(
        initialRoleSet: false,
        metaRole: null,
        isExistingLandlord: false,
        isExistingTenant: false,
        hasTenantInvite: false,
        hasLandlordInvite: false,
      );
      expect(outcome, equals(InitialRoleOutcome.userSelection));
    });

    test('Existing landlord is not prompted for initial role', () {
      final outcome = resolveInitialRole(
        initialRoleSet: false,
        metaRole: null,
        isExistingLandlord: true,
        isExistingTenant: false,
        hasTenantInvite: false,
        hasLandlordInvite: false,
      );
      expect(outcome, equals(InitialRoleOutcome.alreadySet));
    });

    test('Existing user with confirmed role is not prompted', () {
      final outcome = resolveInitialRole(
        initialRoleSet: true,
        metaRole: 'tenant',
        isExistingLandlord: false,
        isExistingTenant: false,
        hasTenantInvite: true,
        hasLandlordInvite: true,
      );
      expect(outcome, equals(InitialRoleOutcome.alreadySet));
    });
  });
}
