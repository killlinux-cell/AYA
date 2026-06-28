#!/bin/bash
# Déploie TOUT le code Coupe du Monde depuis AYA vers /var/www/aya_backend
# Usage sur le VPS: bash deploy_world_cup_vps.sh

set -e

BACKEND="/var/www/aya_backend"
SRC="/tmp/AYA_deploy"

echo "=== 1. Clone AYA (dernière version GitHub) ==="
rm -rf "$SRC"
git clone --depth 1 https://github.com/killlinux-cell/AYA.git "$SRC"
AYA="$SRC/aya_backend"

echo "=== 2. Sauvegarde .env et base (sans écraser) ==="
cp "$BACKEND/.env" /root/.env.aya.backup 2>/dev/null || true
cp "$BACKEND/db.sqlite3" /root/db.sqlite3.before_deploy.$(date +%F_%H%M) 2>/dev/null || true

echo "=== 3. API Coupe du Monde ==="
cp "$AYA/qr_codes/models_world_cup.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_scoring.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_views.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/migrations/0009_world_cup.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/urls.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/admin.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/models.py" "$BACKEND/qr_codes/"
mkdir -p "$BACKEND/qr_codes/management/commands"
cp "$AYA/qr_codes/management/commands/seed_world_cup.py" "$BACKEND/qr_codes/management/commands/" 2>/dev/null || true
touch "$BACKEND/qr_codes/management/__init__.py"
touch "$BACKEND/qr_codes/management/commands/__init__.py"

echo "=== 4. Dashboard Coupe du Monde (gestion complète) ==="
cp "$AYA/dashboard/views.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/urls.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/templates/dashboard/base.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_form.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_detail.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_predictions.html" "$BACKEND/dashboard/templates/dashboard/"

echo "=== 5. Vérification fichiers copiés ==="
grep -q "world_cup_create" "$BACKEND/dashboard/urls.py" && echo "OK urls.py" || { echo "ERREUR urls.py"; exit 1; }
test -f "$BACKEND/dashboard/templates/dashboard/world_cup_match_form.html" && echo "OK formulaire" || { echo "ERREUR template"; exit 1; }
test -f "$BACKEND/qr_codes/world_cup_views.py" && echo "OK API" || { echo "ERREUR API"; exit 1; }

echo "=== 6. Migration ==="
cd "$BACKEND"
source venv/bin/activate
python manage.py migrate qr_codes
python manage.py seed_world_cup 2>/dev/null || echo "(seed ignoré si matchs existent)"

echo "=== 7. Redémarrage Gunicorn/Django ==="
if systemctl list-units --type=service | grep -q aya_backend; then
  systemctl restart aya_backend
  echo "Service aya_backend redémarré"
elif systemctl list-units --type=service | grep -q gunicorn; then
  systemctl restart gunicorn
  echo "Service gunicorn redémarré"
else
  echo "ATTENTION: redémarrez le service Django manuellement"
  systemctl list-units --type=service | grep -iE "aya|gunicorn|django" || true
fi

sleep 3

echo "=== 8. Tests locaux ==="
curl -s http://127.0.0.1:8000/api/ | grep -q world_cup && echo "OK: /api/ contient world_cup" || echo "ERREUR: API sans world_cup"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/dashboard/world-cup/create/)
echo "HTTP /dashboard/world-cup/create/ = $HTTP (302=login OK, 200=OK, 404=échec)"

rm -rf "$SRC"
echo ""
echo "=== TERMINÉ ==="
echo "1. Ouvrez https://monuniversaya.com/dashboard/world-cup/"
echo "2. Ctrl+F5 pour vider le cache"
echo "3. Bouton 'Nouveau match' → /dashboard/world-cup/create/"
