import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const supabaseUrl = 'https://ewylzbdegjtmedpbefah.supabase.co';
  static const supabaseAnonKey = 'sb_publishable_8QtzCWD5laT-t_kXLkxcwQ_3gM9BwBr';

  static SupabaseClient get client => Supabase.instance.client;
}
