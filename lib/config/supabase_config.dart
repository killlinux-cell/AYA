class SupabaseConfig {
  // Remplacez ces valeurs par vos vraies clés Supabase
  static const String url = 'https://kdgwsqlpvqwzzrjgwtel.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtkZ3dzcWxwdnF3enpyamd3dGVsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUwNjY4MzcsImV4cCI6MjA3MDY0MjgzN30.RoNUk9AlX1PFkR7u_jbbjz0CNUsKNlJlAbHqTviXpQ4';

  // Tables de la base de données
  static const String usersTable = 'users';
  static const String qrCodesTable = 'qr_codes';
  static const String userQRCodesTable = 'user_qr_codes';
  static const String gamesTable = 'games';
  static const String userGamesTable = 'user_games';
}
