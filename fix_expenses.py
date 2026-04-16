import re

with open('lib/features/property/presentation/property_detail_screen.dart', 'r') as f:
    content = f.read()

# Replace _formatExpenses method inside _ProposalReviewCardState
format_regex = r"""  String _formatExpenses\(dynamic expenses, bool isTr\) \{
    if \(expenses == null\) return '-';
    List expList;
    if \(expenses is List\) \{
      expList = expenses;
    \} else \{
      return '-';
    \}
    if \(expList.isEmpty\) return '-';

    return expList.map\(\(e\) \{
      if \(e is Map\) \{
        final name = e\['name'\] as String\? \?\? 'Bilinmeyen';
        final receiver = e\['receiver'\] as String\?;
        final recText = receiver == 'owner' \? \(isTr \? 'Ev Sahibi' : 'Landlord'\) 
                      : receiver == 'utility' \? \(isTr \? 'Kullanıcı' : 'Utility'\) 
                      : \(isTr \? 'Dahil' : 'Included'\);
        return '\$name \(\$recText\)';
      \} else \{
        // e is ExpenseItem type
        final dynamic item = e;
        try \{
          final recText = item.receiver.toString\(\).contains\('owner'\) \? \(isTr \? 'Ev Sahibi' : 'Landlord'\) 
                        : item.receiver.toString\(\).contains\('utility'\) \? \(isTr \? 'Kullanıcı' : 'Utility'\) 
                        : \(isTr \? 'Dahil' : 'Included'\);
          return '\$\{item.name\} \(\$recText\)';
        \} catch \(\_\) \{
          return '';
        \}
      \}
    \}\).join\(', '\);
  \}"""

format_replace = """  String _formatExpenses(dynamic expenses, bool isTr) {
    if (expenses == null) return '-';
    List expList;
    if (expenses is List) {
      expList = expenses;
    } else {
      return '-';
    }
    if (expList.isEmpty) return '-';

    return expList.map((e) {
      if (e is Map) {
        final name = e['name'] as String? ?? 'Bilinmeyen';
        final receiver = e['receiver'] as String?;
        final recText = receiver == 'owner' ? (isTr ? 'Kiracı ev sahibine öder' : 'Tenant pays landlord') 
                      : receiver == 'utility' ? (isTr ? 'Kiracı kuruma öder' : 'Tenant pays utility') 
                      : (isTr ? 'Kiraya dahil' : 'Included in rent');
        return '$name ($recText)';
      } else {
        // e is ExpenseItem type
        final dynamic item = e;
        try {
          final recText = item.receiver.toString().contains('owner') ? (isTr ? 'Kiracı ev sahibine öder' : 'Tenant pays landlord') 
                        : item.receiver.toString().contains('utility') ? (isTr ? 'Kiracı kuruma öder' : 'Tenant pays utility') 
                        : (isTr ? 'Kiraya dahil' : 'Included in rent');
          return '${item.name} ($recText)';
        } catch (_) {
          return '';
        }
      }
    }).join(', ');
  }"""

content = re.sub(format_regex, format_replace, content, 1)


with open('lib/features/property/presentation/property_detail_screen.dart', 'w') as f:
    f.write(content)

