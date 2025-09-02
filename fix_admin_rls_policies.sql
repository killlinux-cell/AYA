-- 🛠️ SCRIPT DE MISE À JOUR RLS POUR LE PANEL ADMIN
-- Ce script corrige les politiques RLS pour permettre au panneau d'administration
-- d'accéder à toutes les données nécessaires.

-- ÉTAPE 1 : Ajouter une colonne 'role' à la table 'users'
-- Cette colonne permettra de distinguer les utilisateurs normaux des administrateurs.
ALTER TABLE public.users
ADD COLUMN IF NOT EXISTS role TEXT DEFAULT 'user' NOT NULL;

-- ÉTAPE 2 : Créer une fonction pour définir le rôle de l'utilisateur dans le JWT
-- Cette fonction sera appelée par un trigger pour ajouter le rôle de l'utilisateur
-- au jeton JWT lors de la connexion.
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, first_name, last_name, role)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'last_name', 'user')
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    first_name = EXCLUDED.first_name,
    last_name = EXCLUDED.last_name;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer un trigger pour appeler la fonction handle_new_user après l'insertion dans auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Fonction pour ajouter le rôle de l'utilisateur au JWT
CREATE OR REPLACE FUNCTION public.custom_claims(IN user_id uuid, OUT claims jsonb)
LANGUAGE plpgsql SECURITY DEFINER
AS $$
BEGIN
  SELECT jsonb_build_object('user_role', COALESCE(u.role, 'user'))
  INTO claims
  FROM public.users u
  WHERE u.id = user_id;
  
  -- Si l'utilisateur n'existe pas dans public.users, retourner un rôle par défaut
  IF claims IS NULL THEN
    claims := jsonb_build_object('user_role', 'user');
  END IF;
END;
$$;

-- ÉTAPE 3 : Mettre à jour les politiques RLS pour permettre l'accès admin
-- Nous allons modifier les politiques existantes pour inclure une condition
-- permettant aux utilisateurs avec le rôle 'admin' de voir toutes les données.

-- Politique RLS pour la table 'users'
-- Permet aux utilisateurs authentifiés de voir leur propre profil
-- et aux administrateurs de voir tous les profils.
DROP POLICY IF EXISTS "Allow authenticated users to view their own profile" ON public.users;
DROP POLICY IF EXISTS "Allow authenticated users to view their own profile or admin view all" ON public.users;
CREATE POLICY "Allow authenticated users to view their own profile or admin view all" ON public.users
FOR SELECT USING (
  auth.uid() = id 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique RLS pour la table 'qr_codes'
-- Permet à tous les utilisateurs authentifiés de voir les QR codes
-- et aux administrateurs de voir tous les QR codes.
DROP POLICY IF EXISTS "Allow authenticated users to view qr_codes" ON public.qr_codes;
DROP POLICY IF EXISTS "Allow authenticated users to view qr_codes or admin view all" ON public.qr_codes;
CREATE POLICY "Allow authenticated users to view qr_codes or admin view all" ON public.qr_codes
FOR SELECT USING (
  true 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique RLS pour la table 'user_qr_codes'
-- Permet aux utilisateurs authentifiés de voir leurs propres QR codes scannés
-- et aux administrateurs de voir tous les QR codes scannés.
DROP POLICY IF EXISTS "Allow authenticated users to view their own scanned qr codes" ON public.user_qr_codes;
DROP POLICY IF EXISTS "Allow authenticated users to view their own scanned qr codes or admin view all" ON public.user_qr_codes;
CREATE POLICY "Allow authenticated users to view their own scanned qr codes or admin view all" ON public.user_qr_codes
FOR SELECT USING (
  auth.uid() = user_id 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique RLS pour la table 'game_history'
-- Permet aux utilisateurs authentifiés de voir leur propre historique de jeu
-- et aux administrateurs de voir tout l'historique de jeu.
DROP POLICY IF EXISTS "Allow authenticated users to view their own game history" ON public.game_history;
DROP POLICY IF EXISTS "Allow authenticated users to view their own game history or admin view all" ON public.game_history;
CREATE POLICY "Allow authenticated users to view their own game history or admin view all" ON public.game_history
FOR SELECT USING (
  auth.uid() = user_id 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique RLS pour la table 'daily_game_limits'
-- Permet aux utilisateurs authentifiés de voir leurs propres limites de jeu quotidiennes
-- et aux administrateurs de voir toutes les limites de jeu.
DROP POLICY IF EXISTS "Allow authenticated users to view their own daily game limits" ON public.daily_game_limits;
DROP POLICY IF EXISTS "Allow authenticated users to view their own daily game limits or admin view all" ON public.daily_game_limits;
CREATE POLICY "Allow authenticated users to view their own daily game limits or admin view all" ON public.daily_game_limits
FOR SELECT USING (
  auth.uid() = user_id 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique RLS pour la table 'exchange_requests'
-- Permet aux utilisateurs authentifiés de voir leurs propres demandes d'échange
-- et aux administrateurs de voir toutes les demandes d'échange.
DROP POLICY IF EXISTS "Allow authenticated users to view their own exchange requests" ON public.exchange_requests;
DROP POLICY IF EXISTS "Allow authenticated users to view their own exchange requests or admin view all" ON public.exchange_requests;
CREATE POLICY "Allow authenticated users to view their own exchange requests or admin view all" ON public.exchange_requests
FOR SELECT USING (
  auth.uid() = user_id 
  OR EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- ÉTAPE 4 : Mettre à jour les politiques RLS pour les opérations d'écriture (INSERT, UPDATE, DELETE)
-- Les administrateurs devraient avoir un accès complet pour la gestion.

-- Politique pour les administrateurs sur la table 'users'
DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;
CREATE POLICY "Admins can manage all users" ON public.users
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique pour les administrateurs sur la table 'qr_codes'
DROP POLICY IF EXISTS "Admins can manage all qr_codes" ON public.qr_codes;
CREATE POLICY "Admins can manage all qr_codes" ON public.qr_codes
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique pour les administrateurs sur la table 'user_qr_codes'
DROP POLICY IF EXISTS "Admins can manage all user_qr_codes" ON public.user_qr_codes;
CREATE POLICY "Admins can manage all user_qr_codes" ON public.user_qr_codes
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique pour les administrateurs sur la table 'game_history'
DROP POLICY IF EXISTS "Admins can manage all game_history" ON public.game_history;
CREATE POLICY "Admins can manage all game_history" ON public.game_history
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique pour les administrateurs sur la table 'daily_game_limits'
DROP POLICY IF EXISTS "Admins can manage all daily_game_limits" ON public.daily_game_limits;
CREATE POLICY "Admins can manage all daily_game_limits" ON public.daily_game_limits
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- Politique pour les administrateurs sur la table 'exchange_requests'
DROP POLICY IF EXISTS "Admins can manage all exchange_requests" ON public.exchange_requests;
CREATE POLICY "Admins can manage all exchange_requests" ON public.exchange_requests
FOR ALL USING (
  EXISTS (
    SELECT 1 FROM public.users u 
    WHERE u.id = auth.uid() AND u.role = 'admin'
  )
);

-- ÉTAPE 5 : Créer une fonction pour définir un utilisateur comme administrateur
CREATE OR REPLACE FUNCTION public.set_user_as_admin(user_email TEXT)
RETURNS BOOLEAN AS $$
BEGIN
  UPDATE public.users
  SET role = 'admin'
  WHERE email = user_email;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ÉTAPE 6 : Vérification finale des politiques RLS
SELECT
    'Vérification des politiques RLS' as status,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies
WHERE schemaname = 'public'
    AND tablename IN ('users', 'qr_codes', 'user_qr_codes', 'game_history', 'daily_game_limits', 'exchange_requests')
ORDER BY tablename, policyname;

-- Vérification de la colonne 'role'
SELECT
    'Vérification de la colonne role' as status,
    column_name,
    data_type,
    column_default
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'role';

-- Afficher les utilisateurs actuels et leurs rôles
SELECT
    'Utilisateurs actuels' as status,
    id,
    email,
    first_name,
    last_name,
    role,
    created_at
FROM public.users
ORDER BY created_at DESC;

