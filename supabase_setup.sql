-- Configuration de la base de données Supabase pour Aya Huile App

-- Table des utilisateurs
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  available_points INTEGER DEFAULT 0,
  exchanged_points INTEGER DEFAULT 0,
  collected_qr_codes INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table des codes QR
CREATE TABLE qr_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  description TEXT,
  points INTEGER DEFAULT 10,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison utilisateur-codes QR
CREATE TABLE user_qr_codes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  qr_code_id UUID REFERENCES qr_codes(id) ON DELETE CASCADE,
  collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  points_earned INTEGER NOT NULL,
  UNIQUE(user_id, qr_code_id)
);

-- Table des jeux
CREATE TABLE games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  points_cost INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Table de liaison utilisateur-jeux
CREATE TABLE user_games (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  game_id UUID REFERENCES games(id) ON DELETE CASCADE,
  played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  score INTEGER,
  points_earned INTEGER DEFAULT 0,
  UNIQUE(user_id, game_id)
);

-- RLS (Row Level Security) - Sécurité au niveau des lignes
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_qr_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE games ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_games ENABLE ROW LEVEL SECURITY;

-- Politiques de sécurité pour les utilisateurs
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Politiques de sécurité pour les codes QR
CREATE POLICY "Anyone can view active QR codes" ON qr_codes
  FOR SELECT USING (is_active = true);

-- Politiques de sécurité pour user_qr_codes
CREATE POLICY "Users can view own QR codes" ON user_qr_codes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own QR codes" ON user_qr_codes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiques de sécurité pour les jeux
CREATE POLICY "Anyone can view active games" ON games
  FOR SELECT USING (is_active = true);

-- Politiques de sécurité pour user_games
CREATE POLICY "Users can view own games" ON user_games
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own games" ON user_games
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Fonction pour mettre à jour automatiquement les statistiques utilisateur
CREATE OR REPLACE FUNCTION update_user_stats()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE users 
    SET 
      available_points = available_points + NEW.points_earned,
      collected_qr_codes = collected_qr_codes + 1
    WHERE id = NEW.user_id;
    RETURN NEW;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Déclencheur pour mettre à jour automatiquement les statistiques
CREATE TRIGGER trigger_update_user_stats
  AFTER INSERT ON user_qr_codes
  FOR EACH ROW
  EXECUTE FUNCTION update_user_stats();

-- Insertion de quelques codes QR de test
INSERT INTO qr_codes (code, description, points) VALUES
  ('AYA_WELCOME', 'Bienvenue chez Aya Huile', 20),
  ('AYA_PRODUIT_1', 'Huile d''olive extra vierge', 15),
  ('AYA_PRODUIT_2', 'Huile d''argan', 25),
  ('AYA_PRODUIT_3', 'Huile de noix de coco', 18),
  ('AYA_PROMO_1', 'Promotion spéciale', 30);

-- Insertion de quelques jeux de test
INSERT INTO games (name, description, points_cost) VALUES
  ('Quiz Huiles', 'Testez vos connaissances sur les huiles', 0),
  ('Memory Game', 'Jeu de mémoire avec les produits', 5),
  ('Spin & Win', 'Tournez la roue pour gagner des points', 10);
