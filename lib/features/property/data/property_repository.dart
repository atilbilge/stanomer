import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/data/auth_providers.dart';
import '../domain/property.dart';
import '../domain/contract.dart';
import '../domain/rent_payment.dart';
import '../domain/activity_log.dart';
import '../domain/landlord_stats.dart';
import 'package:stanomer/core/utils/currency_utils.dart';
import 'package:rxdart/rxdart.dart';

enum RentStatus {
  debt,
  awaitingApproval,
  paid,
}

enum BillStatus {
  debt,
  awaitingApproval,
  waitingForLandlord,
  paid,
}

enum PropertyFinancialStatus {
  vacant,
  pendingApproval,
  invitationSent,
  negotiating,
}

class PropertyFinancialState {
  final PropertyFinancialStatus? generalStatus;
  final RentStatus? rentStatus;
  final BillStatus? billStatus;
  
  // Aggregate Metrics
  final Map<String, double> paidTotals;
  final Map<String, double> pendingTotals;
  final Map<String, double> awaitingTotals;
  final int paidCount;
  final int pendingCount;
  final int awaitingCount;

  const PropertyFinancialState({
    this.generalStatus,
    this.rentStatus,
    this.billStatus,
    this.paidTotals = const {},
    this.pendingTotals = const {},
    this.awaitingTotals = const {},
    this.paidCount = 0,
    this.pendingCount = 0,
    this.awaitingCount = 0,
  });
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  return PropertyRepository(Supabase.instance.client);
});

final propertiesStreamProvider = StreamProvider<List<Property>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return Stream.value([]);
  
  final role = user.userMetadata?['role'] as String?;
  return repo.getPropertiesStream(userId: user.id, role: role);
});

final propertiesFutureProvider = FutureProvider<List<Property>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null) return Future.value([]);
  
  final role = user.userMetadata?['role'] as String?;
  return repo.getProperties(role: role);
});

final propertyContractsProvider = StreamProvider.autoDispose.family<List<Contract>, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getPropertyContractsStream(propertyId);
});

final rentPaymentsProvider = StreamProvider.autoDispose.family<List<RentPayment>, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  // We trigger the generation RPC to ensure rows exist for the current view
  repo.generateRentPayments(propertyId);
  return repo.getRentPaymentsStream(propertyId);
});


final activityLogsProvider = StreamProvider.autoDispose.family<List<ActivityLog>, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getActivityLogsStream(propertyId);
});

final propertyProvider = StreamProvider.autoDispose.family<Property?, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getPropertyStream(propertyId);
});

final activeContractProvider = StreamProvider.autoDispose.family<Contract?, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getActiveContractStream(propertyId);
});

/// Real-time stream of proposed_changes for a contract.
final contractProposalProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, contractId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getContractProposalStream(contractId);
});

final propertyFinancialStatusProvider = StreamProvider.autoDispose.family<PropertyFinancialState, String>((ref, propertyId) {
  final repo = ref.watch(propertyRepositoryProvider);
  
  // Combine contract and payments streams
  return Rx.combineLatest2(
    repo.getActiveContractStream(propertyId),
    repo.getRentPaymentsStream(propertyId),
    (Contract? contract, List<RentPayment> payments) {
      // Initialize counters
      final paidTotals = <String, double>{};
      final pendingTotals = <String, double>{};
      final awaitingTotals = <String, double>{};
      int paidC = 0;
      int pendingC = 0;
      int awaitingC = 0;

      for (var p in payments) {
        final cur = p.currency;
        if (p.status == 'paid') {
          paidTotals[cur] = (paidTotals[cur] ?? 0) + p.amount;
          paidC++;
        } else if (p.status == 'declared') {
          awaitingTotals[cur] = (awaitingTotals[cur] ?? 0) + p.amount;
          awaitingC++;
        } else {
          pendingTotals[cur] = (pendingTotals[cur] ?? 0) + p.amount;
          pendingC++;
        }
      }

      final state = PropertyFinancialState(
        paidTotals: paidTotals,
        pendingTotals: pendingTotals,
        awaitingTotals: awaitingTotals,
        paidCount: paidC,
        pendingCount: pendingC,
        awaitingCount: awaitingC,
      );

      if (contract == null) {
        return PropertyFinancialState(
          generalStatus: PropertyFinancialStatus.vacant,
          paidTotals: state.paidTotals,
          pendingTotals: state.pendingTotals,
          awaitingTotals: state.awaitingTotals,
          paidCount: state.paidCount,
          pendingCount: state.pendingCount,
          awaitingCount: state.awaitingCount,
        );
      }
      if (contract.status == ContractStatus.pending) {
        return PropertyFinancialState(
          generalStatus: PropertyFinancialStatus.invitationSent,
          paidTotals: state.paidTotals,
          pendingTotals: state.pendingTotals,
          awaitingTotals: state.awaitingTotals,
          paidCount: state.paidCount,
          pendingCount: state.pendingCount,
          awaitingCount: state.awaitingCount,
        );
      }
      if (contract.status == ContractStatus.negotiating) {
        return PropertyFinancialState(
          generalStatus: PropertyFinancialStatus.negotiating,
          paidTotals: state.paidTotals,
          pendingTotals: state.pendingTotals,
          awaitingTotals: state.awaitingTotals,
          paidCount: state.paidCount,
          pendingCount: state.pendingCount,
          awaitingCount: state.awaitingCount,
        );
      }
      if (contract.status == ContractStatus.expired) {
        return PropertyFinancialState(
          generalStatus: PropertyFinancialStatus.vacant,
          paidTotals: state.paidTotals,
          pendingTotals: state.pendingTotals,
          awaitingTotals: state.awaitingTotals,
          paidCount: state.paidCount,
          pendingCount: state.pendingCount,
          awaitingCount: state.awaitingCount,
        );
      }
      if (contract.status != ContractStatus.active) {
        return PropertyFinancialState(
          generalStatus: PropertyFinancialStatus.pendingApproval,
          paidTotals: state.paidTotals,
          pendingTotals: state.pendingTotals,
          awaitingTotals: state.awaitingTotals,
          paidCount: state.paidCount,
          pendingCount: state.pendingCount,
          awaitingCount: state.awaitingCount,
        );
      }

      final now = DateTime.now();
      
      // Split payments
      final rentPayments = payments.where((p) => p.title == 'Kira').toList();
      final billPayments = payments.where((p) => p.title != 'Kira').toList();

      // Determine Rent Status
      RentStatus rentS;
      if (rentPayments.any((p) => p.status == 'pending' && !p.dueDate.isAfter(now))) {
        rentS = RentStatus.debt;
      } else if (rentPayments.any((p) => p.status == 'declared')) {
        rentS = RentStatus.awaitingApproval;
      } else {
        rentS = RentStatus.paid;
      }

      // Determine Bill Status
      BillStatus billS;
      if (billPayments.any((p) => p.status == 'pending' && !p.dueDate.isAfter(now))) {
        billS = BillStatus.debt;
      } else if (billPayments.any((p) => p.status == 'declared')) {
        billS = BillStatus.awaitingApproval;
      } else if (billPayments.any((p) => p.status == 'pending')) {
        billS = BillStatus.waitingForLandlord;
      } else {
        billS = BillStatus.paid;
      }

      return PropertyFinancialState(
        rentStatus: rentS,
        billStatus: billS,
        paidTotals: state.paidTotals,
        pendingTotals: state.pendingTotals,
        awaitingTotals: state.awaitingTotals,
        paidCount: state.paidCount,
        pendingCount: state.pendingCount,
        awaitingCount: state.awaitingCount,
      );
    },
  );
});

final pendingInvitesForUserProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final repo = ref.watch(propertyRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  
  if (user == null || user.email == null) return Stream.value([]);
  
  // Combine streams for contracts and legacy invitations
  final contractsStream = repo.getPendingContractsStreamForEmail(user.email!);
  final invitationsStream = repo.getPendingInvitationsStreamForEmail(user.email!);
  
  return Rx.combineLatest2(
    contractsStream,
    invitationsStream,
    (List<Map<String, dynamic>> contracts, List<Map<String, dynamic>> invites) {
      return [...contracts, ...invites];
    },
  );
});

final landlordSummaryProvider = StreamProvider.autoDispose<LandlordDashboardStats>((ref) {
  final propertiesAsync = ref.watch(propertiesStreamProvider);
  final repo = ref.watch(propertyRepositoryProvider);

  return propertiesAsync.when(
    data: (properties) {
      if (properties.isEmpty) return Stream.value(const LandlordDashboardStats());
      
      // We want to combine all properties' active contracts and current month payments
      // For simplicity in this redesign, we'll aggregate what we have from properties
      // and active contracts. Delays and Collected would ideally come from a specialized RPC.
      // Here we'll monitor all active contracts.
      
      return Rx.combineLatest2(
        Rx.combineLatest(properties.map((p) => repo.getActiveContractStream(p.id)), (List<Contract?> contracts) => contracts),
        Rx.combineLatest(properties.map((p) => repo.getRentPaymentsStream(p.id)), (List<List<RentPayment>> payments) => payments),
        (List<Contract?> contracts, List<List<RentPayment>> allPayments) {
          Map<String, double> expectedByCurrency = {};
          Map<String, double> collectedByCurrency = {};
          Map<String, double> overdueByCurrency = {};
          Map<String, Map<String, double>> collectedByType = {};
          int vacant = 0;
          int delays = 0;
          int awaitingApprovalCount = 0;
          String? latestAwaitingTitle;
          String? latestAwaitingPropertyId;
          
          final now = DateTime.now();
          final currentMonth = now.month;
          final currentYear = now.year;
          
          for (int i = 0; i < properties.length; i++) {
            final c = contracts[i];
            final payments = allPayments[i];
            
            if (c == null || c.status == ContractStatus.expired) {
              vacant++;
            } else {
              expectedByCurrency = CurrencyUtils.addToMap(expectedByCurrency, c.monthlyRent, c.currency);
            }

            // Calculations based on payments
            for (final p in payments) {
              // 1. Calculate Overdue
              if (p.status != 'paid' && p.dueDate.isBefore(now)) {
                overdueByCurrency = CurrencyUtils.addToMap(overdueByCurrency, p.amount, p.currency);
              }

              // 2. Awaiting Approval
              if (p.status == 'declared') {
                awaitingApprovalCount++;
                latestAwaitingTitle ??= '${properties[i].name} — ${p.title}';
                latestAwaitingPropertyId ??= properties[i].id;
              }

              // 3. Collected for this month
              if (p.status == 'paid' && 
                  p.paidAt != null && 
                  p.paidAt!.year == currentYear && 
                  p.paidAt!.month == currentMonth) {
                
                collectedByCurrency = CurrencyUtils.addToMap(collectedByCurrency, p.amount, p.currency);
                
                // Track by type
                final type = p.title;
                final typeMap = Map<String, double>.from(collectedByType[type] ?? {});
                collectedByType[type] = CurrencyUtils.addToMap(typeMap, p.amount, p.currency);
              }
            }
            
            // Count as delay
            final rentOverdue = payments.any((p) => p.title == 'Kira' && p.status == 'pending' && p.dueDate.isBefore(now));
            final billOverdue = payments.any((p) => p.title != 'Kira' && p.status == 'pending' && p.invoiceUrl != null && p.dueDate.isBefore(now));
            if (rentOverdue || billOverdue) delays++;
          }
          
          return LandlordDashboardStats(
            expectedByCurrency: expectedByCurrency,
            collectedByCurrency: collectedByCurrency,
            overdueByCurrency: overdueByCurrency,
            collectedByType: collectedByType,
            delaysCount: delays,
            vacantCount: vacant,
            totalProperties: properties.length,
            awaitingApprovalCount: awaitingApprovalCount,
            latestAwaitingTitle: latestAwaitingTitle,
            latestAwaitingPropertyId: latestAwaitingPropertyId,
          );
        },
      );
    },
    loading: () => Stream.value(const LandlordDashboardStats()),
    error: (e, _) => Stream.value(const LandlordDashboardStats()),
  );
});

final profileProvider = StreamProvider.autoDispose.family<Map<String, dynamic>?, String>((ref, userId) {
  final repo = ref.watch(propertyRepositoryProvider);
  return repo.getProfileStream(userId);
});

class PropertyRepository {
  final SupabaseClient _client;

  PropertyRepository(this._client);

  Future<List<Property>> getProperties({String? role}) async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    try {
      var query = _client.from('properties_with_names').select();
      
      if (role == 'landlord') {
        query = query.eq('landlord_id', user.id);
      } else if (role == 'tenant') {
        query = query.eq('tenant_id', user.id);
      } else {
        query = query.or('landlord_id.eq.${user.id},tenant_id.eq.${user.id}');
      }

      final response = await query.order('created_at');
      
      print('DEBUG [Future]: Data received: $response');
      final data = response as List;
      final properties = data.map((json) => Property.fromJson(json as Map<String, dynamic>)).toList();
      
      // Deduplicate by ID
      final seen = <String>{};
      return properties.where((p) => seen.add(p.id)).toList();
    } catch (e) {
      print('DEBUG [Future] Error: $e');
      rethrow;
    }
  }

  Stream<Property?> getPropertyStream(String id) {
    return _client
        .from('properties')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .map((rows) => rows.isEmpty ? null : Property.fromJson(rows.first));
  }

  Stream<List<Property>> getPropertiesStream({required String userId, String? role}) {
    if (role != null) {
      print('DEBUG [Stream]: Filtered stream started for user $userId (role: $role)');
    } else {
      print('DEBUG [Stream]: Inclusive stream started for user $userId');
    }

    final query = _client.from('properties').stream(primaryKey: ['id']);
    
    // Apply filters based on role
    final filteredQuery = (role == 'landlord') 
        ? query.eq('landlord_id', userId)
        : (role == 'tenant') 
            ? query.eq('tenant_id', userId)
            : query;

    return filteredQuery
        .order('created_at')
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .map((data) {
      try {
        final properties = data.map((json) => Property.fromJson(json as Map<String, dynamic>)).toList();
        
        // Deduplicate by ID to prevent transient UI glitches during inserts/updates
        final seen = <String>{};
        return properties.where((p) => seen.add(p.id)).toList();
      } catch (e) {
        print('DEBUG: Property Mapping Error: $e');
        throw Exception('Data mapping error: $e');
      }
    });
  }

  Stream<Map<String, dynamic>?> getProfileStream(String userId) {
    return _client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((rows) => rows.isEmpty ? null : rows.first);
  }

  Future<void> createProperty({
    required String address,
    required String name,
    required double defaultMonthlyRent,
    double? defaultDepositAmount,
    required String currency,
    required String defaultDepositCurrency,
    int defaultDueDay = 1,
    TaxType taxType = TaxType.included,
    required List<ExpenseItem> expensesTemplate,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _client.from('properties').insert({
      'address': address,
      'name': name,
      'default_monthly_rent': defaultMonthlyRent,
      'default_deposit_amount': defaultDepositAmount,
      'currency': currency,
      'default_deposit_currency': defaultDepositCurrency,
      'landlord_id': user.id,
      'default_due_day': defaultDueDay,
      'tax_type': taxType.name,
      'expenses_template': expensesTemplate.map((e) => e.toJson()).toList(),
    });
  }

  Future<void> updateProperty(Property property) async {
    await _client.from('properties').update({
      'address': property.address,
      'name': property.name,
      'default_monthly_rent': property.defaultMonthlyRent,
      'default_deposit_amount': property.defaultDepositAmount,
      'currency': property.currency,
      'default_deposit_currency': property.defaultDepositCurrency,
      'default_due_day': property.defaultDueDay,
      'tax_type': property.taxType.name,
      'expenses_template': property.expensesTemplate.map((e) => e.toJson()).toList(),
    }).eq('id', property.id);
  }

  Future<String> uploadContract(String fileName, {String? filePath, Uint8List? bytes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Sanitize filename: remove weird characters and provide fallback
    String cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '').trim();
    if (cleanFileName.isEmpty) cleanFileName = 'contract';
    
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
    
    // Determine content type from extension for better storage handling
    String contentType = 'application/octet-stream';
    if (cleanFileName.toLowerCase().endsWith('.pdf')) contentType = 'application/pdf';
    else if (cleanFileName.toLowerCase().endsWith('.jpg') || cleanFileName.toLowerCase().endsWith('.jpeg')) contentType = 'image/jpeg';
    else if (cleanFileName.toLowerCase().endsWith('.png')) contentType = 'image/png';

    if (bytes != null) {
      // Use uploadBinary which is specifically for raw bytes on Web/Native
      await _client.storage.from('contracts').uploadBinary(
        path, 
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      );
    } else if (filePath != null) {
      await _client.storage.from('contracts').upload(
        path, 
        io.File(filePath),
        fileOptions: FileOptions(contentType: contentType),
      );
    } else {
      throw Exception('Missing file data (either path or bytes must be provided)');
    }

    return _client.storage.from('contracts').getPublicUrl(path);
  }

  Future<String> uploadReceipt(String fileName, {String? filePath, Uint8List? bytes}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    String cleanFileName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9.\-_]'), '').trim();
    if (cleanFileName.isEmpty) cleanFileName = 'receipt';
    
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$cleanFileName';
    
    String contentType = 'application/octet-stream';
    if (cleanFileName.toLowerCase().endsWith('.pdf')) contentType = 'application/pdf';
    else if (cleanFileName.toLowerCase().endsWith('.jpg') || cleanFileName.toLowerCase().endsWith('.jpeg')) contentType = 'image/jpeg';
    else if (cleanFileName.toLowerCase().endsWith('.png')) contentType = 'image/png';

    if (bytes != null) {
      await _client.storage.from('receipts').uploadBinary(
        path, 
        bytes,
        fileOptions: FileOptions(contentType: contentType),
      );
    } else if (filePath != null) {
      await _client.storage.from('receipts').upload(
        path, 
        io.File(filePath),
        fileOptions: FileOptions(contentType: contentType),
      );
    } else {
      throw Exception('Missing file data');
    }

    return _client.storage.from('receipts').getPublicUrl(path);
  }

  Future<void> deleteProperty(String id) async {
    await _client.from('properties').delete().eq('id', id);
  }



  Stream<List<Contract>> getPropertyContractsStream(String propertyId) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('created_at')
        .map((data) {
      return data.map((json) => Contract.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  Future<void> cancelInvite(String id) async {
    // 1. Get property ID first (mandatory legacy info)
    final contractData = await _client.from('contracts').select('property_id').eq('id', id).maybeSingle();
    final propertyId = contractData?['property_id'];

    // 2. Perform deletions and property reset in parallel for speed
    await Future.wait([
      // Delete from invitations
      _client.from('invitations').delete().eq('id', id),
      // Delete from contracts
      _client.from('contracts').delete().eq('id', id).inFilter('status', ['pending', 'negotiating']),
      // Reset property to Vacant state if we have the ID
      if (propertyId != null)
        _client.from('properties').update({
          'tenant_id': null,
        }).eq('id', propertyId),
    ]);
  }

  Future<Map<String, dynamic>> getInviteByToken(String token) async {
    try {
      // Try invitations first
      final inviteResponse = await _client
          .from('invitations')
          .select('*, properties(*)')
          .eq('token', token)
          .maybeSingle();
      
      if (inviteResponse != null) {
        // If it's a secondary invite, we also want to attach the ACTIVE contract terms if available
        final activeContract = await getActiveContract(inviteResponse['property_id']);
        return {
          ...inviteResponse,
          'type': 'invitation',
          'active_contract': activeContract?.toJson(),
        };
      }

      // Try contracts
      final contractResponse = await _client
          .from('contracts')
          .select('*, properties(*)')
          .eq('token', token)
          .maybeSingle();

      if (contractResponse != null) {
        return {
          ...contractResponse,
          'type': 'contract',
        };
      }

      throw Exception('Invitation not found');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> acceptInvite(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      print('DEBUG: Calling accept_invitation RPC with token $token');

      // Find property_id from token before it's deleted/consumed
      final invite = await _client.from('invitations').select('property_id').eq('token', token).maybeSingle();

      // Call the secure database function
      await _client.rpc('accept_invitation', params: {
        'invite_token': token,
      });
      
      if (invite != null) {
        final propertyId = invite['property_id'] as String;
        final landlordId = await _getLandlordId(propertyId);
        await _createNotification(
          userId: landlordId,
          title: 'Invitation Accepted',
          body: 'A tenant has accepted the invitation for your property.',
          type: 'contract',
          relatedId: propertyId,
        );
      }

      print('DEBUG: Successfully accepted invitation via RPC');
    } catch (e) {
      print('DEBUG ERROR [acceptInvite]: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingInvitationsForEmail(String email) async {
    final response = await _client
        .from('invitations')
        .select('*, properties(*)')
        .eq('invitee_email', email)
        .eq('status', 'pending');
    
    final list = response as List;
    return list.map((item) => {
      ...item as Map<String, dynamic>,
      'type': 'invitation',
    }).toList();
  }

  Future<void> declineInvite(String token) async {
    await _client.from('contracts').update({
      'status': 'declined',
    }).eq('token', token);
  }

  // Contract Methods

  Future<Contract> createContract({
    required String propertyId,
    required String inviteeEmail,
    required double monthlyRent,
    double? depositAmount,
    required String currency,
    required String depositCurrency,
    required int dueDay,
    required DateTime startDate,
    required DateTime endDate,
    TaxType taxType = TaxType.included,
    required List<ExpenseItem> expensesConfig,
    String? inviterName,
    String? contractUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = DateTime.now().millisecondsSinceEpoch.toString(); 

    final data = await _client.from('contracts').insert({
      'property_id': propertyId,
      'landlord_id': user.id,
      'inviter_name': inviterName,
      'invitee_email': inviteeEmail.trim().toLowerCase(),
      'monthly_rent': monthlyRent,
      'deposit_amount': depositAmount,
      'currency': currency,
      'deposit_currency': depositCurrency,
      'due_day': dueDay,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'tax_type': taxType.name,
      'expenses_config': expensesConfig.map((e) => e.toJson()).toList(),
      'contract_url': contractUrl,
      'token': token,
      'status': 'pending',
    }).select().single();

    final contract = Contract.fromJson(data);

    // Try to notify the tenant if they are already registered
    try {
      final inviteeProfile = await _client
          .from('profiles')
          .select('id')
          .eq('email', inviteeEmail.trim().toLowerCase())
          .maybeSingle();
      
      if (inviteeProfile != null) {
        final property = await _client
            .from('properties')
            .select('name')
            .eq('id', propertyId)
            .single();
            
        await _createNotification(
          userId: inviteeProfile['id'] as String,
          title: 'New Contract Invitation',
          body: 'You have received a new contract invitation for ${property['name']}.',
          type: 'contract',
          relatedId: propertyId,
        );
      }
    } catch (e) {
      print('DEBUG: Silent notification failure: $e');
    }

    return contract;
  }

  Future<String> createInvitation({
    required String propertyId,
    required String inviteeEmail,
    String? inviterName,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final token = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _client.from('invitations').insert({
      'property_id': propertyId,
      'inviter_id': user.id,
      'inviter_name': inviterName ?? 'Landlord',
      'invitee_email': inviteeEmail.trim().toLowerCase(),
      'token': token,
      'status': 'pending',
      'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    });

    return token;
  }

  Future<Contract> getContractByToken(String token) async {
    final response = await _client
        .from('contracts')
        .select('*, properties(*)')
        .eq('token', token)
        .single();
    
    return Contract.fromJson(response);
  }

  Future<void> proposeRevision(String token, String feedback) async {
    final contractResponse = await _client.from('contracts').select().eq('token', token).single();
    final contract = Contract.fromJson(contractResponse);
    
    await _client.from('contracts').update({
      'status': 'negotiating',
      'tenant_feedback': feedback,
    }).eq('token', token);

    // Notify landlord
    await _createNotification(
      userId: contract.landlordId,
      title: 'Contract Revision',
      body: 'The tenant has requested a revision to the contract terms.',
      type: 'contract',
      relatedId: contract.propertyId,
    );
  }

  Future<void> updateContractTerms(String contractId, {
    double? monthlyRent,
    double? depositAmount,
    String? depositCurrency,
    int? dueDay,
    DateTime? startDate,
    DateTime? endDate,
    TaxType? taxType,
    List<ExpenseItem>? expensesConfig,
    String? contractUrl,
  }) async {
    final updateData = <String, dynamic>{
      'status': 'pending', // Re-send as pending
      'tenant_feedback': null, // Clear feedback
    };
    
    if (monthlyRent != null) updateData['monthly_rent'] = monthlyRent;
    if (depositAmount != null) updateData['deposit_amount'] = depositAmount;
    if (depositCurrency != null) updateData['deposit_currency'] = depositCurrency;
    if (dueDay != null) updateData['due_day'] = dueDay;
    if (startDate != null) updateData['start_date'] = startDate.toIso8601String();
    if (endDate != null) updateData['end_date'] = endDate.toIso8601String();
    if (taxType != null) updateData['tax_type'] = taxType.name;
    if (expensesConfig != null) updateData['expenses_config'] = expensesConfig.map((e) => e.toJson()).toList();
    if (contractUrl != null) updateData['contract_url'] = contractUrl;

    await _client.from('contracts').update(updateData).eq('id', contractId);

    // Notify tenant/invitee
    final contractData = await _client.from('contracts').select().eq('id', contractId).single();
    final targetUserId = await _getCounterpartyId(contractData);
    
    if (targetUserId != null) {
      await _createNotification(
        userId: targetUserId,
        title: 'New Contract Terms',
        body: 'The landlord has sent updated terms for your invitation. Tap to review.',
        type: 'contract',
        relatedId: contractData['property_id'],
      );
    }
  }

  Future<void> acceptContract(String token) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    try {
      await _client.rpc('accept_contract', params: {
        'contract_token': token,
      });
    } catch (e) {
      print('DEBUG ERROR [acceptContract]: $e');
      rethrow;
    }
  }

  Future<List<Contract>> getContractsForProperty(String propertyId) async {
    final response = await _client
        .from('contracts')
        .select()
        .eq('property_id', propertyId)
        .order('created_at');
    
    return (response as List).map((json) => Contract.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Real-time stream of the active (or revision_requested) contract for a property.
  /// Uses Supabase realtime so all connected clients receive push updates.
  Stream<Contract?> getActiveContractStream(String propertyId) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .map((rows) {
          final relevant = rows.where((r) {
            final status = r['status'] as String?;
            return status == 'active' || status == 'revision_requested' || status == 'termination_requested' || status == 'inactive' || status == 'pending' || status == 'negotiating';
          }).toList();
          if (relevant.isEmpty) return null;
          relevant.sort((a, b) {
            final aTime = a['updated_at'] as String? ?? '';
            final bTime = b['updated_at'] as String? ?? '';
            return bTime.compareTo(aTime);
          });
          return Contract.fromJson(relevant.first as Map<String, dynamic>);
        });
  }

  /// Internal one-shot fetch (kept for use inside repository methods).
  Future<Contract?> getActiveContract(String propertyId) async {
    final response = await _client
        .from('contracts')
        .select()
        .eq('property_id', propertyId)
        .filter('status', 'in', '(active,revision_requested,termination_requested,inactive,pending,negotiating)')
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (response == null) return null;
    return Contract.fromJson(response);
  }

  /// Real-time stream of proposed_changes for a specific contract.
  Stream<Map<String, dynamic>?> getContractProposalStream(String contractId) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('id', contractId)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .map((rows) {
          if (rows.isEmpty) return null;
          final changes = rows.first['proposed_changes'] as Map<String, dynamic>?;
          if (changes == null) return null;
          return {
            'changes': changes,
            'proposed_by': rows.first['proposed_by'],
          };
        });
  }

  /// Landlord proposes a contract change. Stores in proposed_changes; sets status revision_requested.
  Future<void> proposeContractChanges(String contractId, Map<String, dynamic> changes) async {
    await _client.rpc('propose_contract_changes', params: {
      'p_contract_id': contractId,
      'p_changes': changes,
    });

    // Notify other party
    final contractData = await _client.from('contracts').select().eq('id', contractId).single();
    final user = _client.auth.currentUser;
    if (user != null) {
      final targetUserId = await _getCounterpartyId(contractData);
      final isLandlord = user.id == contractData['landlord_id'];
      final roleName = isLandlord ? 'Landlord' : 'Tenant';

      if (targetUserId != null) {
        final isInvitationUpdate = contractData['status'] == 'pending';
        // Use token as relatedId for tenants to ensure they can open the invitation screen
        final relatedId = (targetUserId == contractData['tenant_id']) 
            ? contractData['token'] 
            : contractData['property_id'];

        await _createNotification(
          userId: targetUserId,
          title: isInvitationUpdate ? 'New Contract Terms' : 'Contract Revision',
          body: isInvitationUpdate 
            ? 'The $roleName has sent updated terms for your invitation. Tap to review.'
            : '$roleName has proposed new changes to the contract terms.',
          type: 'contract',
          relatedId: contractData['property_id'],
        );
      }
    }
  }

  /// Propose early contract termination. Stores in proposed_changes; sets status termination_requested.
  Future<void> requestContractTermination(String contractId, DateTime terminationDate) async {
    await _client.rpc('propose_contract_termination', params: {
      'p_contract_id': contractId,
      'p_termination_date': terminationDate.toIso8601String(),
    });

    // Notify other party
    final contractData = await _client.from('contracts').select().eq('id', contractId).single();
    final user = _client.auth.currentUser;
    if (user != null) {
      final targetUserId = user.id == contractData['landlord_id'] ? contractData['tenant_id'] : contractData['landlord_id'];
      if (targetUserId != null) {
        final relatedId = (targetUserId == contractData['tenant_id']) 
            ? contractData['token'] 
            : contractData['property_id'];

        await _createNotification(
          userId: targetUserId,
          title: 'Contract Termination Requested',
          body: 'A request has been made to end the contract early.',
          type: 'contract',
          relatedId: contractData['property_id'],
        );
      }
    }
  }

  /// Tenant accepts proposed changes. Applies them to contract fields; clears proposal; sets active.
  Future<void> acceptProposedChanges(String contractId) async {
    await _client.rpc('accept_proposed_changes', params: {
      'p_contract_id': contractId,
    });

    // Notify other party
    final contractData = await _client.from('contracts').select().eq('id', contractId).single();
    final user = _client.auth.currentUser;
    if (user != null) {
      final targetUserId = user.id == contractData['landlord_id'] ? contractData['tenant_id'] : contractData['landlord_id'];
      if (targetUserId != null) {
        final relatedId = (targetUserId == contractData['tenant_id']) 
            ? contractData['token'] 
            : contractData['property_id'];

        await _createNotification(
          userId: targetUserId,
          title: 'Contract Changes Accepted',
          body: 'The proposed contract changes have been accepted.',
          type: 'contract',
          relatedId: contractData['property_id'],
        );
      }
    }
  }

  /// Tenant declines proposed changes. Clears proposal; reverts status to active (terms unchanged).
  Future<void> declineProposedChanges(String contractId) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    // Fetch before RPC to know who proposed
    final contractBefore = await _client.from('contracts').select().eq('id', contractId).single();
    final wasProposedByMe = contractBefore['proposed_by'] == user.id;

    await _client.rpc('decline_proposed_changes', params: {
      'p_contract_id': contractId,
    });

    // Notify other party
    final targetUserId = await _getCounterpartyId(contractBefore);

    if (targetUserId != null) {
      final isLandlord = user.id == contractBefore['landlord_id'];
      final roleName = isLandlord ? 'Landlord' : 'Tenant';
      
      final relatedId = (targetUserId == contractBefore['tenant_id']) 
          ? contractBefore['token'] 
          : contractBefore['property_id'];

      await _createNotification(
        userId: targetUserId,
        title: wasProposedByMe ? 'Revision Cancelled' : 'Revision Declined',
        body: wasProposedByMe
          ? '$roleName has withdrawn their proposed contract changes.'
          : '$roleName has declined the proposed contract changes.',
        type: 'contract',
        relatedId: contractBefore['property_id'],
      );
    }
  }

  Stream<List<Map<String, dynamic>>> getPendingContractsStreamForEmail(String email) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('invitee_email', email.trim().toLowerCase())
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .asyncMap((rows) async {
          final pendingRows = rows
              .where((r) {
                final status = r['status'] as String?;
                // 'revision_requested' with a tenant_id means the landlord proposed changes
                // on an ACTIVE contract. The tenant sees this via Property Detail screen,
                // NOT as a new invitation card on the dashboard.
                if (status == 'revision_requested' && r['tenant_id'] != null) {
                  return false;
                }
                return status == 'pending' || status == 'negotiating' || status == 'revision_requested';
              })
              .toList();
              
          if (pendingRows.isEmpty) return [];

          final propertyIds = pendingRows.map((r) => r['property_id'] as String).toSet().toList();
          final propsResponse = await _client.from('properties').select().inFilter('id', propertyIds);
          final propsMap = {for (var p in propsResponse) p['id'] as String: p};

          return pendingRows.map((item) => {
            ...item,
            'type': 'contract',
            'properties': propsMap[item['property_id']],
          }).toList();
        });
  }

  Stream<List<Map<String, dynamic>>> getPendingInvitationsStreamForEmail(String email) {
    return _client
        .from('invitations')
        .stream(primaryKey: ['id'])
        .eq('invitee_email', email.trim().toLowerCase())
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .asyncMap((rows) async {
          final pendingRows = rows
              .where((r) => r['status'] == 'pending')
              .toList();
              
          if (pendingRows.isEmpty) return [];

          final propertyIds = pendingRows.map((r) => r['property_id'] as String).toSet().toList();
          final propsResponse = await _client.from('properties').select().inFilter('id', propertyIds);
          final propsMap = {for (var p in propsResponse) p['id'] as String: p};

          return pendingRows.map((item) => {
            ...item,
            'type': 'invitation',
            'properties': propsMap[item['property_id']],
          }).toList();
        });
  }

  Future<void> removeTenant(String propertyId, String inviteId) async {
    // We use a secure RPC to handle this atomically and bypass client-side RLS for deletions
    await _client.rpc('leave_property', params: {
      'p_property_id': propertyId,
      'p_invite_id': inviteId,
    });
  }

  Future<void> generateRentPayments(String propertyId) async {
    try {
      await _client.rpc('generate_missing_rent_payments', params: {
        'p_property_id': propertyId,
      });
    } catch (e) {
      print('DEBUG ERROR [generateRentPayments]: $e');
    }
  }

  Stream<List<RentPayment>> getRentPaymentsStream(String propertyId) {
    return _client
        .from('rent_payments')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('due_date', ascending: false)
        .map((data) {
      // Map to domain objects
      final list = (data as List).map((json) => RentPayment.fromJson(json as Map<String, dynamic>)).toList();
      
      // Perform STABLE sort in Dart: due_date desc, created_at asc, id asc
      list.sort((a, b) {
        // Primary: due_date desc
        int cmp = b.dueDate.compareTo(a.dueDate);
        if (cmp != 0) return cmp;
        
        // Secondary: created_at asc
        if (a.createdAt != null && b.createdAt != null) {
          cmp = a.createdAt!.compareTo(b.createdAt!);
          if (cmp != 0) return cmp;
        }
        
        // Tertiary: id asc (for absolute stability)
        return a.id.compareTo(b.id);
      });
      
      return list;
    });
  }

  Future<void> declareRentAsPaid(String paymentId, String propertyId, String monthName, DateTime dueDate, {String? receiptUrl, String? note}) async {
    await _client.from('rent_payments').update({
      'status': 'declared',
      'declared_at': DateTime.now().toIso8601String(),
      'receipt_url': receiptUrl,
      'owner_note': note,
    }).eq('id', paymentId);

    await _logActivity(propertyId, 'rent_declared', {
      'month': monthName,
      'due_date': dueDate.toIso8601String(),
      'has_receipt': receiptUrl != null,
      'is_cash': receiptUrl == 'CASH',
    });

    final landlordId = await _getLandlordId(propertyId);
    await _createNotification(
      userId: landlordId,
      title: 'Rent Declared',
      body: 'Tenant has declared rent as paid for $monthName${receiptUrl == 'CASH' ? ' (Cash)' : ''}',
      type: 'rent',
      relatedId: propertyId,
    );
  }

  Future<void> approveRentPayment(String paymentId, String propertyId, String monthName, DateTime dueDate) async {
    await _client.from('rent_payments').update({
      'status': 'paid',
      'paid_at': DateTime.now().toIso8601String(),
      'dispute_reason': null,
      'disputed_at': null,
    }).eq('id', paymentId);

    await _logActivity(propertyId, 'rent_approved', {
      'month': monthName,
      'due_date': dueDate.toIso8601String(),
    });

    final tenantId = await _getTenantId(propertyId);
    if (tenantId != null) {
      await _createNotification(
        userId: tenantId,
        title: 'Rent Approved',
        body: 'Landlord has approved your rent payment for $monthName',
        type: 'rent',
        relatedId: propertyId,
      );
    }
  }

  Future<void> rejectRentPayment(String paymentId, String propertyId, String monthName, DateTime dueDate) async {
    await _client.from('rent_payments').update({
      'status': 'pending',
      'declared_at': null,
      'paid_at': null,
      'dispute_reason': null,
      'disputed_at': null,
    }).eq('id', paymentId);

    await _logActivity(propertyId, 'rent_rejected', {
      'month': monthName,
      'due_date': dueDate.toIso8601String(),
    });

    final tenantId = await _getTenantId(propertyId);
    if (tenantId != null) {
      await _createNotification(
        userId: tenantId,
        title: 'Rent Payment Rejected',
        body: 'Landlord has rejected your rent declaration for $monthName. Please check the details.',
        type: 'rent',
        relatedId: propertyId,
      );
    }
  }

  Future<void> disputeRentPayment(String paymentId, String propertyId, String reason) async {
    await _client.from('rent_payments').update({
      'status': 'disputed',
      'dispute_reason': reason,
      'disputed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);

    await _logActivity(propertyId, 'rent_disputed', {
      'payment_id': paymentId,
      'reason': reason,
    });

    final landlordId = await _getLandlordId(propertyId);
    await _createNotification(
      userId: landlordId,
      title: 'Payment Disputed',
      body: 'Tenant has objected to a charge. Reason: $reason',
      type: 'rent',
      relatedId: propertyId,
    );
  }

  Future<void> setPaymentInvoice(String paymentId, String propertyId, String monthName, DateTime dueDate, double amount, String? invoiceUrl, {String currency = 'RSD', String? ownerNote}) async {
    final isZero = amount == 0;
    await _client.from('rent_payments').update({
      'amount': amount,
      'currency': currency,
      'invoice_url': invoiceUrl,
      'status': isZero ? 'paid' : 'pending',
      'paid_at': isZero ? DateTime.now().toIso8601String() : null,
      'dispute_reason': null,
      'disputed_at': null,
      'owner_note': ownerNote,
    }).eq('id', paymentId);

    await _logActivity(propertyId, 'invoice_uploaded', {
      'month': monthName,
      'amount': amount,
      'currency': currency,
      'due_date': dueDate.toIso8601String(),
    });

    final tenantId = await _getTenantId(propertyId);
    if (tenantId != null) {
      await _createNotification(
        userId: tenantId,
        title: isZero ? 'Month Settled (0 Cost)' : 'New Bill Entered',
        body: isZero ? 'The costs for $monthName have been settled as 0.' : 'A new bill has been entered for $monthName. Amount: $amount $currency',
        type: 'rent',
        relatedId: propertyId,
      );
    }
  }


  Future<void> uploadContractDocument(String contractId, String name, List<int> fileBytes, String extension) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '${user.id}/additional_docs/$contractId/$fileName';

    await _client.storage.from('contracts').uploadBinary(path, Uint8List.fromList(fileBytes));
    final publicUrl = _client.storage.from('contracts').getPublicUrl(path);

    // Get current documents
    final data = await _client.from('contracts').select('additional_documents').eq('id', contractId).single();
    final List<dynamic> currentDocs = data['additional_documents'] ?? [];
    
    final newDoc = {
      'name': name,
      'url': publicUrl,
      'created_at': DateTime.now().toIso8601String(),
    };

    currentDocs.add(newDoc);

    await _client.from('contracts').update({
      'additional_documents': currentDocs,
    }).eq('id', contractId);
  }

  Future<void> deleteContractDocument(String contractId, ContractDocument doc) async {
    try {
      final uri = Uri.parse(doc.url);
      final pathParts = uri.pathSegments;
      final contractsIdx = pathParts.indexOf('contracts');
      if (contractsIdx != -1 && contractsIdx + 1 < pathParts.length) {
        final storagePath = pathParts.skip(contractsIdx + 1).join('/');
        await _client.storage.from('contracts').remove([storagePath]);
      }
    } catch (_) {}

    final data = await _client.from('contracts').select('additional_documents').eq('id', contractId).single();
    final List<dynamic> currentDocs = data['additional_documents'] ?? [];
    
    currentDocs.removeWhere((d) => d['url'] == doc.url);

    await _client.from('contracts').update({
      'additional_documents': currentDocs,
    }).eq('id', contractId);
  }

  Future<void> updateMainContract(String contractId, List<int> fileBytes, String extension) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final fileName = 'main_contract_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final path = '${user.id}/contracts/$contractId/$fileName';

    await _client.storage.from('contracts').uploadBinary(path, Uint8List.fromList(fileBytes));
    final publicUrl = _client.storage.from('contracts').getPublicUrl(path);

    await _client.from('contracts').update({
      'contract_url': publicUrl,
    }).eq('id', contractId);
  }

  Stream<List<ActivityLog>> getActivityLogsStream(String propertyId) {
    return _client
        .from('activity_logs')
        .stream(primaryKey: ['id'])
        .eq('property_id', propertyId)
        .order('created_at', ascending: false)
        .cast<dynamic>()
        .map((data) => (data as List).map((json) => json as Map<String, dynamic>).toList())
        .map((data) {
      return data.map((json) => ActivityLog.fromJson(json as Map<String, dynamic>)).toList();
    });
  }

  Future<void> _logActivity(String propertyId, String type, Map<String, dynamic> metadata) async {
    final user = _client.auth.currentUser;
    await _client.from('activity_logs').insert({
      'property_id': propertyId,
      'user_id': user?.id,
      'type': type,
      'metadata': metadata,
    });
  }

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? relatedId,
  }) async {
    final currentUser = _client.auth.currentUser;
    if (currentUser?.id == userId) return;

    await _client.from('notifications').insert({
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'related_id': relatedId,
    });
  }

  Future<String> _getLandlordId(String propertyId) async {
    final data = await _client.from('properties').select('landlord_id').eq('id', propertyId).single();
    return data['landlord_id'] as String;
  }

  Future<String?> _getTenantId(String propertyId) async {
    final data = await _client.from('properties').select('tenant_id').eq('id', propertyId).single();
    return data['tenant_id'] as String?;
  }

  Future<String?> _getCounterpartyId(Map<String, dynamic> contractData) async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    String? targetUserId = user.id == contractData['landlord_id'] ? contractData['tenant_id'] : contractData['landlord_id'];

    if (targetUserId == null && contractData['invitee_email'] != null) {
      try {
        final profileData = await _client.from('profiles').select('id').eq('email', contractData['invitee_email']).maybeSingle();
        if (profileData != null) {
          targetUserId = profileData['id'] as String;
        }
      } catch (e) {
        print('DEBUG: Could not find profile for invitee_email: ${contractData['invitee_email']}');
      }
    }
    
    return targetUserId;
  }
}
