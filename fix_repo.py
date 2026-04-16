import re

with open('lib/features/property/data/property_repository.dart', 'r') as f:
    content = f.read()

repo_regex = r"""  Stream<Map<String, dynamic>\?> getContractProposalStream\(String contractId\) \{
    return _client
        .from\('contracts'\)
        .stream\(primaryKey: \['id'\]\)
        .eq\('id', contractId\)
        .map\(\(rows\) \{
          if \(rows.isEmpty\) return null;
          return rows.first\['proposed_changes'\] as Map<String, dynamic>\?;
        \}\);
  \}"""

repo_replace = """  Stream<Map<String, dynamic>?> getContractProposalStream(String contractId) {
    return _client
        .from('contracts')
        .stream(primaryKey: ['id'])
        .eq('id', contractId)
        .map((rows) {
          if (rows.isEmpty) return null;
          final changes = rows.first['proposed_changes'] as Map<String, dynamic>?;
          if (changes == null) return null;
          return {
            'changes': changes,
            'proposed_by': rows.first['proposed_by'],
          };
        });
  }"""

content = re.sub(repo_regex, repo_replace, content)

with open('lib/features/property/data/property_repository.dart', 'w') as f:
    f.write(content)

