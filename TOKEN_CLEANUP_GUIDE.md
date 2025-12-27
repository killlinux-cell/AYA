# 🧹 Guide de Nettoyage des Tokens d'Échange Expirés

## 📋 Problème Résolu

**Problème** : Lorsqu'un utilisateur crée un token d'échange et que le vendeur ne scanne pas le QR code à temps, le token expire mais les points de l'utilisateur ne sont pas restaurés.

**Solution** : Commande de gestion Django pour nettoyer automatiquement les tokens expirés et restaurer les points.

## 🔧 Commande de Nettoyage

### **Fichier créé** : `aya_backend/qr_codes/management/commands/cleanup_expired_tokens.py`

### **Utilisation** :

#### **1. Simulation (dry-run)**
```bash
cd aya_backend
python manage.py cleanup_expired_tokens --dry-run
```
- Affiche les tokens qui seraient nettoyés
- Aucune modification effectuée

#### **2. Nettoyage réel**
```bash
cd aya_backend
python manage.py cleanup_expired_tokens
```
- Restaure les points des utilisateurs
- Supprime les tokens expirés

### **Exemple de sortie** :
```
Trouvé 5 tokens expirés à nettoyer.
Points restaurés pour user@example.com: +100 points
Points restaurés pour user2@example.com: +50 points
Nettoyage terminé:
- 5 tokens supprimés
- 2 utilisateurs concernés
- 150 points restaurés au total
```

## 🚀 Automatisation

### **Tâche Cron (recommandée)**
Ajouter dans le crontab du serveur :
```bash
# Nettoyer les tokens expirés toutes les heures
0 * * * * cd /path/to/aya_backend && python manage.py cleanup_expired_tokens
```

### **Tâche Celery (optionnel)**
Créer une tâche périodique avec Celery Beat pour exécuter automatiquement le nettoyage.

## 📊 Fonctionnalités

### **Ce que fait la commande** :
1. ✅ **Identifie** les tokens expirés et non utilisés
2. ✅ **Restaure** les points aux utilisateurs concernés
3. ✅ **Supprime** les tokens expirés de la base de données
4. ✅ **Affiche** un rapport détaillé des opérations

### **Sécurité** :
- ✅ **Mode dry-run** pour tester avant d'exécuter
- ✅ **Vérifications** avant de restaurer les points
- ✅ **Logs détaillés** de toutes les opérations

## 🎯 Résultat

**Avant** : 
- Token créé → Points retirés
- Token expire → Points perdus ❌

**Après** :
- Token créé → Points retirés
- Token expire → Points restaurés automatiquement ✅

## 📝 Utilisation Recommandée

1. **Exécuter manuellement** après avoir identifié le problème
2. **Configurer une tâche cron** pour l'automatisation
3. **Surveiller les logs** pour vérifier le bon fonctionnement

**Les utilisateurs récupèrent maintenant leurs points automatiquement quand leurs tokens expirent !** 🎊✨
