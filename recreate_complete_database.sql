-- Script complet pour recréer toutes les tables et relations du projet Aya
-- ATTENTION: Ce script supprime TOUTES les données existantes et recrée tout depuis zéro
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- =====================================================
-- PHASE 1: SUPPRESSION COMPLÈTE DE TOUTES LES DONNÉES
-- =====================================================

-- Désactiver temporairement RLS pour permettre la suppression
DO $$
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN 
        SELECT tablename 
        FROM pg_tables 
        WHERE schemaname = 'public' 
            AND tablename NOT LIKE 'pg_%'
            AND tablename NOT LIKE 'sql_%'
    LOOP
        EXECUTE format('ALTER TABLE public.%I DISABLE ROW LEVEL SECURITY', table_record.tablename);
    END LOOP;
END $$;

-- Supprimer toutes les données dans l'ordre correct (respecter les contraintes de clés étrangères)
DELETE FROM public.user_games;
DELETE FROM public.user_qr_codes;
DELETE FROM public.users;
DELETE FROM public.qr_codes;
DELETE FROM public.games;

-- Supprimer tous les utilisateurs authentifiés
DELETE FROM auth.users;

-- =====================================================
-- PHASE 2: SUPPRESSION ET RECRÉATION DES TABLES
-- =====================================================

-- Supprimer les tables existantes (si elles existent)
DROP TABLE IF EXISTS public.user_games CASCADE;
DROP TABLE IF EXISTS public.user_qr_codes CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.qr_codes CASCADE;
DROP TABLE IF EXISTS public.games CASCADE;

-- =====================================================
-- PHASE 3: CRÉATION DES TABLES
-- =====================================================

-- 1. Créer la table users avec la structure complète
CREATE TABLE public.users (
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
CREATE TABLE public.qr_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    points INTEGER NOT NULL DEFAULT 0,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Créer la table user_qr_codes (relation many-to-many)
CREATE TABLE public.user_qr_codes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    qr_code_id UUID REFERENCES public.qr_codes(id) ON DELETE CASCADE,
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    points_earned INTEGER NOT NULL,
    UNIQUE(user_id, qr_code_id)
);

-- 4. Créer la table games
CREATE TABLE public.games (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    points_cost INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Créer la table user_games
CREATE TABLE public.user_games (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    game_id UUID REFERENCES public.games(id) ON DELETE CASCADE,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    points_spent INTEGER DEFAULT 0,
    UNIQUE(user_id, game_id)
);

-- =====================================================
-- PHASE 4: ACTIVATION DE RLS ET CRÉATION DES POLITIQUES
-- =====================================================

-- Activer RLS sur toutes les tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_games ENABLE ROW LEVEL SECURITY;

-- Politiques pour la table users
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Politiques pour la table qr_codes
CREATE POLICY "Anyone can view active QR codes" ON public.qr_codes
    FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins can modify QR codes" ON public.qr_codes
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Politiques pour la table user_qr_codes
CREATE POLICY "Users can view own QR codes" ON public.user_qr_codes
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own QR codes" ON public.user_qr_codes
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiques pour la table games
CREATE POLICY "Anyone can view active games" ON public.games
    FOR SELECT USING (is_active = true);

CREATE POLICY "Only admins can modify games" ON public.games
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Politiques pour la table user_games
CREATE POLICY "Users can view own games" ON public.user_games
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own games" ON public.user_games
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- =====================================================
-- PHASE 5: CRÉATION DES TRIGGERS ET FONCTIONS
-- =====================================================

-- Fonction pour mettre à jour automatiquement last_login_at
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.users 
    SET last_login_at = NOW() 
    WHERE id = NEW.id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour mettre à jour last_login_at lors de la connexion
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_login();

-- =====================================================
-- PHASE 6: INSERTION DES DONNÉES DE BASE
-- =====================================================

-- Insérer des codes QR d'exemple
INSERT INTO public.qr_codes (code, points, description) VALUES
    ('WELCOME2024', 100, 'Code de bienvenue'),
    ('BONUS50', 50, 'Bonus spécial'),
    ('EXTRA25', 25, 'Points supplémentaires'),
    ('AYA_HUILE', 75, 'Code spécial Aya Huile'),
    ('PROMO100', 100, 'Code promotionnel')
ON CONFLICT (code) DO NOTHING;

-- Insérer des jeux d'exemple
INSERT INTO public.games (name, description, points_cost) VALUES
    ('Quiz Aya Huile', 'Testez vos connaissances sur l''huile d''argan', 20),
    ('Memory Game', 'Jeu de mémoire avec des cartes', 15),
    ('Lucky Spin', 'Tournez la roue de la chance', 30),
    ('Scratch & Win', 'Grattez et gagnez des points', 25)
ON CONFLICT DO NOTHING;

-- =====================================================
-- PHASE 7: CRÉATION DES INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_personal_qr ON public.users(personal_qr_code);
CREATE INDEX IF NOT EXISTS idx_user_qr_codes_user_id ON public.user_qr_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_qr_codes_qr_code_id ON public.user_qr_codes(qr_code_id);
CREATE INDEX IF NOT EXISTS idx_user_games_user_id ON public.user_games(user_id);
CREATE INDEX IF NOT EXISTS idx_user_games_game_id ON public.user_games(game_id);
CREATE INDEX IF NOT EXISTS idx_qr_codes_code ON public.qr_codes(code);
CREATE INDEX IF NOT EXISTS idx_qr_codes_active ON public.qr_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_games_active ON public.games(is_active);

-- =====================================================
-- PHASE 8: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que toutes les tables sont créées
SELECT 
    'Tables créées' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('users', 'qr_codes', 'user_qr_codes', 'games', 'user_games')
ORDER BY tablename;

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
ORDER BY tablename, cmd;

-- Vérifier les données de base
SELECT 'QR Codes créés' as check_type, COUNT(*) as count FROM public.qr_codes
UNION ALL
SELECT 'Jeux créés', COUNT(*) FROM public.games;

-- Message de confirmation
SELECT 'Base de données recréée avec succès! Vous pouvez maintenant tester l''authentification.' as status;
