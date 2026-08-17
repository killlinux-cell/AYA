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
cp "$AYA/qr_codes/world_cup_bracket_data.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_match_sync.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/sarci_knowledge.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/sarci_chat.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/chat_views.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/world_cup_dashboard.py" "$BACKEND/qr_codes/"
cp "$AYA/qr_codes/migrations/0009_world_cup.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/migrations/0010_world_cup_bracket.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/migrations/0011_world_cup_bracket_state.py" "$BACKEND/qr_codes/migrations/"
cp "$AYA/qr_codes/migrations/0012_world_cup_match_bracket_code.py" "$BACKEND/qr_codes/migrations/"
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
cp "$AYA/dashboard/templates/dashboard/qr_codes.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/bulk_operations.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/games.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_bracket.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/games.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_form.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_match_detail.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/world_cup_predictions.html" "$BACKEND/dashboard/templates/dashboard/"
mkdir -p "$BACKEND/dashboard/templates/dashboard/partials"
cp "$AYA/dashboard/templates/dashboard/partials/"*.html "$BACKEND/dashboard/templates/dashboard/partials/" 2>/dev/null || true

echo "=== 4b. Publicités (bannière + vidéos) ==="
cp "$AYA/dashboard/views_ads.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/models_ads.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/serializers_ads.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/urls_api.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/migrations/0002_videoadvertisement.py" "$BACKEND/dashboard/migrations/" 2>/dev/null || true
cp "$AYA/dashboard/migrations/0003_homebanner.py" "$BACKEND/dashboard/migrations/" 2>/dev/null || true
cp "$AYA/dashboard/templates/dashboard/advertisements.html" "$BACKEND/dashboard/templates/dashboard/" 2>/dev/null || true
cp "$AYA/dashboard/templates/dashboard/create_advertisement.html" "$BACKEND/dashboard/templates/dashboard/" 2>/dev/null || true
cp "$AYA/dashboard/templates/dashboard/home_banner.html" "$BACKEND/dashboard/templates/dashboard/" 2>/dev/null || true

echo "=== 4c. Recettes (vidéos indépendantes des pubs) ==="
cp "$AYA/dashboard/models_recipes.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/views_recipes.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/migrations/0004_recipevideo.py" "$BACKEND/dashboard/migrations/" 2>/dev/null || true
cp "$AYA/dashboard/urls.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/urls_api.py" "$BACKEND/dashboard/"
cp "$AYA/dashboard/templates/dashboard/recipes.html" "$BACKEND/dashboard/templates/dashboard/"
cp "$AYA/dashboard/templates/dashboard/create_recipe.html" "$BACKEND/dashboard/templates/dashboard/"

echo "=== 5. Settings ==="
cp "$AYA/aya_project/settings.py" "$BACKEND/aya_project/settings.py"
test -f /root/.env.aya.backup && cp /root/.env.aya.backup "$BACKEND/.env" || true

echo "=== 6. Vérification ==="
grep -q "world_cup_bracket_api" "$BACKEND/dashboard/urls.py" && echo "OK bracket API" || { echo "ERREUR bracket API"; exit 1; }
test -f "$BACKEND/dashboard/templates/dashboard/games.html" && grep -q "aya-games-skin" "$BACKEND/dashboard/templates/dashboard/games.html" && echo "OK skin jeux" || { echo "ERREUR games.html"; exit 1; }
grep -q "chat_message" "$BACKEND/qr_codes/urls.py" && echo "OK chat SARCI" || { echo "ERREUR chat API"; exit 1; }
test -f "$BACKEND/dashboard/templates/dashboard/qr_codes.html" && grep -q "deleteAllQRModal" "$BACKEND/dashboard/templates/dashboard/qr_codes.html" && echo "OK suppression QR" || { echo "ERREUR qr_codes.html"; exit 1; }
test -f "$BACKEND/dashboard/templates/dashboard/world_cup_bracket.html" && echo "OK tableau" || { echo "ERREUR template tableau"; exit 1; }

echo "=== 7. Migration + données CDM ==="
cd "$BACKEND"
source venv/bin/activate
python manage.py migrate qr_codes
python manage.py migrate dashboard
python manage.py sync_world_cup_matches
python manage.py seed_world_cup_bracket 2>/dev/null || true
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
HTTP3=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/api/advertisements/banner/")
echo "HTTP /api/advertisements/banner/ = $HTTP3"
HTTP4=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8000/api/advertisements/active/")
echo "HTTP /api/advertisements/active/ = $HTTP4"

rm -rf "$SRC"
echo ""
echo "=== TERMINÉ ==="
echo "1. Tableau: https://monuniversaya.com/dashboard/world-cup/"
echo "2. Pronostics: https://monuniversaya.com/dashboard/games/?tab=pronostics"
echo "3. Matchs: https://monuniversaya.com/dashboard/world-cup/matches/"
echo "4. Ctrl+F5 pour vider le cache"
echo ""
echo "=== 10. Nginx upload (bannière / vidéo, fix 413) ==="
NGINX_SITE=""
for f in /etc/nginx/sites-enabled/*monuniversaya* /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/aya*; do
  [ -f "$f" ] && NGINX_SITE="$f" && break
done
if [ -n "$NGINX_SITE" ]; then
  if grep -q "client_max_body_size" "$NGINX_SITE"; then
    sed -i 's/client_max_body_size.*/client_max_body_size 100M;/' "$NGINX_SITE"
    echo "OK client_max_body_size mis à jour dans $NGINX_SITE"
  else
    sed -i '/server_name/a \    client_max_body_size 100M;' "$NGINX_SITE" 2>/dev/null || \
    sed -i '/listen 443/a \    client_max_body_size 100M;' "$NGINX_SITE" 2>/dev/null || \
    echo "ATTENTION: ajoutez manuellement client_max_body_size 100M; dans $NGINX_SITE"
  fi
  nginx -t && systemctl reload nginx && echo "OK nginx rechargé" || echo "ERREUR nginx -t"
else
  echo "ATTENTION: config nginx introuvable — voir aya_backend/nginx_upload_fix.conf"
fi
