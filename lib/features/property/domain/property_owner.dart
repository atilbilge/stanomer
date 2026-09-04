enum PropertyOwnerType {
  individual,
  company;

  static PropertyOwnerType fromString(String? value) {
    if (value == 'company') return PropertyOwnerType.company;
    return PropertyOwnerType.individual;
  }
}

enum OwnerDocumentType {
  idDocument,
  ownershipProof,
  powerOfAttorney,
  other;

  static OwnerDocumentType fromString(String? value) {
    switch (value) {
      case 'id_document':
        return OwnerDocumentType.idDocument;
      case 'ownership_proof':
        return OwnerDocumentType.ownershipProof;
      case 'power_of_attorney':
        return OwnerDocumentType.powerOfAttorney;
      default:
        return OwnerDocumentType.other;
    }
  }

  String toDbString() {
    switch (this) {
      case OwnerDocumentType.idDocument:
        return 'id_document';
      case OwnerDocumentType.ownershipProof:
        return 'ownership_proof';
      case OwnerDocumentType.powerOfAttorney:
        return 'power_of_attorney';
      case OwnerDocumentType.other:
        return 'other';
    }
  }
}

class PropertyOwnerDocument {
  final OwnerDocumentType type;
  final String name;
  final String url;
  final DateTime? uploadedAt;

  const PropertyOwnerDocument({
    required this.type,
    required this.name,
    required this.url,
    this.uploadedAt,
  });

  factory PropertyOwnerDocument.fromJson(Map<String, dynamic> json) {
    return PropertyOwnerDocument(
      type: OwnerDocumentType.fromString(json['type'] as String?),
      name: json['name'] as String? ?? 'document.pdf',
      url: json['url'] as String? ?? '',
      uploadedAt: json['uploaded_at'] != null ? DateTime.tryParse(json['uploaded_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.toDbString(),
      'name': name,
      'url': url,
      'uploaded_at': uploadedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  PropertyOwnerDocument copyWith({
    OwnerDocumentType? type,
    String? name,
    String? url,
    DateTime? uploadedAt,
  }) {
    return PropertyOwnerDocument(
      type: type ?? this.type,
      name: name ?? this.name,
      url: url ?? this.url,
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class PropertyOwner {
  final String? id;
  final String? propertyId;
  final PropertyOwnerType ownerType;
  final bool isPrimary;
  final double ownershipPercentage;

  // Individual / Shared Contact
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? secondaryContact;
  final String? email;

  // Individual ID
  final String? idDocumentNumber;
  final String? idDetails;

  // Company / Legal Entity
  final String? companyName;
  final String? registeredAddress;
  final String? pib;
  final String? registrationNumber;
  final String? representativeName;
  final String? representativeIdNumber;
  final String? representativeIdDetails;

  // Supporting Documents
  final List<PropertyOwnerDocument> documents;
  final DateTime? createdAt;

  const PropertyOwner({
    this.id,
    this.propertyId,
    this.ownerType = PropertyOwnerType.individual,
    this.isPrimary = false,
    this.ownershipPercentage = 100.0,
    this.firstName,
    this.lastName,
    this.phone,
    this.secondaryContact,
    this.email,
    this.idDocumentNumber,
    this.idDetails,
    this.companyName,
    this.registeredAddress,
    this.pib,
    this.registrationNumber,
    this.representativeName,
    this.representativeIdNumber,
    this.representativeIdDetails,
    this.documents = const [],
    this.createdAt,
  });

  String get displayName {
    if (ownerType == PropertyOwnerType.company) {
      return (companyName != null && companyName!.trim().isNotEmpty) ? companyName!.trim() : 'Şirket';
    }
    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return full.isNotEmpty ? full : 'Malik';
  }

  bool get isCompany => ownerType == PropertyOwnerType.company;
  bool get isIndividual => ownerType == PropertyOwnerType.individual;
  String? get idNumber => idDocumentNumber;

  factory PropertyOwner.fromJson(Map<String, dynamic> json) {
    final docsList = (json['documents'] as List<dynamic>?)
            ?.map((e) => PropertyOwnerDocument.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return PropertyOwner(
      id: json['id'] as String?,
      propertyId: json['property_id'] as String?,
      ownerType: PropertyOwnerType.fromString(json['owner_type'] as String?),
      isPrimary: json['is_primary'] as bool? ?? false,
      ownershipPercentage: (json['ownership_percentage'] as num?)?.toDouble() ?? 100.0,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      phone: json['phone'] as String?,
      secondaryContact: json['secondary_contact'] as String?,
      email: json['email'] as String?,
      idDocumentNumber: json['id_document_number'] as String?,
      idDetails: json['id_details'] as String?,
      companyName: json['company_name'] as String?,
      registeredAddress: json['registered_address'] as String?,
      pib: json['pib'] as String?,
      registrationNumber: json['registration_number'] as String?,
      representativeName: json['representative_name'] as String?,
      representativeIdNumber: json['representative_id_number'] as String?,
      representativeIdDetails: json['representative_id_details'] as String?,
      documents: docsList,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson({bool excludeId = false}) {
    final map = <String, dynamic>{
      'owner_type': ownerType == PropertyOwnerType.company ? 'company' : 'individual',
      'is_primary': isPrimary,
      'ownership_percentage': ownershipPercentage,
      'first_name': firstName?.trim(),
      'last_name': lastName?.trim(),
      'phone': phone?.trim(),
      'secondary_contact': secondaryContact?.trim(),
      'email': (email != null && email!.trim().isNotEmpty) ? email!.trim().toLowerCase() : null,
      'id_document_number': idDocumentNumber?.trim(),
      'id_details': idDetails?.trim(),
      'company_name': companyName?.trim(),
      'registered_address': registeredAddress?.trim(),
      'pib': pib?.trim(),
      'registration_number': registrationNumber?.trim(),
      'representative_name': representativeName?.trim(),
      'representative_id_number': representativeIdNumber?.trim(),
      'representative_id_details': representativeIdDetails?.trim(),
      'documents': documents.map((d) => d.toJson()).toList(),
    };

    if (propertyId != null) map['property_id'] = propertyId;
    if (!excludeId && id != null) map['id'] = id;
    return map;
  }

  PropertyOwner copyWith({
    String? id,
    String? propertyId,
    PropertyOwnerType? ownerType,
    bool? isPrimary,
    double? ownershipPercentage,
    String? firstName,
    String? lastName,
    String? phone,
    String? secondaryContact,
    String? email,
    String? idDocumentNumber,
    String? idDetails,
    String? companyName,
    String? registeredAddress,
    String? pib,
    String? registrationNumber,
    String? representativeName,
    String? representativeIdNumber,
    String? representativeIdDetails,
    List<PropertyOwnerDocument>? documents,
    DateTime? createdAt,
  }) {
    return PropertyOwner(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      ownerType: ownerType ?? this.ownerType,
      isPrimary: isPrimary ?? this.isPrimary,
      ownershipPercentage: ownershipPercentage ?? this.ownershipPercentage,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      secondaryContact: secondaryContact ?? this.secondaryContact,
      email: email ?? this.email,
      idDocumentNumber: idDocumentNumber ?? this.idDocumentNumber,
      idDetails: idDetails ?? this.idDetails,
      companyName: companyName ?? this.companyName,
      registeredAddress: registeredAddress ?? this.registeredAddress,
      pib: pib ?? this.pib,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      representativeName: representativeName ?? this.representativeName,
      representativeIdNumber: representativeIdNumber ?? this.representativeIdNumber,
      representativeIdDetails: representativeIdDetails ?? this.representativeIdDetails,
      documents: documents ?? this.documents,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
