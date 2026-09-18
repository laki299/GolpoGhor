import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/supabase_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  // ======================
  // Sign Up
  // ======================
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {
        if (fullName != null) 'full_name': fullName,
        if (username != null) 'username': username,
      },
    );

    // Profile তৈরি
    if (response.user != null) {
      try {
        await _client.from(SupabaseConstants.profiles).upsert({
          'id': response.user!.id,
          'full_name': fullName,
          'username': username,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        // Profile তৈরি ব্যর্থ হলেও সাইনআপ সফল হতে পারে
        print('Profile creation error: $e');
      }
    }

    return response;
  }

  // ======================
  // Sign In
  // ======================
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ======================
  // Sign Out
  // ======================
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ======================
  // Get Current Profile
  // ======================
  Future<UserModel?> getCurrentProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final data = await _client
        .from(SupabaseConstants.profiles)
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (data == null) {
      // Profile না থাকলে তৈরি করে দিই
      await _client.from(SupabaseConstants.profiles).upsert({
        'id': user.id,
        'full_name': user.userMetadata?['full_name'],
        'username': user.userMetadata?['username'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      final newData = await _client
          .from(SupabaseConstants.profiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (newData == null) return null;
      return UserModel.fromJson(newData);
    }

    return UserModel.fromJson(data);
  }

  // ======================
  // Update Profile
  // ======================
  Future<void> updateProfile({
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('User not logged in');

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (fullName != null) updates['full_name'] = fullName;
    if (username != null) updates['username'] = username;
    if (bio != null) updates['bio'] = bio;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client
        .from(SupabaseConstants.profiles)
        .update(updates)
        .eq('id', user.id);
  }

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}
