import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aya/providers/auth_provider.dart';
import 'package:aya/providers/user_provider.dart';
import 'package:aya/screens/splash_screen.dart';
import 'package:aya/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Masquer la barre de notification système
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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
        title: 'Mon univers AYA',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
