import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/user.dart' as app_user;
import '../models/qr_code.dart';
import 'dart:math';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Obtenir les données utilisateur complètes
  Future<app_user.User?> getUserData(String userId) async {
    try {
      print('UserService: Getting user data for ID: $userId');

      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', userId)
          .maybeSingle(); // Utiliser maybeSingle au lieu de single

      print('UserService: Raw response from database: $response');

      if (response != null) {
        final user = app_user.User.fromJson({
          'id': response['id'],
          'email': response['email'],
          'name':
              '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'
                  .trim(),
          'availablePoints': response['available_points'] ?? 0,
          'exchangedPoints': response['exchanged_points'] ?? 0,
          'collectedQRCodes': response['collected_qr_codes'] ?? 0,
          'createdAt': response['created_at'],
          'lastLoginAt': response['last_login_at'],
          'personalQRCode': response['personal_qr_code'],
        });

        print(
          'UserService: User object created: ${user.name}, Points: ${user.availablePoints}',
        );
        
        // Vérifier si c'est un nouvel utilisateur
        if (user.availablePoints == 0 && user.collectedQRCodes == 0) {
          print('UserService: New user detected - this is normal for new registrations');
        }
        
        return user;
      } else {
        // L'utilisateur n'existe pas dans la table users, le créer automatiquement
        print('UserService: User profile not found, creating it automatically');
        await _createUserProfileIfMissing(userId);
        
        // Récupérer à nouveau les données
        return await getUserData(userId);
      }
    } catch (e) {
      print('UserService: Error getting user data: $e');
      if (e.toString().contains('No rows returned') || e.toString().contains('PGRST116')) {
        print('UserService: No user found with ID: $userId - creating profile automatically');
        try {
          await _createUserProfileIfMissing(userId);
          return await getUserData(userId);
        } catch (createError) {
          print('UserService: Failed to create user profile: $createError');
          return null;
        }
      }
      rethrow;
    }
  }

  // Créer automatiquement le profil utilisateur s'il manque
  Future<void> _createUserProfileIfMissing(String userId) async {
    try {
      // Récupérer les informations de base depuis Supabase Auth
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      // Générer un QR code personnel unique
      final personalQRCode = await generatePersonalQRCode(userId);

      // Créer le profil utilisateur
      await _supabase.from(SupabaseConfig.usersTable).insert({
        'id': userId,
        'email': authUser.email ?? '',
        'first_name': authUser.userMetadata?['first_name'] ?? '',
        'last_name': authUser.userMetadata?['last_name'] ?? '',
        'available_points': 0,
        'exchanged_points': 0,
        'collected_qr_codes': 0,
        'personal_qr_code': personalQRCode,
        'created_at': DateTime.now().toIso8601String(),
        'last_login_at': DateTime.now().toIso8601String(),
      });

      print('UserService: User profile created automatically for ID: $userId');
    } catch (e) {
      print('UserService: Error creating user profile automatically: $e');
      rethrow;
    }
  }

  // Générer un QR code personnel unique pour l'utilisateur
  Future<String> generatePersonalQRCode(String userId) async {
    try {
      // Générer un code unique basé sur l'ID utilisateur et un timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(9999);
      final personalCode =
          'USER_${userId.substring(0, 8)}_${timestamp}_$random';

      // Mettre à jour la base de données avec le nouveau QR code personnel
      await _supabase
          .from(SupabaseConfig.usersTable)
          .update({'personal_qr_code': personalCode})
          .eq('id', userId);

      print('UserService: Personal QR code generated: $personalCode');
      return personalCode;
    } catch (e) {
      print('UserService: Error generating personal QR code: $e');
      rethrow;
    }
  }

  // Obtenir le QR code personnel de l'utilisateur
  Future<String?> getPersonalQRCode(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('personal_qr_code')
          .eq('id', userId)
          .single();

      return response['personal_qr_code'];
    } catch (e) {
      print('UserService: Error getting personal QR code: $e');
      return null;
    }
  }

  // Vérifier l'identité d'un utilisateur via son QR code personnel
  Future<app_user.User?> verifyUserByQRCode(String personalQRCode) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('personal_qr_code', personalQRCode)
          .single();

      if (response != null) {
        return app_user.User.fromJson({
          'id': response['id'],
          'email': response['email'],
          'name':
              '${response['first_name'] ?? ''} ${response['last_name'] ?? ''}'
                  .trim(),
          'availablePoints': response['available_points'] ?? 0,
          'exchangedPoints': response['exchanged_points'] ?? 0,
          'collectedQRCodes': response['collected_qr_codes'] ?? 0,
          'createdAt': response['created_at'],
          'lastLoginAt': response['last_login_at'],
          'personalQRCode': response['personal_qr_code'],
        });
      }
      return null;
    } catch (e) {
      print('UserService: Error verifying user by QR code: $e');
      return null;
    }
  }

  // Mettre à jour les points de l'utilisateur
  Future<void> updateUserPoints(
    String userId,
    int availablePoints,
    int exchangedPoints,
  ) async {
    try {
      await _supabase
          .from(SupabaseConfig.usersTable)
          .update({
            'available_points': availablePoints,
            'exchanged_points': exchangedPoints,
          })
          .eq('id', userId);
    } catch (e) {
      print('Erreur lors de la mise à jour des points: $e');
      rethrow;
    }
  }

  // Ajouter un code QR collecté
  Future<void> addQRCode(String userId, QRCode qrCode) async {
    try {
      // Ajouter le code QR à la table user_qr_codes
      await _supabase.from(SupabaseConfig.userQRCodesTable).insert({
        'user_id': userId,
        'qr_code_id': qrCode.id,
        'collected_at': qrCode.collectedAt.toIso8601String(),
        'points_earned': qrCode.points,
      });

      // Mettre à jour les statistiques de l'utilisateur
      final userData = await getUserData(userId);
      if (userData != null) {
        await updateUserPoints(
          userId,
          userData.availablePoints + qrCode.points,
          userData.exchangedPoints,
        );

        await _supabase
            .from(SupabaseConfig.usersTable)
            .update({'collected_qr_codes': userData.collectedQRCodes + 1})
            .eq('id', userId);
      }
    } catch (e) {
      print('Erreur lors de l\'ajout du code QR: $e');
      rethrow;
    }
  }

  // Obtenir tous les codes QR collectés par l'utilisateur
  Future<List<QRCode>> getUserQRCodes(String userId) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.userQRCodesTable)
          .select('*, qr_codes(*)')
          .eq('user_id', userId)
          .order('collected_at', ascending: false);

      return response.map<QRCode>((data) {
        final qrData = data['qr_codes'] as Map<String, dynamic>;
        return QRCode(
          id: qrData['id'],
          code: qrData['code'],
          points: data['points_earned'],
          collectedAt: DateTime.parse(data['collected_at']),
          description: qrData['description'] ?? 'Code QR collecté',
        );
      }).toList();
    } catch (e) {
      print('Erreur lors de la récupération des codes QR: $e');
      return [];
    }
  }

  // Vérifier si un code QR a déjà été collecté
  Future<bool> hasQRCode(String userId, String qrCode) async {
    try {
      final response = await _supabase
          .from(SupabaseConfig.userQRCodesTable)
          .select('qr_codes!inner(*)')
          .eq('user_id', userId)
          .eq('qr_codes.code', qrCode)
          .limit(1);

      return response.isNotEmpty;
    } catch (e) {
      print('Erreur lors de la vérification du code QR: $e');
      return false;
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
      // Vérifier d'abord si le profil existe déjà
      final existingProfile = await _supabase
          .from(SupabaseConfig.usersTable)
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile == null) {
        // Générer un QR code personnel unique
        final personalQRCode = await generatePersonalQRCode(user.id);

        // Créer le profil utilisateur
        await _supabase.from(SupabaseConfig.usersTable).insert({
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
        });
        print(
          'User profile created successfully for user: ${user.id} with QR code: $personalQRCode',
        );
      } else {
        print('User profile already exists for user: ${user.id}');

        // Vérifier si le profil a un QR code personnel
        final profile = await _supabase
            .from(SupabaseConfig.usersTable)
            .select('personal_qr_code')
            .eq('id', user.id)
            .single();

        if (profile['personal_qr_code'] == null) {
          // Générer un QR code personnel si il n'en a pas
          final personalQRCode = await generatePersonalQRCode(user.id);
          print(
            'Personal QR code generated for existing user: $personalQRCode',
          );
        }
      }
    } catch (e) {
      print('Error creating user profile: $e');
      // Ne pas échouer l'inscription si la création du profil échoue
      // Le profil sera créé lors de la prochaine connexion
    }
  }
}
