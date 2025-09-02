-- Script pour étendre la base de données avec le système de jeux
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- =====================================================
-- PHASE 1: CRÉATION DES TABLES DE JEUX
-- =====================================================

-- Table pour l'historique des jeux
CREATE TABLE IF NOT EXISTS public.game_history (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL,
    points_spent INTEGER NOT NULL DEFAULT 0,
    points_won INTEGER NOT NULL DEFAULT 0,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_winning BOOLEAN DEFAULT false
);

-- Table pour les limitations quotidiennes
CREATE TABLE IF NOT EXISTS public.daily_game_limits (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    game_type TEXT NOT NULL,
    last_played_date DATE NOT NULL,
    UNIQUE(user_id, game_type)
);

-- =====================================================
-- PHASE 2: ACTIVATION DE RLS ET POLITIQUES
-- =====================================================

-- Activer RLS sur les nouvelles tables
ALTER TABLE public.game_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_game_limits ENABLE ROW LEVEL SECURITY;

-- Politiques pour game_history
CREATE POLICY "Users can view own game history" ON public.game_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own game history" ON public.game_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiques pour daily_game_limits
CREATE POLICY "Users can view own daily limits" ON public.daily_game_limits
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily limits" ON public.daily_game_limits
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily limits" ON public.daily_game_limits
    FOR UPDATE USING (auth.uid() = user_id);

-- =====================================================
-- PHASE 3: INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index pour game_history
CREATE INDEX IF NOT EXISTS idx_game_history_user_id ON public.game_history(user_id);
CREATE INDEX IF NOT EXISTS idx_game_history_played_at ON public.game_history(played_at);
CREATE INDEX IF NOT EXISTS idx_game_history_game_type ON public.game_history(game_type);

-- Index pour daily_game_limits
CREATE INDEX IF NOT EXISTS idx_daily_game_limits_user_id ON public.daily_game_limits(user_id);
CREATE INDEX IF NOT EXISTS idx_daily_game_limits_game_type ON public.daily_game_limits(game_type);
CREATE INDEX IF NOT EXISTS idx_daily_game_limits_date ON public.daily_game_limits(last_played_date);

-- =====================================================
-- PHASE 4: FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour obtenir les statistiques de jeux d'un utilisateur
CREATE OR REPLACE FUNCTION public.get_user_game_stats(user_uuid UUID)
RETURNS TABLE (
    total_games BIGINT,
    total_points_spent BIGINT,
    total_points_won BIGINT,
    winning_games BIGINT,
    win_rate NUMERIC,
    net_points BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*) as total_games,
        COALESCE(SUM(points_spent), 0) as total_points_spent,
        COALESCE(SUM(points_won), 0) as total_points_won,
        COUNT(*) FILTER (WHERE is_winning) as winning_games,
        CASE 
            WHEN COUNT(*) > 0 THEN 
                ROUND((COUNT(*) FILTER (WHERE is_winning)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
            ELSE 0 
        END as win_rate,
        COALESCE(SUM(points_won - points_spent), 0) as net_points
    FROM public.game_history
    WHERE user_id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour vérifier si un utilisateur peut jouer aujourd'hui
CREATE OR REPLACE FUNCTION public.can_play_today(user_uuid UUID, game_type_param TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    last_played_date DATE;
    today_date DATE := CURRENT_DATE;
BEGIN
    -- Vérifier si l'utilisateur a déjà joué aujourd'hui
    SELECT last_played_date INTO last_played_date
    FROM public.daily_game_limits
    WHERE user_id = user_uuid AND game_type = game_type_param;
    
    -- Retourner true si l'utilisateur n'a jamais joué ou s'il n'a pas joué aujourd'hui
    RETURN last_played_date IS NULL OR last_played_date < today_date;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour enregistrer une partie jouée
CREATE OR REPLACE FUNCTION public.record_game_play(
    user_uuid UUID,
    game_type_param TEXT,
    points_spent_param INTEGER,
    points_won_param INTEGER
)
RETURNS VOID AS $$
BEGIN
    -- Insérer l'historique de la partie
    INSERT INTO public.game_history (
        user_id,
        game_type,
        points_spent,
        points_won,
        is_winning
    ) VALUES (
        user_uuid,
        game_type_param,
        points_spent_param,
        points_won_param,
        points_won_param > 0
    );
    
    -- Mettre à jour la limitation quotidienne
    INSERT INTO public.daily_game_limits (
        user_id,
        game_type,
        last_played_date
    ) VALUES (
        user_uuid,
        game_type_param,
        CURRENT_DATE
    )
    ON CONFLICT (user_id, game_type)
    DO UPDATE SET last_played_date = CURRENT_DATE;
    
    -- Mettre à jour les points de l'utilisateur
    UPDATE public.users
    SET available_points = available_points + (points_won_param - points_spent_param)
    WHERE id = user_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PHASE 5: VUES POUR LES RAPPORTS
-- =====================================================

-- Vue pour les statistiques globales des jeux
CREATE OR REPLACE VIEW public.game_statistics AS
SELECT 
    game_type,
    COUNT(*) as total_plays,
    COUNT(*) FILTER (WHERE is_winning) as winning_plays,
    COALESCE(SUM(points_spent), 0) as total_points_spent,
    COALESCE(SUM(points_won), 0) as total_points_won,
    CASE 
        WHEN COUNT(*) > 0 THEN 
            ROUND((COUNT(*) FILTER (WHERE is_winning)::NUMERIC / COUNT(*)::NUMERIC) * 100, 2)
        ELSE 0 
    END as win_rate,
    COALESCE(AVG(points_won), 0) as average_points_won
FROM public.game_history
GROUP BY game_type
ORDER BY total_plays DESC;

-- Vue pour les meilleurs joueurs
CREATE OR REPLACE VIEW public.top_players AS
SELECT 
    u.id,
    u.email,
    u.first_name,
    u.last_name,
    COUNT(gh.id) as total_games,
    COALESCE(SUM(gh.points_won), 0) as total_points_won,
    COALESCE(SUM(gh.points_won - gh.points_spent), 0) as net_points,
    COUNT(*) FILTER (WHERE gh.is_winning) as winning_games
FROM public.users u
LEFT JOIN public.game_history gh ON u.id = gh.user_id
GROUP BY u.id, u.email, u.first_name, u.last_name
HAVING COUNT(gh.id) > 0
ORDER BY net_points DESC, total_points_won DESC
LIMIT 100;

-- =====================================================
-- PHASE 6: TRIGGERS AUTOMATIQUES
-- =====================================================

-- Trigger pour mettre à jour les statistiques utilisateur
CREATE OR REPLACE FUNCTION public.update_user_game_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour les statistiques dans la table users si nécessaire
    -- (Cette fonction peut être étendue selon les besoins)
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_game_history_change
    AFTER INSERT OR UPDATE OR DELETE ON public.game_history
    FOR EACH ROW
    EXECUTE FUNCTION public.update_user_game_stats();

-- =====================================================
-- PHASE 7: DONNÉES DE TEST (OPTIONNEL)
-- =====================================================

-- Insérer quelques jeux de test si nécessaire
-- (Décommentez si vous voulez des données de test)

/*
INSERT INTO public.game_history (user_id, game_type, points_spent, points_won, is_winning) VALUES
    ('USER_ID_HERE', 'scratch_win', 10, 25, true),
    ('USER_ID_HERE', 'spin_wheel', 10, 0, false),
    ('USER_ID_HERE', 'scratch_win', 10, 15, true);
*/

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
    AND tablename IN ('game_history', 'daily_game_limits')
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
    AND tablename IN ('game_history', 'daily_game_limits')
ORDER BY tablename, cmd;

-- Vérifier les fonctions créées
SELECT 
    'Fonctions créées' as check_type,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
    AND routine_name LIKE '%game%'
ORDER BY routine_name;

-- Message de confirmation
SELECT 'Système de jeux étendu avec succès!' as status;
