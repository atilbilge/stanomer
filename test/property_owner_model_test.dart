import 'package:flutter_test/flutter_test.dart';
import 'package:stanomer/features/property/domain/property_owner.dart';

void main() {
  group('PropertyOwner Model Tests', () {
    test('Individual Owner serialization and deserialization', () {
      final json = {
        'id': 'owner-1',
        'property_id': 'prop-123',
        'owner_type': 'individual',
        'is_primary': true,
        'ownership_percentage': 50.0,
        'first_name': 'Marko',
        'last_name': 'Petrović',
        'phone': '+381601234567',
        'secondary_contact': '+381609876543 (Brother)',
        'email': 'marko@example.com',
        'id_document_number': '123456789',
        'id_details': 'MUP Beograd',
        'documents': [
          {
            'type': 'id_document',
            'name': 'passport.pdf',
            'url': 'https://example.com/passport.pdf',
            'uploaded_at': '2026-09-03T10:00:00.000Z',
          }
        ],
      };

      final owner = PropertyOwner.fromJson(json);
      expect(owner.id, 'owner-1');
      expect(owner.ownerType, PropertyOwnerType.individual);
      expect(owner.isPrimary, isTrue);
      expect(owner.displayName, 'Marko Petrović');
      expect(owner.secondaryContact, '+381609876543 (Brother)');
      expect(owner.documents.length, 1);
      expect(owner.documents.first.type, OwnerDocumentType.idDocument);

      final mapped = owner.toJson();
      expect(mapped['owner_type'], 'individual');
      expect(mapped['email'], 'marko@example.com');
      expect(mapped['secondary_contact'], '+381609876543 (Brother)');
    });

    test('Legal Entity / Company Owner serialization and deserialization', () {
      final json = {
        'id': 'owner-2',
        'property_id': 'prop-123',
        'owner_type': 'company',
        'is_primary': false,
        'ownership_percentage': 50.0,
        'company_name': 'Axia Real Estate d.o.o.',
        'registered_address': 'Knez Mihailova 10, Belgrade',
        'pib': '109876543',
        'registration_number': '20123456',
        'representative_name': 'Jovan Jovanović',
        'representative_id_number': '987654321',
        'representative_id_details': 'Director',
        'phone': '+381112345678',
        'secondary_contact': '+381112345679 (Office)',
        'email': 'office@axia.rs',
        'documents': [
          {
            'type': 'power_of_attorney',
            'name': 'ovlascenje.pdf',
            'url': 'https://example.com/poa.pdf',
          },
          {
            'type': 'ownership_proof',
            'name': 'vlasnicki_list.pdf',
            'url': 'https://example.com/tapu.pdf',
          }
        ],
      };

      final owner = PropertyOwner.fromJson(json);
      expect(owner.id, 'owner-2');
      expect(owner.ownerType, PropertyOwnerType.company);
      expect(owner.displayName, 'Axia Real Estate d.o.o.');
      expect(owner.pib, '109876543');
      expect(owner.registrationNumber, '20123456');
      expect(owner.representativeName, 'Jovan Jovanović');
      expect(owner.documents.length, 2);
      expect(owner.documents.first.type, OwnerDocumentType.powerOfAttorney);
      expect(owner.documents.last.type, OwnerDocumentType.ownershipProof);
    });
  });
}
