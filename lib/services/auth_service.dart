import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static AuthService? _instance;
  static AuthService get instance => _instance ??= AuthService._();
  AuthService._();

  static final _supabase = Supabase.instance.client;

  // Check if user is currently logged in with null safety
  static bool get isLoggedIn {
    try {
      final session = _supabase.auth.currentSession;
      return session != null;
    } catch (e) {
      print('Auth check error: $e');
      return false;
    }
  }

  // Check if user is currently authenticated (alias for isLoggedIn)
  static bool get isAuthenticated => isLoggedIn;

  // Get current user with null safety
  static User? get currentUser {
    try {
      return _supabase.auth.currentUser;
    } catch (e) {
      print('Current user error: $e');
      return null;
    }
  }

  // Get current user ID with null safety
  static String? get currentUserId {
    try {
      return _supabase.auth.currentUser?.id;
    } catch (e) {
      print('Current user ID error: $e');
      return null;
    }
  }

  // Enhanced auth initialization with timeout and error handling
  static Future<bool> initializeAuth() async {
    try {
      // Check if we have a valid session first
      final session = _supabase.auth.currentSession;
      if (session != null) {
        print('Valid session found');
        return true;
      }

      // Development mode: Try to get first available user for demo
      final prefs = await SharedPreferences.getInstance();
      final demoEmail =
          prefs.getString('demo_user_email') ?? 'admin@faturamanager.com';

      // For development, we'll create a simple auth bypass
      final success = await _signInDevelopmentMode(demoEmail);
      print('Development mode auth: $success');
      return success;
    } catch (e) {
      print('Auth initialization error: $e');
      // Return false but don't crash the app
      return false;
    }
  }

  // Enhanced development mode sign-in with better error handling
  static Future<bool> _signInDevelopmentMode(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('demo_user_email', email);

      // Try to get user profile that matches this email
      final userProfile = await _supabase
          .from('user_profiles')
          .select('id, email, full_name')
          .eq('email', email)
          .maybeSingle();

      if (userProfile != null) {
        // Store user info for development mode
        await prefs.setString('demo_user_id', userProfile['id']);
        await prefs.setString(
            'demo_user_name', userProfile['full_name'] ?? 'Demo User');
        print('Demo user profile found: ${userProfile['full_name']}');
        return true;
      } else {
        print('No user profile found for: $email');
        return false;
      }
    } catch (e) {
      print('Development sign-in error: $e');
      return false;
    }
  }

  // Enhanced sign up with better error handling
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
        },
      );

      // If signup successful, create user profile
      if (response.user != null) {
        await _createUserProfile(response.user!, fullName, phone);
      }

      return response;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }

  // Create user profile in database
  Future<void> _createUserProfile(
      User user, String fullName, String? phone) async {
    try {
      await _supabase.from('user_profiles').insert({
        'id': user.id,
        'email': user.email!,
        'full_name': fullName,
        'phone': phone,
        'role': 'business_owner',
        'is_active': true,
      });
    } catch (e) {
      print('Create user profile error: $e');
      // Don't rethrow to avoid breaking signup flow
    }
  }

  // Enhanced sign in with better error handling
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      print('Sign in error: $e');
      rethrow;
    }
  }

  // Enhanced sign out with cleanup
  static Future<void> logout() async {
    try {
      await _supabase.auth.signOut();

      // Clear development mode data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('demo_user_email');
      await prefs.remove('demo_user_id');
      await prefs.remove('demo_user_name');

      print('Logout successful');
    } catch (e) {
      print('Logout error: $e');
    }
  }

  // Enhanced reset password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // Enhanced update user profile
  Future<UserResponse> updateUserProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phone != null) updates['phone'] = phone;

      final response = await _supabase.auth.updateUser(
        UserAttributes(data: updates),
      );

      // Also update the user_profiles table
      if (currentUserId != null) {
        await _supabase.from('user_profiles').update({
          if (fullName != null) 'full_name': fullName,
          if (phone != null) 'phone': phone,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', currentUserId!);
      }

      return response;
    } catch (e) {
      print('Update user profile error: $e');
      rethrow;
    }
  }

  // Listen to auth state changes with error handling
  static Stream<AuthState> get authStateChanges {
    try {
      return _supabase.auth.onAuthStateChange;
    } catch (e) {
      print('Auth state changes error: $e');
      // Return empty stream if error
      return const Stream.empty();
    }
  }

  // Enhanced business ID retrieval with fallback mechanisms
  static Future<String?> getUserBusinessId() async {
    try {
      String? userId = currentUserId;

      // If not logged in, try development mode
      if (userId == null) {
        final prefs = await SharedPreferences.getInstance();
        userId = prefs.getString('demo_user_id');
      }

      if (userId == null) return null;

      final businessProfile = await _supabase
          .from('business_profiles')
          .select('id')
          .eq('owner_id', userId)
          .maybeSingle();

      final businessId = businessProfile?['id'];
      print('Business ID found: $businessId');
      return businessId;
    } catch (e) {
      print('Error getting business ID: $e');
      return null;
    }
  }

  // Enhanced business profile retrieval
  static Future<Map<String, dynamic>?> getBusinessProfile() async {
    try {
      final businessId = await getUserBusinessId();
      if (businessId == null) {
        print('No business ID available');
        return null;
      }

      final businessProfile = await _supabase
          .from('business_profiles')
          .select('*')
          .eq('id', businessId)
          .maybeSingle();

      if (businessProfile != null) {
        print('Business profile found: ${businessProfile['business_name']}');
      }
      return businessProfile;
    } catch (e) {
      print('Error getting business profile: $e');
      return null;
    }
  }

  // Check if user has valid business profile
  static Future<bool> hasBusinessProfile() async {
    try {
      final profile = await getBusinessProfile();
      return profile != null;
    } catch (e) {
      print('Error checking business profile: $e');
      return false;
    }
  }

  // Get user display name
  static Future<String> getUserDisplayName() async {
    try {
      if (isLoggedIn && currentUser != null) {
        return currentUser!.userMetadata?['full_name'] ??
            currentUser!.email ??
            'User';
      }

      // Development mode fallback
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('demo_user_name') ?? 'Demo User';
    } catch (e) {
      print('Error getting user display name: $e');
      return 'User';
    }
  }

  // Validate session and refresh if needed
  static Future<bool> validateSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) return false;

      // Check if session is expired
      final expiresAt =
          DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000);
      if (expiresAt.isBefore(DateTime.now())) {
        // Try to refresh
        final refreshed = await _supabase.auth.refreshSession();
        return refreshed.session != null;
      }

      return true;
    } catch (e) {
      print('Session validation error: $e');
      return false;
    }
  }
}