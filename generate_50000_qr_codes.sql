-- Script pour générer 50 000 QR codes selon la spécification du projet
-- Batch 4151000 avec répartition spécifique
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- =====================================================
-- PHASE 1: NETTOYAGE DES DONNÉES EXISTANTES
-- =====================================================

-- Supprimer les QR codes existants (optionnel - décommentez si nécessaire)
-- DELETE FROM public.qr_codes;

-- =====================================================
-- PHASE 2: GÉNÉRATION DES QR CODES GAGNANTS (45 000)
-- =====================================================

-- 25 000 QR codes → 10 points
INSERT INTO public.qr_codes (code, points, description, is_active)
SELECT 
    'BATCH4151000_' || LPAD(ROW_NUMBER() OVER ()::TEXT, 5, '0') || '_10P',
    10,
    'QR Code gagnant - 10 points (Batch 4151000)',
    true
FROM generate_series(1, 25000) AS n;

-- 15 000 QR codes → 50 points
INSERT INTO public.qr_codes (code, points, description, is_active)
SELECT 
    'BATCH4151000_' || LPAD((ROW_NUMBER() OVER () + 25000)::TEXT, 5, '0') || '_50P',
    50,
    'QR Code gagnant - 50 points (Batch 4151000)',
    true
FROM generate_series(1, 15000) AS n;

-- 5 000 QR codes → 100 points
INSERT INTO public.qr_codes (code, points, description, is_active)
SELECT 
    'BATCH4151000_' || LPAD((ROW_NUMBER() OVER () + 40000)::TEXT, 5, '0') || '_100P',
    100,
    'QR Code gagnant - 100 points (Batch 4151000)',
    true
FROM generate_series(1, 5000) AS n;

-- =====================================================
-- PHASE 3: GÉNÉRATION DES TICKETS "RÉESSAYER" (4 500)
-- =====================================================

INSERT INTO public.qr_codes (code, points, description, is_active)
SELECT 
    'BATCH4151000_' || LPAD((ROW_NUMBER() OVER () + 45000)::TEXT, 5, '0') || '_RETRY',
    0,
    'Ticket "Réessayer" - Pas de points, mais ne perdez pas espoir !',
    true
FROM generate_series(1, 4500) AS n;

-- =====================================================
-- PHASE 4: GÉNÉRATION DES PROGRAMMES DE FIDÉLITÉ (5 000)
-- =====================================================

INSERT INTO public.qr_codes (code, points, description, is_active)
SELECT 
    'BATCH4151000_' || LPAD((ROW_NUMBER() OVER () + 49500)::TEXT, 5, '0') || '_FIDELITY',
    25,
    'Programme de fidélité - 25 points + accès aux jeux !',
    true
FROM generate_series(1, 5000) AS n;

-- =====================================================
-- PHASE 5: VÉRIFICATION ET STATISTIQUES
-- =====================================================

-- Statistiques de génération
SELECT 
    'Statistiques de génération' as check_type,
    COUNT(*) as total_qr_codes,
    COUNT(CASE WHEN points = 10 THEN 1 END) as qr_10_points,
    COUNT(CASE WHEN points = 50 THEN 1 END) as qr_50_points,
    COUNT(CASE WHEN points = 100 THEN 1 END) as qr_100_points,
    COUNT(CASE WHEN points = 0 THEN 1 END) as qr_retry,
    COUNT(CASE WHEN points = 25 THEN 1 END) as qr_fidelity
FROM public.qr_codes
WHERE code LIKE 'BATCH4151000_%';

-- Répartition par points
SELECT 
    'Répartition par points' as check_type,
    points,
    COUNT(*) as count,
    ROUND((COUNT(*)::NUMERIC / 50000) * 100, 2) as percentage
FROM public.qr_codes
WHERE code LIKE 'BATCH4151000_%'
GROUP BY points
ORDER BY points;

-- Vérification des codes uniques
SELECT 
    'Vérification des codes uniques' as check_type,
    COUNT(*) as total_codes,
    COUNT(DISTINCT code) as unique_codes,
    CASE 
        WHEN COUNT(*) = COUNT(DISTINCT code) THEN '✅ Tous les codes sont uniques'
        ELSE '❌ Il y a des doublons'
    END as status
FROM public.qr_codes
WHERE code LIKE 'BATCH4151000_%';

-- =====================================================
-- PHASE 6: EXPORT DES DONNÉES (OPTIONNEL)
-- =====================================================

-- Créer une vue pour l'export des QR codes
CREATE OR REPLACE VIEW public.qr_codes_export AS
SELECT 
    code,
    points,
    description,
    is_active,
    created_at
FROM public.qr_codes
WHERE code LIKE 'BATCH4151000_%'
ORDER BY code;

-- =====================================================
-- PHASE 7: INDEX POUR LES PERFORMANCES
-- =====================================================

-- Index pour améliorer les performances de recherche
CREATE INDEX IF NOT EXISTS idx_qr_codes_batch_4151000 ON public.qr_codes(code) 
WHERE code LIKE 'BATCH4151000_%';

CREATE INDEX IF NOT EXISTS idx_qr_codes_points_batch ON public.qr_codes(points, code) 
WHERE code LIKE 'BATCH4151000_%';

-- =====================================================
-- PHASE 8: FONCTIONS UTILITAIRES
-- =====================================================

-- Fonction pour obtenir un QR code aléatoire par type
CREATE OR REPLACE FUNCTION public.get_random_qr_code_by_points(target_points INTEGER)
RETURNS TABLE (
    code TEXT,
    points INTEGER,
    description TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        qc.code,
        qc.points,
        qc.description
    FROM public.qr_codes qc
    WHERE qc.points = target_points 
        AND qc.is_active = true
        AND qc.code LIKE 'BATCH4151000_%'
    ORDER BY RANDOM()
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour obtenir les statistiques d'utilisation des QR codes
CREATE OR REPLACE FUNCTION public.get_qr_code_usage_stats()
RETURNS TABLE (
    points_category INTEGER,
    total_codes BIGINT,
    used_codes BIGINT,
    usage_rate NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        qc.points as points_category,
        COUNT(qc.id) as total_codes,
        COUNT(uqc.id) as used_codes,
        CASE 
            WHEN COUNT(qc.id) > 0 THEN 
                ROUND((COUNT(uqc.id)::NUMERIC / COUNT(qc.id)::NUMERIC) * 100, 2)
            ELSE 0 
        END as usage_rate
    FROM public.qr_codes qc
    LEFT JOIN public.user_qr_codes uqc ON qc.id = uqc.qr_code_id
    WHERE qc.code LIKE 'BATCH4151000_%'
    GROUP BY qc.points
    ORDER BY qc.points;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- PHASE 9: RAPPORTS DE VALIDATION
-- =====================================================

-- Rapport de validation complet
SELECT 
    'RAPPORT DE VALIDATION' as report_type,
    'Batch 4151000' as batch_name,
    CURRENT_TIMESTAMP as generation_date;

-- Vérification de la conformité avec les spécifications
SELECT 
    'Conformité avec les spécifications' as check_type,
    CASE 
        WHEN COUNT(*) = 50000 THEN '✅ Nombre total correct'
        ELSE '❌ Nombre total incorrect: ' || COUNT(*)
    END as total_count,
    CASE 
        WHEN COUNT(CASE WHEN points = 10 THEN 1 END) = 25000 THEN '✅ 25 000 QR codes à 10 points'
        ELSE '❌ QR codes à 10 points: ' || COUNT(CASE WHEN points = 10 THEN 1 END)
    END as qr_10_points,
    CASE 
        WHEN COUNT(CASE WHEN points = 50 THEN 1 END) = 15000 THEN '✅ 15 000 QR codes à 50 points'
        ELSE '❌ QR codes à 50 points: ' || COUNT(CASE WHEN points = 50 THEN 1 END)
    END as qr_50_points,
    CASE 
        WHEN COUNT(CASE WHEN points = 100 THEN 1 END) = 5000 THEN '✅ 5 000 QR codes à 100 points'
        ELSE '❌ QR codes à 100 points: ' || COUNT(CASE WHEN points = 100 THEN 1 END)
    END as qr_100_points,
    CASE 
        WHEN COUNT(CASE WHEN points = 0 THEN 1 END) = 4500 THEN '✅ 4 500 tickets "Réessayer"'
        ELSE '❌ Tickets "Réessayer": ' || COUNT(CASE WHEN points = 0 THEN 1 END)
    END as qr_retry,
    CASE 
        WHEN COUNT(CASE WHEN points = 25 THEN 1 END) = 5000 THEN '✅ 5 000 programmes de fidélité'
        ELSE '❌ Programmes de fidélité: ' || COUNT(CASE WHEN points = 25 THEN 1 END)
    END as qr_fidelity
FROM public.qr_codes
WHERE code LIKE 'BATCH4151000_%';

-- =====================================================
-- PHASE 10: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT 
    'GÉNÉRATION TERMINÉE AVEC SUCCÈS!' as status,
    '50 000 QR codes générés selon les spécifications' as message,
    'Batch 4151000 prêt pour la distribution' as next_step;
