#!/bin/bash
# Déploie le code Coupe du Monde depuis le repo AYA vers /var/www/aya_backend
# Usage: bash deploy_world_cup_vps.sh

set -e

BACKEND="/var/www/aya_backend"
SRC="/tmp/AYA_deploy"

echo "=== 1. Clone AYA (dernière version) ==="
rm -rf "$SRC"
git clone --depth 1 https://github.com/killlinux-cell/AYA.git "$SRC"

echo "=== 2. Sauvegarde .env et base ==="
cp "$BACKEND/.env" /root/.env.aya.backup 2>/dev/null || true
cp "$BACKEND/db.sqlite3" /root/db.sqlite3.before_deploy.$(date +%F_%H%M) 2>/dev/null || true

echo "=== 3. Copie fichiers CDM (API) ==="
cp "$SRC/aya_backend/qr_codes/models_world_cup.py" "$BACKEND/qr_codes/"
cp "$SRC/aya_backend/qr_codes/world_cup_scoring.py" "$BACKEND/qr_codes/"
cp "$SRC/aya_backend/qr_codes/world_cup_views.py" "$BACKEND/qr_codes/"
cp "$SRC/aya_backend/qr_codes/migrations/0009_world_cup.py" "$BACKEND/qr_codes/migrations/"
cp "$SRC/aya_backend/qr_codes/urls.py" "$BACKEND/qr_codes/"
cp "$SRC/aya_backend/qr_codes/admin.py" "$BACKEND/qr_codes/"
cp "$SRC/aya_backend/qr_codes/models.py" "$BACKEND/qr_codes/"
mkdir -p "$BACKEND/qr_codes/management/commands"
cp "$SRC/aya_backend/qr_codes/management/commands/seed_world_cup.py" "$BACKEND/qr_codes/management/commands/" 2>/dev/null || true
touch "$BACKEND/qr_codes/management/__init__.py" "$BACKEND/qr_codes/management/commands/__init__.py"

echo "=== 4. Copie fichiers Dashboard CDM ==="
cp "$SRC/aya_backend/dashboard/views.py" "$BACKEND/dashboard/"
cp "$SRC/aya_backend/dashboard/urls.py" "$BACKEND/dashboard/"
cp "$SRC/aya_backend/dashboard/templates/dashboard/base.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$SRC/aya_backend/dashboard/templates/dashboard/world_cup.html" "$BACKEND/dashboard/templates/dashboard/"

echo "=== 5. Migration + matchs ==="
cd "$BACKEND"
source venv/bin/activate
python manage.py migrate qr_codes
python manage.py seed_world_cup 2>/dev/null || echo "(seed ignoré si matchs existent)"

echo "=== 6. Redémarrage ==="
systemctl restart aya_backend 2>/dev/null || systemctl restart gunicorn 2>/dev/null || echo "Redémarrez le service manuellement"

echo "=== 7. Vérification ==="
sleep 2
curl -s http://127.0.0.1:8000/api/ | grep -q world_cup && echo "OK: API world_cup présente" || echo "ERREUR: API world_cup absente"
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/dashboard/world-cup/ | grep -qE "200|302" && echo "OK: Dashboard world-cup accessible" || echo "ERREUR: Dashboard world-cup 404"

rm -rf "$SRC"
echo "=== Terminé ==="
echo "Ouvrez: https://monuniversaya.com/dashboard/world-cup/"
echo "Menu: Coupe du Monde dans la barre latérale (Ctrl+F5 pour vider le cache)"
