#!/bin/bash
# Déploie le code Coupe du Monde complet vers /var/www/aya_backend
# Usage sur le VPS: bash deploy_world_cup_vps.sh

set -e

BACKEND="/var/www/aya_backend"
SRC="/tmp/AYA_deploy"

echo "=== 1. Clone AYA (dernière version GitHub) ==="
rm -rf "$SRC"
git clone --depth 1 https://github.com/killlinux-cell/AYA.git "$SRC"
AYA="$SRC/aya_backend"

echo "=== 2. Sauvegarde .env et base ==="
cp "$BACKEND/.env" /root/.env.aya.backup 2>/dev/null || true
cp "$BACKEND/db.sqlite3" /root/db.sqlite3.before_deploy.$(date +%F_%H%M) 2>/dev/null || true

echo "=== 3. API Coupe du Monde ==="
cp "$AYA/qr_codes/models_world_cup.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_scoring.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_views.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_flags.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_bracket.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_dashboard.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/migrations/0009_world_cup.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/migrations/0010_world_cup_bracket.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/urls.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/admin.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/models.py" "$BACKEND/qr_codes/"
mkdir -p "$BACKEND/qr_codes/management/commands"
cp "$AYA/qr_codes/management/commands/"*.py "$BACKEND/qr_codes/management/commands/" 2>/dev/null || true
touch "$BACKEND/qr_codes/management/__init__.py"
touch "$BACKEND/qr_codes/management/commands/__init__.py"

echo "=== 4. Dashboard (Jeux + CDM + tableau) ==="
cp "$AYA/dashboard/views.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/urls.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/app_version_views.py" "$BACKEND/dashboard/" 2>/dev/null || true
mkdir -p "$BACKEND/dashboard/templatetags"
cp "$AYA/dashboard/templatetags/world_cup_tags.py" "$BACKEND/dashboard/templatetags/" 2>/dev/null || true
touch "$BACKEND/dashboard/templatetags/__init__.py" 2>/dev/null || true
cp "$AYA/dashboard/templates/dashboard/base.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/games.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_bracket.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_form.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_detail.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_predictions.html" "$BACKEND/dashboard/templates/dashboard/"
mkdir -p "$BACKEND/dashboard/templates/dashboard/partials"
cp "$AYA/dashboard/templates/dashboard/partials/"*.html "$BACKEND/dashboard/templates/dashboard/partials/" 2>/dev/null || true

echo "=== 5. Settings ==="
cp "$AYA/aya_project/settings.py" "$BACKEND/aya_project/settings.py"
test -f /root/.env.aya.backup && cp /root/.env.aya.backup "$BACKEND/.env" || true

echo "=== 6. Vérification ==="
grep -q "world_cup_bracket" "$BACKEND/dashboard/urls.py" && echo "OK bracket urls" || { echo "ERREUR bracket urls"; exit 1; }
grep -q "POINTS_EXACT = 10" "$BACKEND/qr_codes/world_cup_scoring.py" && echo "OK barème 10/5/1" || { echo "ERREUR scoring"; exit 1; }
test -f "$BACKEND/dashboard/templates/dashboard/world_cup_bracket.html" && echo "OK tableau" || { echo "ERREUR template tableau"; exit 1; }

echo "=== 7. Migration + données CDM ==="
cd "$BACKEND"
source venv/bin/activate
python manage.py migrate qr_codes
python manage.py seed_world_cup_bracket
python manage.py recalculate_world_cup_points

echo "=== 8. Redémarrage Gunicorn ==="
if systemctl list-units --type=service | grep -q aya_backend; then
  systemctl restart aya_backend
elif systemctl list-units --type=service | grep -q gunicorn; then
  systemctl restart gunicorn
else
  GUNICORN_PID=$(pgrep -f "gunicorn.*wsgi" | head -1)
  if [ -n "$GUNICORN_PID" ]; then
    kill -HUP "$GUNICORN_PID"
  else
    echo "ATTENTION: redémarrez Django manuellement"
  fi
fi

sleep 3

echo "=== 9. Tests ==="
curl -s http://127.0.0.1:8000/api/ | grep -q world_cup && echo "OK API world_cup" || echo "ERREUR API"
HTTP=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8000/dashboard/world-cup/)
echo "HTTP /dashboard/world-cup/ = $HTTP"
HTTP2=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/dashboard/games/?tab=pronostics")
echo "HTTP /dashboard/games/?tab=pronostics = $HTTP2"

rm -rf "$SRC"
echo ""
echo "=== TERMINÉ ==="
echo "1. Tableau: https://monuniversaya.com/dashboard/world-cup/"
echo "2. Pronostics: https://monuniversaya.com/dashboard/games/?tab=pronostics"
echo "3. Matchs: https://monuniversaya.com/dashboard/world-cup/matches/"
echo "4. Ctrl+F5 pour vider le cache"
