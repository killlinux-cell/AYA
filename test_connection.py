#!/usr/bin/env python3
"""
Script simple pour tester la connexion au backend
"""

import requests
import time

def test_connection():
    """Teste la connexion au backend"""
    print("🔗 Test de connexion au backend...")
    
    # Attendre un peu que le serveur démarre
    time.sleep(2)
    
    try:
        response = requests.get("http://localhost:8000/api/", timeout=5)
        if response.status_code == 200:
            print("✅ Backend accessible")
            print(f"   Réponse: {response.json()}")
            return True
        else:
            print(f"❌ Backend inaccessible (status: {response.status_code})")
            return False
    except requests.exceptions.ConnectionError:
        print("❌ Impossible de se connecter au backend")
        print("💡 Vérifiez que le serveur Django est démarré sur le port 8000")
        return False
    except Exception as e:
        print(f"❌ Erreur: {e}")
        return False

if __name__ == "__main__":
    test_connection()
