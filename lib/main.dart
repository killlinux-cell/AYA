import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:aya/providers/auth_provider.dart';
import 'package:aya/providers/user_provider.dart';
import 'package:aya/screens/splash_screen.dart';
import 'package:aya/screens/email_confirmation_screen.dart';
import 'package:aya/services/deep_link_service.dart';
import 'package:aya/utils/theme.dart';
import 'package:aya/config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, UserProvider>(
          create: (_) => UserProvider(),
          update: (_, authProvider, userProvider) {
            userProvider ??= UserProvider();

            // Réinitialiser le UserProvider si l'utilisateur n'est plus authentifié
            if (!authProvider.isAuthenticated) {
              userProvider.reset();
            }
            // Initialiser le UserProvider quand l'AuthProvider change et qu'il y a un utilisateur authentifié
            else if (authProvider.isAuthenticated &&
                userProvider.user == null) {
              userProvider.initialize();
            }

            return userProvider;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Aya HUILE VÉGÉTALE',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        onGenerateRoute: (settings) {
          // Gérer les deep links pour la confirmation d'email et la réinitialisation de mot de passe
          if (settings.name?.startsWith('/auth/callback') == true) {
            return MaterialPageRoute(
              builder: (context) =>
                  const EmailConfirmationScreen(type: 'confirmation'),
            );
          } else if (settings.name?.startsWith('/auth/reset') == true) {
            return MaterialPageRoute(
              builder: (context) =>
                  const EmailConfirmationScreen(type: 'reset'),
            );
          }
          return null;
        },
        onUnknownRoute: (settings) {
          // Gérer les routes inconnues (comme les deep links)
          return MaterialPageRoute(
            builder: (context) => const EmailConfirmationScreen(),
          );
        },
      ),
    );
  }
}
