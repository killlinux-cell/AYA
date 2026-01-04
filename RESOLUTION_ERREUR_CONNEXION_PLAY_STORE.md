# 🔧 Résolution Erreur de Connexion - Tests Play Store

## ❌ Problème Identifié

**Erreur** : "Erreur de connexion - Problème de connexion. Vérifiez votre internet et réessayez."

**Contexte** : L'application fonctionnait en développement local mais ne se connecte plus au backend lors des tests Play Store.

---

## 🔍 Causes Possibles

### 1. **Backend Non Accessible depuis Internet** ⚠️ CRITIQUE

Le serveur `https://monuniversaya.com` doit être :
- ✅ **Déployé et accessible** depuis Internet
- ✅ **Certificat SSL valide** (HTTPS)
- ✅ **Port 443 ouvert** (HTTPS)
- ✅ **Firewall configuré** pour accepter les connexions

### 2. **Configuration CORS Incorrecte**

Le backend doit autoriser les requêtes depuis l'application mobile.

### 3. **ALLOWED_HOSTS Non Configuré**

Le backend doit accepter les requêtes depuis le domaine.

---

## ✅ Solutions

### Solution 1 : Vérifier que le Backend est Accessible

#### Test 1 : Vérifier depuis un Navigateur

1. **Ouvrez votre navigateur**
2. **Allez sur** : `https://monuniversaya.com`
3. **Vérifiez** :
   - ✅ Le site charge-t-il ?
   - ✅ Y a-t-il un certificat SSL valide (cadenas vert) ?
   - ✅ Pas d'erreur de certificat ?

#### Test 2 : Tester l'API

1. **Testez l'endpoint de santé** :
   ```
   https://monuniversaya.com/api/
   ```
   
2. **Testez l'endpoint d'authentification** :
   ```
   https://monuniversaya.com/api/auth/login/
   ```

3. **Vérifiez la réponse** :
   - ✅ 200 OK = Backend accessible
   - ❌ 404/500/Timeout = Backend non accessible ou mal configuré

#### Test 3 : Tester depuis un Outil Externe

Utilisez **Postman** ou **curl** :

```bash
curl -X GET https://monuniversaya.com/api/
```

---

### Solution 2 : Vérifier la Configuration CORS

#### Vérifier `settings.py`

Assurez-vous que les CORS sont correctement configurés :

```python
# aya_backend/aya_project/settings.py

CORS_ALLOWED_ORIGINS = [
    "http://localhost:3000",
    "http://127.0.0.1:3000",
    "http://localhost:8080",
    "http://127.0.0.1:8080",
    "http://10.0.2.2:8000",  # Android emulator
    "https://monuniversaya.com",
    "https://www.monuniversaya.com",
]

# IMPORTANT : Autoriser toutes les origines pour les apps mobiles
CORS_ALLOW_ALL_ORIGINS = True  # Pour les apps mobiles (optionnel mais recommandé)

# Ou plus restrictif :
CORS_ALLOW_CREDENTIALS = True
CORS_ALLOW_HEADERS = [
    'accept',
    'accept-encoding',
    'authorization',
    'content-type',
    'dnt',
    'origin',
    'user-agent',
    'x-csrftoken',
    'x-requested-with',
]
```

#### Redémarrer le Serveur Django

Après modification, redémarrez le serveur :

```bash
cd aya_backend
python manage.py runserver 0.0.0.0:8000
```

---

### Solution 3 : Vérifier ALLOWED_HOSTS

#### Dans `settings.py` :

```python
ALLOWED_HOSTS = [
    'monuniversaya.com',
    'www.monuniversaya.com',
    '216.158.228.93',  # IP du serveur
    '*',  # Pour le développement (retirer en production)
]
```

**⚠️ En production**, retirez `'*'` et utilisez uniquement vos domaines.

---

### Solution 4 : Vérifier le Certificat SSL

#### Problèmes de Certificat SSL

Si le certificat SSL n'est pas valide :
- ❌ Les apps Android peuvent refuser la connexion
- ❌ Erreur "Certificate verification failed"

#### Solutions :

1. **Utiliser un certificat valide** (Let's Encrypt, Cloudflare, etc.)
2. **Vérifier que le certificat n'est pas expiré**
3. **Vérifier que le certificat couvre le bon domaine**

---

### Solution 5 : Vérifier les Permissions Réseau Android

#### Vérifier `AndroidManifest.xml`

Assurez-vous que les permissions réseau sont présentes :

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

#### Vérifier `network_security_config.xml`

Pour Android 9+, vérifiez que HTTPS est autorisé :

```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    
    <!-- Autoriser votre domaine -->
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">monuniversaya.com</domain>
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </domain-config>
</network-security-config>
```

---

## 🔧 Diagnostic Étape par Étape

### Étape 1 : Tester le Backend depuis un Navigateur

1. Ouvrez : `https://monuniversaya.com`
2. Si ça ne charge pas → **Backend non déployé ou inaccessible**

### Étape 2 : Tester l'API

1. Ouvrez : `https://monuniversaya.com/api/`
2. Si erreur 404 → **URLs mal configurées**
3. Si erreur 500 → **Erreur serveur**
4. Si timeout → **Serveur non accessible**

### Étape 3 : Tester depuis l'App (Mode Debug)

1. **Activez les logs** dans l'application
2. **Regardez les erreurs** dans la console
3. **Vérifiez l'URL** utilisée

### Étape 4 : Vérifier les Logs du Serveur

1. **Connectez-vous au serveur**
2. **Vérifiez les logs Django** :
   ```bash
   tail -f /var/log/django/error.log
   ```
3. **Vérifiez les logs Nginx/Apache** (si utilisé)

---

## 🚀 Actions Immédiates

### 1. Vérifier que le Backend est Déployé

**Question** : Votre backend Django est-il déployé sur `monuniversaya.com` ?

- ✅ **OUI** → Passez à l'étape 2
- ❌ **NON** → Vous devez déployer le backend d'abord

### 2. Tester l'Accessibilité

**Test rapide** :
```bash
curl -I https://monuniversaya.com/api/
```

**Résultat attendu** :
```
HTTP/2 200
```

### 3. Vérifier les CORS

**Modifiez `settings.py`** pour autoriser toutes les origines (temporairement) :

```python
CORS_ALLOW_ALL_ORIGINS = True
```

### 4. Redémarrer le Serveur

```bash
# Sur le serveur
sudo systemctl restart gunicorn  # ou votre service
# ou
python manage.py runserver 0.0.0.0:8000
```

---

## 📋 Checklist de Vérification

- [ ] Backend déployé et accessible sur `https://monuniversaya.com`
- [ ] Certificat SSL valide et non expiré
- [ ] CORS configuré pour accepter les requêtes mobiles
- [ ] ALLOWED_HOSTS contient `monuniversaya.com`
- [ ] Port 443 (HTTPS) ouvert dans le firewall
- [ ] Serveur Django en cours d'exécution
- [ ] Permissions réseau Android configurées
- [ ] `network_security_config.xml` autorise le domaine

---

## 🔍 Debug dans l'Application

### Ajouter des Logs de Debug

Dans `lib/services/django_game_service.dart`, ajoutez :

```dart
Future<Map<String, dynamic>> playGame(...) async {
  try {
    print('🌐 URL: ${DjangoConfig.baseUrl}/api/games/play/');
    print('🔑 Token: ${_authService.accessToken?.substring(0, 20)}...');
    
    final response = await http.post(
      Uri.parse('${DjangoConfig.baseUrl}/api/games/play/'),
      headers: _authHeaders,
      body: jsonEncode({...}),
    );
    
    print('📡 Status: ${response.statusCode}');
    print('📄 Body: ${response.body}');
    
    // ...
  } catch (e) {
    print('❌ Erreur complète: $e');
    print('❌ Type: ${e.runtimeType}');
    // ...
  }
}
```

### Vérifier les Logs

1. **Connectez l'appareil en USB**
2. **Activez le mode développeur**
3. **Regardez les logs** :
   ```bash
   adb logcat | grep -i "connection\|error\|network"
   ```

---

## ⚠️ Problèmes Courants

### Problème 1 : Backend Non Déployé

**Symptôme** : Timeout ou erreur de connexion

**Solution** : Déployer le backend Django sur le serveur

### Problème 2 : Certificat SSL Invalide

**Symptôme** : Erreur "Certificate verification failed"

**Solution** : Installer un certificat SSL valide (Let's Encrypt)

### Problème 3 : CORS Bloqué

**Symptôme** : Erreur CORS dans les logs

**Solution** : Configurer CORS pour autoriser les apps mobiles

### Problème 4 : Firewall Bloque les Connexions

**Symptôme** : Timeout

**Solution** : Ouvrir le port 443 (HTTPS) dans le firewall

---

## 📞 Support

Si le problème persiste :

1. **Vérifiez les logs du serveur**
2. **Testez l'API depuis Postman**
3. **Vérifiez la configuration du serveur web** (Nginx/Apache)
4. **Contactez votre hébergeur** si nécessaire

---

## ✅ Résumé

**Action immédiate** :
1. ✅ Vérifier que `https://monuniversaya.com` est accessible
2. ✅ Tester l'API : `https://monuniversaya.com/api/`
3. ✅ Vérifier les CORS dans `settings.py`
4. ✅ Redémarrer le serveur Django
5. ✅ Rebuild et retester l'application

