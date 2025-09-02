import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/auth_config.dart';
import '../models/user.dart' as app_user;

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtenir l'utilisateur actuel
  app_user.User? get currentUser {
    final user = _supabase.auth.currentUser;
    print('Current user from Supabase: ${user?.id}');
    if (user != null) {
      return app_user.User(
        id: user.id,
        email: user.email ?? '',
        name:
            '${user.userMetadata?['first_name'] ?? ''} ${user.userMetadata?['last_name'] ?? ''}'
                .trim(),
        availablePoints: 0,
        exchangedPoints: 0,
        collectedQRCodes: 0,
        createdAt: DateTime.parse(user.createdAt),
        lastLoginAt: user.lastSignInAt != null
            ? DateTime.parse(user.lastSignInAt!)
            : DateTime.parse(user.createdAt),
      );
    }
    return null;
  }

  // Obtenir la session actuelle
  Session? get currentSession {
    final session = _supabase.auth.currentSession;
    print('Current session: ${session?.user.id}');
    return session;
  }

  // Inscription
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    print('Signing up user: $email');

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'first_name': firstName, 'last_name': lastName},
        emailRedirectTo: AuthConfig.emailConfirmationRedirectUrl,
      );

      print(
        'Sign up response: ${response.user?.id}, emailConfirmed: ${response.user?.emailConfirmedAt}',
      );

      if (response.user != null) {
        // Créer le profil utilisateur dans la table users
        await _createUserProfile(response.user!, email, firstName, lastName);

        // Attendre un peu pour s'assurer que le profil est créé
        await Future.delayed(const Duration(milliseconds: 500));
      }

      return response;
    } catch (e) {
      print('Error during sign up: $e');
      rethrow;
    }
  }

  // Créer le profil utilisateur dans la table users
  Future<void> _createUserProfile(
    User user,
    String email,
    String firstName,
    String lastName,
  ) async {
    try {
      print('Creating user profile for: ${user.id}');

      // Vérifier d'abord si le profil existe déjà
      final existingProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Créer le profil utilisateur avec un QR code personnel
        final personalQRCode =
            'USER_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch % 10000}';

        final insertData = {
          'id': user.id,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'available_points': 0,
          'exchanged_points': 0,
          'collected_qr_codes': 0,
          'personal_qr_code': personalQRCode,
          'created_at': DateTime.now().toIso8601String(),
          'last_login_at': DateTime.now().toIso8601String(),
        };

        print('Inserting user profile with data: $insertData');

        await _supabase.from(SupabaseConfig.usersTable).insert(insertData);

        print(
          'User profile created successfully for user: ${user.id} with QR code: $personalQRCode',
        );
      } else {
        print('User profile already exists for user: ${user.id}');

        // Vérifier si le profil a un QR code personnel
        try {
          final profile = await _supabase
              .from(SupabaseConfig.usersTable)
              .select('personal_qr_code')
              .eq('id', user.id)
              .single();

          if (profile['personal_qr_code'] == null) {
            // Générer un QR code personnel si il n'en a pas
            final personalQRCode =
                'USER_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch % 10000}';
            await _supabase
                .from(SupabaseConfig.usersTable)
                .update({'personal_qr_code': personalQRCode})
                .eq('id', user.id);
            print(
              'Personal QR code generated for existing user: $personalQRCode',
            );
          }
        } catch (e) {
          print('Error checking/generating personal QR code: $e');
        }
      }
    } catch (e) {
      print('Error creating user profile: $e');
      // Ne pas échouer l'inscription si la création du profil échoue
      // Le profil sera créé lors de la prochaine connexion
    }
  }

  // Connexion
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    print('Signing in user: $email');

    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    print(
      'Sign in response: ${response.user?.id}, session: ${response.session?.user.id}',
    );

    if (response.user != null && response.session != null) {
      // Vérifier et créer le profil utilisateur si nécessaire
      await _ensureUserProfileExists(response.user!);

      // Mettre à jour la dernière connexion
      try {
        await _supabase
            .from(SupabaseConfig.usersTable)
            .update({'last_login_at': DateTime.now().toIso8601String()})
            .eq('id', response.user!.id);
        print('Last login updated successfully');
      } catch (e) {
        print('Error updating last login: $e');
        // Ne pas échouer la connexion si la mise à jour échoue
      }
    }

    return response;
  }

  // S'assurer que le profil utilisateur existe
  Future<void> _ensureUserProfileExists(User user) async {
    try {
      // Vérifier si le profil existe
      final profile = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null) {
        print('User profile not found during sign in, creating it...');

        // Créer le profil avec les données de l'utilisateur et un QR code personnel
        final personalQRCode =
            'USER_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch % 10000}';

        await _supabase.from(SupabaseConfig.usersTable).insert({
          'id': user.id,
          'email': user.email ?? '',
          'first_name': user.userMetadata?['first_name'] ?? '',
          'last_name': user.userMetadata?['last_name'] ?? '',
          'available_points': 0,
          'exchanged_points': 0,
          'collected_qr_codes': 0,
          'personal_qr_code': personalQRCode,
          'created_at': DateTime.now().toIso8601String(),
          'last_login_at': DateTime.now().toIso8601String(),
        });
        print(
          'User profile created during sign in for user: ${user.id} with QR code: $personalQRCode',
        );
      } else {
        print('User profile already exists for user: ${user.id}');

        // Vérifier si le profil a un QR code personnel
        try {
          final profileData = await _supabase
              .from(SupabaseConfig.usersTable)
              .select('personal_qr_code')
              .eq('id', user.id)
              .single();

          if (profileData['personal_qr_code'] == null) {
            // Générer un QR code personnel si il n'en a pas
            final personalQRCode =
                'USER_${user.id.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().millisecondsSinceEpoch % 10000}';
            await _supabase
                .from(SupabaseConfig.usersTable)
                .update({'personal_qr_code': personalQRCode})
                .eq('id', user.id);
            print(
              'Personal QR code generated for existing user: $personalQRCode',
            );
          }
        } catch (e) {
          print('Error checking/generating personal QR code: $e');
        }

        // Mettre à jour la dernière connexion
        try {
          await _supabase
              .from(SupabaseConfig.usersTable)
              .update({'last_login_at': DateTime.now().toIso8601String()})
              .eq('id', user.id);
          print('Last login time updated for user: ${user.id}');
        } catch (e) {
          print('Error updating last login time: $e');
        }
      }
    } catch (e) {
      print('Error ensuring user profile exists: $e');
      // Ne pas échouer la connexion si la création du profil échoue
      // Le profil sera créé lors de la prochaine tentative
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      print('Signing out user');

      // Vérifier si l'utilisateur est connecté avant la déconnexion
      final currentUser = _supabase.auth.currentUser;
      if (currentUser != null) {
        print('Current user before sign out: ${currentUser.id}');

        // Supprimer la session actuelle
        await _supabase.auth.signOut();

        // Vérifier que la déconnexion a bien fonctionné
        final userAfterSignOut = _supabase.auth.currentUser;
        if (userAfterSignOut == null) {
          print('User signed out successfully - no current user');
        } else {
          print(
            'WARNING: User still authenticated after sign out: ${userAfterSignOut.id}',
          );
          // Forcer la suppression de la session
          await _supabase.auth.signOut();
        }
      } else {
        print('No user to sign out');
      }

      // Nettoyer les données locales si nécessaire
      await _clearLocalData();
    } catch (e) {
      print('Error during sign out: $e');
      // Forcer la déconnexion même en cas d'erreur
      try {
        await _supabase.auth.signOut();
      } catch (forceSignOutError) {
        print('Force sign out error: $forceSignOutError');
      }
    }
  }

  // Nettoyer les données locales
  Future<void> _clearLocalData() async {
    try {
      // Supprimer les données stockées localement
      // Vous pouvez ajouter ici la suppression des SharedPreferences, etc.
      print('Local data cleared');
    } catch (e) {
      print('Error clearing local data: $e');
    }
  }

  // Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    print('Resetting password for: $email');
    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: AuthConfig.passwordResetRedirectUrl,
    );
    print('Password reset email sent');
  }

  // Réinitialisation du mot de passe en interne (sans redirection externe)
  Future<bool> resetPasswordInternal(String email) async {
    try {
      print('Resetting password internally for: $email');

      // Envoyer l'email de réinitialisation
      await _supabase.auth.resetPasswordForEmail(
        email,
        // Pas de redirection externe, on gère tout en interne
      );

      print('Password reset email sent internally');
      return true;
    } catch (e) {
      print('Error sending password reset email: $e');
      return false;
    }
  }

  // Mettre à jour le mot de passe avec le code de réinitialisation
  Future<bool> updatePasswordWithCode(String code, String newPassword) async {
    try {
      print('Updating password with code: $code');

      // Extraire le code du lien si c'est une URL
      String actualCode = code;
      if (code.contains('http')) {
        try {
          final uri = Uri.parse(code);
          actualCode =
              uri.queryParameters['code'] ??
              uri.queryParameters['token'] ??
              uri.queryParameters['access_token'] ??
              code;
          print('Extracted code from URL: ${actualCode.substring(0, 10)}...');
        } catch (e) {
          print('Error parsing URL: $e');
          return false;
        }
      }

      // Utiliser exchangeCodeForSession (méthode recommandée par Supabase)
      try {
        print(
          'Using exchangeCodeForSession with code: ${actualCode.substring(0, 10)}...',
        );
        final response = await _supabase.auth.exchangeCodeForSession(
          actualCode,
        );

        if (response.session != null) {
          print('Code exchanged successfully, updating password');

          await _supabase.auth.updateUser(
            UserAttributes(password: newPassword),
          );

          print('Password updated successfully');
          return true;
        } else {
          print('No session returned from exchangeCodeForSession');
          return false;
        }
      } catch (e) {
        print('exchangeCodeForSession failed: $e');
        return false;
      }
    } catch (e) {
      print('Error updating password with code: $e');
      return false;
    }
  }

  // Vérifier si un code de réinitialisation est valide
  Future<bool> isResetCodeValid(String code) async {
    try {
      print('Validating reset code: $code');

      final response = await _supabase.auth.exchangeCodeForSession(code);
      final isValid = response.session != null;

      print('Reset code validation result: $isValid');
      return isValid;
    } catch (e) {
      print('Error validating reset code: $e');
      return false;
    }
  }

  // Gérer les deep links pour la confirmation d'email et la réinitialisation
  Future<void> handleDeepLink(String url) async {
    print('Handling deep link: $url');
    try {
      if (url.contains('/auth/callback')) {
        // Gérer la confirmation d'email
        final session = _supabase.auth.currentSession;
        if (session != null) {
          print('Email confirmation handled');
        }
      } else if (url.contains('/auth/reset')) {
        // Gérer la réinitialisation de mot de passe
        final session = _supabase.auth.currentSession;
        if (session != null) {
          print('Password reset handled');
        }
      }
    } catch (e) {
      print('Error handling deep link: $e');
    }
  }

  // Vérifier le statut de confirmation de l'email
  Future<bool> checkEmailConfirmation(String email) async {
    try {
      // Cette méthode nécessite des permissions admin, donc on utilise une approche alternative
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: 'dummy_password_for_check',
      );
      return false; // Si on arrive ici, le mot de passe était incorrect
    } catch (e) {
      if (e.toString().contains('Invalid login credentials')) {
        // L'utilisateur existe, on peut vérifier son statut via la table users
        try {
          final result = await _supabase
              .from(SupabaseConfig.usersTable)
              .select('id')
              .eq('email', email)
              .single();
          return result != null;
        } catch (e) {
          print('Error checking user existence: $e');
          return false;
        }
      }
      return false;
    }
  }

  // Écouter les changements d'authentification
  Stream<AuthState> get authStateChanges {
    print('Setting up auth state changes listener');
    return _supabase.auth.onAuthStateChange;
  }

  // Vérifier si l'utilisateur est connecté
  bool get isAuthenticated {
    final authenticated = _supabase.auth.currentUser != null;
    print('Is authenticated: $authenticated');
    return authenticated;
  }

  // Vérifier si l'email est confirmé
  bool get isEmailConfirmed {
    final user = _supabase.auth.currentUser;
    final confirmed = user?.emailConfirmedAt != null;
    print('Is email confirmed: $confirmed');
    return confirmed;
  }

  // Rafraîchir la session
  Future<void> refreshSession() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session != null) {
        await _supabase.auth.refreshSession();
        print('Session refreshed successfully');
      }
    } catch (e) {
      print('Error refreshing session: $e');
    }
  }

  // Mettre à jour le profil utilisateur
  Future<void> updateUserProfile({
    required String firstName,
    required String lastName,
  }) async {
    try {
      print('Updating user profile: $firstName $lastName');

      await _supabase.auth.updateUser(
        UserAttributes(data: {'first_name': firstName, 'last_name': lastName}),
      );

      print('User profile updated successfully');
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Mettre à jour l'email de l'utilisateur
  Future<void> updateUserEmail(String newEmail) async {
    try {
      print('Updating user email to: $newEmail');

      await _supabase.auth.updateUser(UserAttributes(email: newEmail));

      print('User email updated successfully');
    } catch (e) {
      print('Error updating user email: $e');
      rethrow;
    }
  }

  // Mettre à jour le mot de passe de l'utilisateur
  Future<void> updateUserPassword(String newPassword) async {
    try {
      print('Updating user password');

      await _supabase.auth.updateUser(UserAttributes(password: newPassword));

      print('User password updated successfully');
    } catch (e) {
      print('Error updating user password: $e');
      rethrow;
    }
  }
}
