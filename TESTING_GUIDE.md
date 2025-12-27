# 🧪 Guide de Test - Scenario 1.3: QR Code Scanning

## 🎯 **Vue d'ensemble des tests**

Ce guide vous explique comment tester le système de scan QR avec validation Django et attribution de récompenses.

## 🔧 **Préparation des tests**

### **1. Backend Django - Créer des QR codes de test**

```bash
# Dans le dossier aya_backend
cd aya_backend
python manage.py shell < create_test_qr_codes.py
```

### **2. Vérifier que l'API Django fonctionne**

```bash
# Tester l'endpoint de validation
curl -X POST http://localhost:8000/api/qr-codes/validate-and-claim/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"code": "TEST_WIN_001"}'
```

## 📱 **Tests dans l'application Flutter**

### **Test 1 : QR Code valide avec points**

1. **Ouvrir l'app** sur votre téléphone/émulateur
2. **Se connecter** avec un compte utilisateur
3. **Aller dans "Scanner"** (icône QR dans la navigation)
4. **Scanner le code** `TEST_WIN_001`
5. **Vérifier** :
   - ✅ Popup de récompense s'affiche
   - ✅ Message "Félicitations ! Vous avez gagné 50 points !"
   - ✅ Couleur verte (prix moyen)
   - ✅ Points disponibles mis à jour
   - ✅ QR codes collectés +1

### **Test 2 : QR Code avec grand prix**

1. **Scanner le code** `TEST_WIN_002`
2. **Vérifier** :
   - ✅ Popup violet (grand prix)
   - ✅ Message "Félicitations ! Vous avez gagné 100 points !"
   - ✅ Emoji 🏆
   - ✅ Points disponibles +100

### **Test 3 : Ticket fidélité**

1. **Scanner le code** `TEST_LOYALTY_001`
2. **Vérifier** :
   - ✅ Popup orange (ticket fidélité)
   - ✅ Message "Vous avez gagné Ticket Fidélité !"
   - ✅ Emoji 🎫

### **Test 4 : Code déjà utilisé (erreur)**

1. **Scanner le code** `TEST_ALREADY_USED`
2. **Vérifier** :
   - ✅ Popup d'erreur s'affiche
   - ✅ Message "Ce QR code a déjà été utilisé"
   - ✅ Bouton "Réessayer" fonctionne

### **Test 5 : Code invalide (erreur)**

1. **Scanner le code** `TEST_INVALID`
2. **Vérifier** :
   - ✅ Popup d'erreur s'affiche
   - ✅ Message "QR code invalide"
   - ✅ Scanner redémarre

## 🎮 **Tests avec le générateur de QR codes**

### **Utiliser le générateur intégré**

1. **Aller dans "Profil"** → **"Générateur de QR Codes"**
2. **Choisir un QR code** de test (ex: "Grand Prix - 100 points")
3. **Scanner le code généré** avec l'app
4. **Vérifier** que la récompense s'affiche correctement

## 🔍 **Vérification dans Django Admin**

### **Dashboard Django**

1. **Aller sur** `http://localhost:8000/admin/`
2. **Vérifier dans "QR Codes"** :
   - ✅ Codes de test créés
   - ✅ Statut "used" après scan
   - ✅ Utilisateur associé

3. **Vérifier dans "User QR Codes"** :
   - ✅ Historique des scans
   - ✅ Types de récompenses
   - ✅ Dates de réclamation

## 📊 **Tests de performance**

### **Test de charge**

```python
# Script de test de charge (optionnel)
import requests
import time

def test_qr_validation_performance():
    codes = ['TEST_WIN_001', 'TEST_WIN_002', 'TEST_WIN_003']
    
    for code in codes:
        start_time = time.time()
        response = requests.post(
            'http://localhost:8000/api/qr-codes/validate-and-claim/',
            json={'code': code},
            headers={'Authorization': 'Bearer YOUR_TOKEN'}
        )
        end_time = time.time()
        
        print(f"Code {code}: {end_time - start_time:.2f}s - Status: {response.status_code}")
```

## 🐛 **Débogage**

### **Logs Flutter**

```bash
# Voir les logs en temps réel
flutter logs

# Rechercher les logs de validation QR
flutter logs | grep "QR Scanner"
flutter logs | grep "Validation du QR code"
flutter logs | grep "Points mis à jour"
```

### **Logs Django**

```bash
# Dans le terminal Django
python manage.py runserver --verbosity=2

# Vérifier les requêtes API
tail -f django.log | grep "qr-codes"
```

## ✅ **Checklist de validation**

### **Fonctionnalités à vérifier**

- [ ] **Scan QR valide** : Popup de récompense s'affiche
- [ ] **Types de récompenses** : Couleurs et emojis corrects
- [ ] **Mise à jour des points** : Compteurs mis à jour
- [ ] **Gestion d'erreurs** : Codes déjà utilisés, invalides
- [ ] **Animations** : Popup avec effets visuels
- [ ] **Navigation** : Retour fluide après gain
- [ ] **Synchronisation** : Données cohérentes avec Django
- [ ] **Performance** : Réponse rapide (< 2 secondes)

### **Tests d'intégration**

- [ ] **Authentification** : Utilisateur connecté requis
- [ ] **API Backend** : Communication Flutter ↔ Django
- [ ] **Base de données** : Persistance des données
- [ ] **État de l'app** : Providers mis à jour
- [ ] **Interface** : UI responsive et intuitive

## 🚀 **Tests avancés**

### **Test de scénarios complexes**

1. **Scan rapide** : Scanner plusieurs codes rapidement
2. **Connexion perdue** : Tester avec réseau instable
3. **App en arrière-plan** : Scanner puis changer d'app
4. **Multi-utilisateurs** : Tester avec plusieurs comptes

### **Test de régression**

```bash
# Script de test automatisé
python test_qr_scenarios.py

# Tests à exécuter :
# - Scan code valide
# - Scan code déjà utilisé
# - Scan code invalide
# - Scan avec erreur réseau
# - Scan avec utilisateur non authentifié
```

## 📈 **Métriques de succès**

### **Performance attendue**

- **Temps de validation** : < 2 secondes
- **Taux de succès** : > 95%
- **Temps d'affichage popup** : < 500ms
- **Mise à jour UI** : < 1 seconde

### **Expérience utilisateur**

- **Feedback visuel** : Immédiat et clair
- **Messages d'erreur** : Informatifs et utiles
- **Navigation** : Fluide et intuitive
- **Animations** : Smooth et engageantes

## 🎯 **Prochaines étapes après les tests**

1. **Corriger les bugs** identifiés
2. **Optimiser les performances** si nécessaire
3. **Améliorer l'UX** basé sur les retours
4. **Ajouter des tests automatisés**
5. **Préparer la production**

---

**🎉 Une fois tous ces tests validés, votre Scenario 1.3 sera prêt pour la production !**
