import 'package:supabase/supabase.dart';
void main() async {
  final supabase = SupabaseClient('https://qydoyfzjntokryrxyxez.supabase.co', 'dummy');
  // Just want to see if we can read profiles locally or using curl to the local instance?
  // We don't have the secret. We can just use grep to see if email is in profile.
}
