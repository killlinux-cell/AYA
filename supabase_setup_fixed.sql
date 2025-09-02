-- Configuration complète de la base de données Supabase pour Aya Huile App
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- 1. Créer la table users avec la bonne structure
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT NOT NULL UNIQUE,
    first_name TEXT,
    last_name TEXT,
    available_points INTEGER DEFAULT 0,
    exchanged_points INTEGER DEFAULT 0,
    collected_qr_codes INTEGER DEFAULT 0,
    personal_qr_code TEXT UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Créer la table qr_codes
CREATE TABLE IF NOT EXISTS public.qr_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    points INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Créer la table user_qr_codes (relation many-to-many)
CREATE TABLE IF NOT EXISTS public.user_qr_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    qr_code_id UUID REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    points_earned INTEGER NOT NULL,
    UNIQUE(user_id, qr_code_id)
);

-- 4. Créer la table games
CREATE TABLE IF NOT EXISTS public.games (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    points_cost INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Créer la table user_games
CREATE TABLE IF NOT EXISTS public.user_games (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    points_spent INTEGER DEFAULT 0,
    UNIQUE(user_id, game_id)
);

-- 6. Activer RLS (Row Level Security) sur toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_games ENABLE ROW LEVEL SECURITY;

-- 7. Créer les politiques RLS pour la table users
-- Les utilisateurs peuvent voir et modifier uniquement leur propre profil
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- 8. Créer les politiques RLS pour la table qr_codes
-- Tout le monde peut voir les codes QR actifs
CREATE POLICY "Anyone can view active QR codes" ON public.qr_codes
    FOR SELECT USING (is_active = true);

-- Seuls les admins peuvent modifier les codes QR
CREATE POLICY "Only admins can modify QR codes" ON public.qr_codes
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- 9. Créer les politiques RLS pour la table user_qr_codes
-- Les utilisateurs peuvent voir leurs propres codes QR collectés
CREATE POLICY "Users can view own QR codes" ON public.user_qr_codes
    FOR SELECT USING (auth.uid() = user_id);

-- Les utilisateurs peuvent insérer leurs propres codes QR collectés
CREATE POLICY "Users can insert own QR codes" ON public.user_qr_codes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 10. Créer les politiques RLS pour la table games
-- Tout le monde peut voir les jeux actifs
CREATE POLICY "Anyone can view active games" ON public.games
    FOR SELECT USING (is_active = true);

-- Seuls les admins peuvent modifier les jeux
CREATE POLICY "Only admins can modify games" ON public.games
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- 11. Créer les politiques RLS pour la table user_games
-- Les utilisateurs peuvent voir leurs propres parties
CREATE POLICY "Users can view own games" ON public.user_games
    FOR SELECT USING (auth.uid() = user_id);

-- Les utilisateurs peuvent insérer leurs propres parties
CREATE POLICY "Users can insert own games" ON public.user_games
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 12. Créer un trigger pour mettre à jour automatiquement last_login_at
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW() 
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_login
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_login();

-- 13. Insérer quelques codes QR d'exemple
INSERT INTO public.qr_codes (code, points, description) VALUES
    ('WELCOME2024', 100, 'Code de bienvenue'),
    ('BONUS50', 50, 'Bonus spécial'),
    ('EXTRA25', 25, 'Points supplémentaires')
ON CONFLICT (code) DO NOTHING;

-- 14. Insérer quelques jeux d'exemple
INSERT INTO public.games (name, description, points_cost) VALUES
    ('Quiz Aya Huile', 'Testez vos connaissances sur l''huile d''argan', 20),
    ('Memory Game', 'Jeu de mémoire avec des cartes', 15),
    ('Lucky Spin', 'Tournez la roue de la chance', 30)
ON CONFLICT DO NOTHING;

-- 15. Créer un index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_user_qr_codes_user_id ON public.user_qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_games_user_id ON public.user_games(user_id);

-- 16. Vérifier que tout est configuré correctement
SELECT 'Configuration terminée avec succès!' as status;
