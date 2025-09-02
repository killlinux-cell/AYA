-- Script pour corriger la synchronisation entre auth.users et public.users
-- Ce script résout le problème où vous pouvez vous connecter mais ne voyez pas les utilisateurs

-- 1. Désactiver temporairement RLS
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. Créer les entrées manquantes dans public.users pour les utilisateurs auth existants
INSERT INTO public.users (id, email, first_name, last_name, available_points, exchanged_points, collected_qr_codes, created_at, last_login_at)
SELECT 
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'first_name', ''),
    COALESCE(au.raw_user_meta_data->>'last_name', ''),
    0,
    0,
    0,
    au.created_at,
    COALESCE(au.last_sign_in_at, au.created_at)
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 3. Mettre à jour les utilisateurs existants avec les dernières informations
UPDATE public.users 
SET 
    email = au.email,
    last_login_at = COALESCE(au.last_sign_in_at, public.users.last_login_at),
    first_name = COALESCE(au.raw_user_meta_data->>'first_name', public.users.first_name),
    last_name = COALESCE(au.raw_user_meta_data->>'last_name', public.users.last_name)
FROM auth.users au
WHERE public.users.id = au.id;

-- 4. Réactiver RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5. Vérifier le résultat
SELECT 
    'Synchronisation terminée' as status,
    COUNT(*) as total_users_in_public
FROM public.users;

-- 6. Afficher les utilisateurs synchronisés
SELECT 
    id,
    email,
    first_name,
    last_name,
    available_points,
    created_at,
    last_login_at
FROM public.users
ORDER BY created_at DESC;
