import 'package:supabase_flutter/supabase_flutter.dart';

/// Convenience accessors for the shared Supabase client.
SupabaseClient get db => Supabase.instance.client;

/// Id of the currently signed-in user, or null when signed out.
String? currentUserId() => Supabase.instance.client.auth.currentUser?.id;