import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/property/domain/property_owner.dart';

void main() {
  group('Multiple Owners & Co-owner Access Logic Tests', () {
    test('Primary owner requires email and is marked as primary', () {
      final primaryOwner = PropertyOwner(
        isPrimary: true,
        ownerType: PropertyOwnerType.individual,
        firstName: 'Nikola',
        lastName: 'Nikolić',
        phone: '+381611112233',
        email: 'nikola@example.com',
        idDocumentNumber: 'SRB123456',
        secondaryContact: '+381619998877 (Spouse)',
      );

      expect(primaryOwner.isPrimary, isTrue);
      expect(primaryOwner.email, isNotNull);
      expect(primaryOwner.email, 'nikola@example.com');
      expect(primaryOwner.displayName, 'Nikola Nikolić');
      expect(primaryOwner.secondaryContact, contains('Spouse'));
    });

    test('Co-owner with optional email can be resolved for login matching', () {
      final coOwnerWithEmail = PropertyOwner(
        isPrimary: false,
        ownerType: PropertyOwnerType.individual,
        firstName: 'Jelena',
        lastName: 'Nikolić',
        phone: '+381622223344',
        email: 'jelena@example.com',
        ownershipPercentage: 50.0,
      );

      final coOwnerWithoutEmail = PropertyOwner(
        isPrimary: false,
        ownerType: PropertyOwnerType.individual,
        firstName: 'Mihajlo',
        lastName: 'Nikolić',
        phone: '+381633334455',
        email: null,
        ownershipPercentage: 25.0,
      );

      // Verify email matching helper logic
      final userLoggedInEmail = 'jelena@example.com';

      final owners = [coOwnerWithEmail, coOwnerWithoutEmail];

      final matchingOwner = owners.firstWhere(
        (o) => o.email?.trim().toLowerCase() == userLoggedInEmail.trim().toLowerCase(),
        orElse: () => const PropertyOwner(),
      );

      expect(matchingOwner.firstName, 'Jelena');
      expect(matchingOwner.email, 'jelena@example.com');

      // Unmatched check
      final anotherUserEmail = 'unknown@example.com';
      final hasAccess = owners.any((o) => o.email?.trim().toLowerCase() == anotherUserEmail.toLowerCase());
      expect(hasAccess, isFalse);
    });

    test('Company owner with representative, PIB, and documents serialization', () {
      final companyOwner = PropertyOwner(
        isPrimary: true,
        ownerType: PropertyOwnerType.company,
        companyName: 'Belgrade Real Estate Holding d.o.o.',
        registeredAddress: 'Bulevar Kralja Aleksandra 100',
        pib: '109876543',
        registrationNumber: '20987654',
        representativeName: 'Aleksandar Petrović',
        representativeIdNumber: '1122334455',
        representativeIdDetails: 'General Manager',
        phone: '+381112223344',
        secondaryContact: '+381112223345 (Accounting)',
        email: 'office@belgrade-holding.rs',
        documents: const [
          PropertyOwnerDocument(
            type: OwnerDocumentType.ownershipProof,
            name: 'vlasnicki_list.pdf',
            url: 'https://storage.stanomer.com/vlasnicki_list.pdf',
          ),
          PropertyOwnerDocument(
            type: OwnerDocumentType.powerOfAttorney,
            name: 'ovlascenje_agencija.pdf',
            url: 'https://storage.stanomer.com/ovlascenje.pdf',
          ),
        ],
      );

      expect(companyOwner.ownerType, PropertyOwnerType.company);
      expect(companyOwner.displayName, 'Belgrade Real Estate Holding d.o.o.');
      expect(companyOwner.pib, '109876543');
      expect(companyOwner.representativeName, 'Aleksandar Petrović');
      expect(companyOwner.documents.length, 2);

      final json = companyOwner.toJson();
      expect(json['company_name'], 'Belgrade Real Estate Holding d.o.o.');
      expect(json['pib'], '109876543');
      expect(json['documents'], isA<List>());
      expect((json['documents'] as List).length, 2);

      final fromJson = PropertyOwner.fromJson(json);
      expect(fromJson.displayName, 'Belgrade Real Estate Holding d.o.o.');
      expect(fromJson.documents.first.type, OwnerDocumentType.ownershipProof);
      expect(fromJson.documents.last.type, OwnerDocumentType.powerOfAttorney);
    });
  });
}
