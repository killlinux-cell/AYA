-- Ajout de la table des demandes d'échange
CREATE TABLE IF NOT EXISTS public.exchange_requests (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    points INTEGER NOT NULL,
    exchange_code TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_completed BOOLEAN DEFAULT false,
    completed_at TIMESTAMP WITH TIME ZONE,
    vendor_id UUID, -- ID du vendeur qui a confirmé l'échange
    notes TEXT -- Notes optionnelles du vendeur
);

-- Index pour optimiser les requêtes
CREATE INDEX IF NOT EXISTS idx_exchange_requests_user_id ON public.exchange_requests(user_id);
CREATE INDEX IF NOT EXISTS idx_exchange_requests_exchange_code ON public.exchange_requests(exchange_code);
CREATE INDEX IF NOT EXISTS idx_exchange_requests_created_at ON public.exchange_requests(created_at);

-- RLS pour la table exchange_requests
ALTER TABLE public.exchange_requests ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux utilisateurs de voir leurs propres échanges
CREATE POLICY "Users can view their own exchange requests" ON public.exchange_requests
    FOR SELECT USING (auth.uid() = user_id);

-- Politique pour permettre aux utilisateurs de créer leurs propres échanges
CREATE POLICY "Users can create their own exchange requests" ON public.exchange_requests
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour permettre aux vendeurs de voir tous les échanges (à adapter selon vos besoins)
CREATE POLICY "Vendors can view all exchange requests" ON public.exchange_requests
    FOR SELECT USING (true);

-- Politique pour permettre aux vendeurs de mettre à jour les échanges
CREATE POLICY "Vendors can update exchange requests" ON public.exchange_requests
    FOR UPDATE USING (true);

-- Fonction pour automatiquement déduire les points lors de la confirmation d'un échange
CREATE OR REPLACE FUNCTION process_exchange_confirmation()
RETURNS TRIGGER AS $$
BEGIN
    -- Si l'échange vient d'être complété
    IF NEW.is_completed = true AND OLD.is_completed = false THEN
        -- Mettre à jour les points de l'utilisateur
        UPDATE public.users 
        SET 
            available_points = available_points - NEW.points,
            exchanged_points = exchanged_points + NEW.points
        WHERE id = NEW.user_id;
        
        -- Mettre à jour la date de completion
        NEW.completed_at = NOW();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour automatiser la déduction des points
CREATE TRIGGER trigger_exchange_confirmation
    BEFORE UPDATE ON public.exchange_requests
    FOR EACH ROW
    EXECUTE FUNCTION process_exchange_confirmation();

-- Vue pour les statistiques d'échange
CREATE OR REPLACE VIEW exchange_statistics AS
SELECT 
    u.id as user_id,
    u.first_name,
    u.last_name,
    u.email,
    COUNT(er.id) as total_exchanges,
    SUM(CASE WHEN er.is_completed THEN er.points ELSE 0 END) as total_points_exchanged,
    SUM(CASE WHEN NOT er.is_completed THEN er.points ELSE 0 END) as pending_points,
    MAX(er.created_at) as last_exchange_date
FROM public.users u
LEFT JOIN public.exchange_requests er ON u.id = er.user_id
GROUP BY u.id, u.first_name, u.last_name, u.email;

-- Fonction pour obtenir les statistiques d'un utilisateur
CREATE OR REPLACE FUNCTION get_user_exchange_stats(user_uuid UUID)
RETURNS TABLE(
    total_exchanges BIGINT,
    completed_exchanges BIGINT,
    pending_exchanges BIGINT,
    total_points_exchanged BIGINT,
    pending_points BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(er.id) as total_exchanges,
        COUNT(CASE WHEN er.is_completed THEN 1 END) as completed_exchanges,
        COUNT(CASE WHEN NOT er.is_completed THEN 1 END) as pending_exchanges,
        SUM(CASE WHEN er.is_completed THEN er.points ELSE 0 END) as total_points_exchanged,
        SUM(CASE WHEN NOT er.is_completed THEN er.points ELSE 0 END) as pending_points
    FROM public.exchange_requests er
    WHERE er.user_id = user_uuid;
END;
$$ LANGUAGE plpgsql;
