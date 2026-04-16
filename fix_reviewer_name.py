import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

overview_regex = r"""            final resolvedLandlordName = landlordProfileAsync.value\?\['full_name'\] \?\? liveProperty.landlordName \?\? activeContract\?.inviterName \?\? 'Landlord';
            final resolvedTenantName = tenantProfileAsync.value\?\['full_name'\] \?\? liveProperty.tenantName \?\? activeContract\?.inviteeEmail \?\? 'Tenant';"""
overview_replace = """            final resolvedLandlordName = landlordProfileAsync.value?['full_name'] ?? liveProperty.landlordName ?? activeContract?.inviterName ?? 'Landlord';
            final resolvedTenantName = tenantProfileAsync.value?['full_name'] ?? liveProperty.tenantName ?? activeContract?.inviteeEmail ?? 'Tenant';
            final resolvedLandlordEmail = landlordProfileAsync.value?['email'] ?? '';
            final resolvedTenantEmail = tenantProfileAsync.value?['email'] ?? activeContract?.inviteeEmail ?? '';"""

content = re.sub(overview_regex, overview_replace, content)

card_inv_regex = r"""                  _ProposalReviewCard\(
                    contract: activeContract,
                    isTenant: effectiveIsTenant,
                    isLandlord: effectiveIsLandlord,
                    isTr: isTr,
                    propertyId: liveProperty.id,
                  \),"""
card_inv_replace = """                  _ProposalReviewCard(
                    contract: activeContract,
                    isTenant: effectiveIsTenant,
                    isLandlord: effectiveIsLandlord,
                    isTr: isTr,
                    propertyId: liveProperty.id,
                    landlordName: resolvedLandlordName,
                    tenantName: resolvedTenantName,
                    landlordEmail: resolvedLandlordEmail,
                    tenantEmail: resolvedTenantEmail,
                  ),"""

content = re.sub(card_inv_regex, card_inv_replace, content)

class_def_regex = r"""class _ProposalReviewCard extends ConsumerStatefulWidget \{
  final Contract contract;
  final bool isTenant;
  final bool isLandlord;
  final bool isTr;
  final String propertyId;
  const _ProposalReviewCard\(\{
    required this.contract,
    required this.isTenant,
    required this.isLandlord,
    required this.isTr,
    required this.propertyId,
  \}\);"""
class_def_replace = """class _ProposalReviewCard extends ConsumerStatefulWidget {
  final Contract contract;
  final bool isTenant;
  final bool isLandlord;
  final bool isTr;
  final String propertyId;
  final String landlordName;
  final String tenantName;
  final String landlordEmail;
  final String tenantEmail;

  const _ProposalReviewCard({
    required this.contract,
    required this.isTenant,
    required this.isLandlord,
    required this.isTr,
    required this.propertyId,
    required this.landlordName,
    required this.tenantName,
    required this.landlordEmail,
    required this.tenantEmail,
  });"""

content = re.sub(class_def_regex, class_def_replace, content)


build_msg_regex = r"""                  Text\(
                    isTr \? 'Karşı taraf aşağıdaki değişiklikleri teklif ediyor:' : 'The other party proposes the following changes:',
                    style: const TextStyle\(fontSize: 13, color: StanomerColors.textSecondary\),
                  \),"""
build_msg_replace = """                  Builder(builder: (context) {
                    String proposerName = '';
                    String proposerEmail = '';
                    if (proposedBy == widget.contract.landlordId) {
                      proposerName = widget.landlordName;
                      proposerEmail = widget.landlordEmail;
                    } else if (proposedBy == widget.contract.tenantId) {
                      proposerName = widget.tenantName;
                      proposerEmail = widget.tenantEmail;
                    }
                    
                    final emailText = proposerEmail.isNotEmpty ? ' ($proposerEmail)' : '';
                    return Text(
                      isTr ? '$proposerName$emailText aşağıdaki değişiklikleri teklif ediyor:' : '$proposerName$emailText proposes the following changes:',
                      style: const TextStyle(fontSize: 13, color: StanomerColors.textSecondary, fontWeight: FontWeight.w600),
                    );
                  }),"""

content = re.sub(build_msg_regex, build_msg_replace, content)

with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

