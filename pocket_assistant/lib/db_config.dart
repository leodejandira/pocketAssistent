import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // SUBSTITUA COM SUAS CREDENCIAIS REAIS DO SUPABASE
  static const String url = 'https://pnwkvrfshrthgtujmnkv.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBud2t2cmZzaHJ0aGd0dWptbmt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA1NDgyNDksImV4cCI6MjA3NjEyNDI0OX0.NyYFRbz81kJsXLXJJc9X92NVM_Zg-K29A2JuufnbWxA';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    print('✅ Supabase inicializado com sucesso!');
  }
}
