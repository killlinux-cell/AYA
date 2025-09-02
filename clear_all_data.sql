-- Script pour vider complètement toutes les données de la base de données Supabase
-- ATTENTION: Ce script supprime TOUTES les données, y compris les utilisateurs authentifiés
-- Exécutez ce script dans l'éditeur SQL de votre projet Supabase

-- 1. Désactiver temporairement RLS pour permettre la suppression
ALTER TABLE public.user_games DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_qr_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.games DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les données des tables dans l'ordre correct (respecter les contraintes de clés étrangères)
-- Commencer par les tables de liaison
DELETE FROM public.user_games;
DELETE FROM public.user_qr_codes;

-- Supprimer les données des tables principales
DELETE FROM public.users;
DELETE FROM public.qr_codes;
DELETE FROM public.games;

-- 3. Supprimer tous les utilisateurs authentifiés
-- Cette commande supprime TOUS les utilisateurs de l'authentification Supabase
DELETE FROM auth.users;

-- 4. Réactiver RLS
ALTER TABLE public.user_games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;

-- 5. Réinitialiser les séquences si elles existent
-- (Pour les colonnes auto-incrémentées, si vous en avez)

-- 6. Vérifier que toutes les tables sont vides
SELECT 'users' as table_name, COUNT(*) as row_count FROM public.users
UNION ALL
SELECT 'qr_codes', COUNT(*) FROM public.qr_codes
UNION ALL
SELECT 'user_qr_codes', COUNT(*) FROM public.user_qr_codes
UNION ALL
SELECT 'games', COUNT(*) FROM public.games
UNION ALL
SELECT 'user_games', COUNT(*) FROM public.user_games
UNION ALL
SELECT 'auth.users', COUNT(*) FROM auth.users;

-- 7. Message de confirmation
SELECT 'Toutes les données ont été supprimées avec succès!' as status;
