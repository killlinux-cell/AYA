"""
Base de connaissances SARCI SA — source : https://sarci.ci/
Utilisée par l'assistant chat (100 % gratuit, sans API externe).
"""

SARCI_KNOWLEDGE = [
    {
        'id': 'entreprise',
        'keywords': [
            'sarci', 'société', 'entreprise', 'qui', 'sommes', 'raffinage',
            'africaine', 'côte', 'ivoire', 'ci', 'activité', 'mission',
            'histoire', 'présentation', 'propos',
        ],
        'title': 'SARCI SA — Qui sommes-nous',
        'content': (
            "La Société Africaine de Raffinage en Côte d'Ivoire (SARCI SA) est une "
            "entreprise du secteur agroalimentaire. Ses activités principales sont le "
            "raffinage de l'huile de palme brute et la distribution de produits destinés "
            "à la consommation en Côte d'Ivoire et dans la sous-région.\n\n"
            "SARCI s'engage à fidéliser les consommateurs et à leur offrir une large "
            "gamme de produits de qualité répondant à leurs besoins.\n\n"
            "Site officiel : https://sarci.ci"
        ),
    },
    {
        'id': 'huiles',
        'keywords': [
            'huile', 'huiles', 'aya', 'bonor', 'palme', 'cuisine', 'frire',
            'raffinage', 'liquide',
        ],
        'title': 'Huiles SARCI',
        'content': (
            "SARCI propose une gamme d'huiles alimentaires de qualité :\n"
            "• **Aya** — huile de référence de la marque\n"
            "• **Bonor** — huile pour la cuisine quotidienne\n\n"
            "Ces huiles sont produites dans le cadre du raffinage de l'huile de palme "
            "brute, activité cœur de SARCI SA.\n\n"
            "Plus d'infos : https://sarci.ci (section Nos Produits > Huiles)"
        ),
    },
    {
        'id': 'savons',
        'keywords': [
            'savon', 'savons', 'magico', 'maya', 'ménage', 'toilette', 'armonia',
            'uno', 'hygiène', 'laver', 'mousse',
        ],
        'title': 'Savons SARCI',
        'content': (
            "SARCI distribue plusieurs marques de savons :\n"
            "• **Magico**\n"
            "• **Maya Ménage** — entretien de la maison\n"
            "• **Maya Toilette** — hygiène corporelle\n"
            "• **Armonia**\n"
            "• **UNO**\n\n"
            "Découvrez-les sur https://sarci.ci (section Nos Produits > Savons)"
        ),
    },
    {
        'id': 'chocolats',
        'keywords': [
            'chocolat', 'chocolats', 'choco', 'cacao', 'aya choco', 'doucerie',
        ],
        'title': 'Chocolats SARCI',
        'content': (
            "SARCI propose des produits chocolatés sous la marque **Aya Choco**.\n\n"
            "Retrouvez la gamme sur https://sarci.ci (section Nos Produits > Chocolats)"
        ),
    },
    {
        'id': 'margarines',
        'keywords': [
            'margarine', 'margarines', 'beurre', 'tartine', 'pâtisserie',
        ],
        'title': 'Margarines SARCI',
        'content': (
            "SARCI commercialise la **Margarine Aya**, produit de qualité pour "
            "vos préparations culinaires et tartines.\n\n"
            "Plus d'infos : https://sarci.ci (section Nos Produits > Margarines)"
        ),
    },
    {
        'id': 'marques',
        'keywords': [
            'marque', 'marques', 'produit', 'produits', 'gamme', 'catalogue',
            'tous', 'liste', 'quels',
        ],
        'title': 'Nos marques',
        'content': (
            "Les principales marques SARCI SA :\n"
            "🛢️ **Huiles** : Aya, Bonor\n"
            "🧼 **Savons** : Magico, Maya Ménage, Maya Toilette, Armonia, UNO\n"
            "🍫 **Chocolats** : Aya Choco\n"
            "🧈 **Margarines** : Margarine Aya\n\n"
            "La qualité est au cœur du processus de fabrication de tous nos produits.\n"
            "Voir le catalogue : https://sarci.ci"
        ),
    },
    {
        'id': 'qualite',
        'keywords': [
            'qualité', 'certification', 'norme', 'politique', 'engagement',
            'fabrication', 'processus',
        ],
        'title': 'Politique de qualité',
        'content': (
            "SARCI SA place la qualité au cœur de son processus de fabrication. "
            "L'entreprise s'engage à offrir des produits répondant aux attentes "
            "des consommateurs ivoiriens et de la sous-région.\n\n"
            "Consultez la politique de qualité sur https://sarci.ci "
            "(section Entreprise > Politique de qualité)"
        ),
    },
    {
        'id': 'contact',
        'keywords': [
            'contact', 'contacter', 'téléphone', 'tel', 'appeler', 'email',
            'mail', 'adresse', 'siège', 'localisation', 'où', 'abidjan',
            'yopougon', 'devis',
        ],
        'title': 'Contact SARCI',
        'content': (
            "📞 **Téléphones** :\n"
            "• +225 27 23 46 71 39\n"
            "• +225 27 23 46 66 18\n\n"
            "📧 **Email** : sarci@sarci.ci\n"
            "🌐 **Site web** : https://sarci.ci\n\n"
            "📍 **Siège social** :\n"
            "Yopougon Zone Industrielle, Abidjan, Côte d'Ivoire\n"
            "BP : 04 BP 1244 Abidjan 04\n\n"
            "N'hésitez pas à nous contacter pour toute demande ou devis."
        ),
    },
    {
        'id': 'app_aya',
        'keywords': [
            'application', 'app', 'mon univers', 'aya+', 'aya plus', 'points',
            'qr', 'code', 'scanner', 'fidélité', 'fidelite', 'fidéliser',
            'jeux', 'pronostic', 'pronostics', 'match', 'coupe', 'monde',
            'bonus', 'grand prix', 'gagner', 'comment utiliser', 'utiliser',
        ],
        'title': 'Application Mon univers AYA',
        'content': (
            "**Mon univers AYA** est l'application mobile de fidélité SARCI SA.\n\n"
            "Fonctionnalités :\n"
            "• 📱 **Scanner des QR codes** sur les produits SARCI pour gagner des points\n"
            "• ⭐ **Accumuler des points** et les échanger contre des récompenses\n"
            "• 🎮 **Jeux & pronostics** — pariez sur les matchs et gagnez des points\n"
            "• 🍳 **Recettes & astuces** — bientôt disponibles\n"
            "• 🏆 **Grand Prix** — participez aux tirages au sort\n\n"
            "Scannez les codes QR sur les emballages des produits Aya et SARCI "
            "pour commencer à cumuler vos points !"
        ),
    },
    {
        'id': 'points',
        'keywords': [
            'point', 'points', 'cumuler', 'gagner', 'échanger', 'echange',
            'solde', 'récompense', 'recompense', 'cadeau',
        ],
        'title': 'Système de points AYA',
        'content': (
            "Dans l'application Mon univers AYA :\n"
            "1. **Scannez** les QR codes sur les produits SARCI\n"
            "2. **Accumulez** des points sur votre compte\n"
            "3. **Échangez** vos points contre des récompenses\n"
            "4. **Participez** aux jeux et pronostics pour gagner encore plus\n\n"
            "Votre solde de points est visible sur l'écran d'accueil de l'application."
        ),
    },
    {
        'id': 'actions_sociales',
        'keywords': [
            'social', 'sociaux', 'actions', 'rse', 'responsabilité', 'communauté',
            'engagement social',
        ],
        'title': 'Actions sociales SARCI',
        'content': (
            "SARCI SA mène des actions sociales au service de la communauté "
            "ivoirienne. Retrouvez le détail sur https://sarci.ci "
            "(section Entreprise > Actions sociales)."
        ),
    },
    {
        'id': 'actualites',
        'keywords': [
            'actualité', 'actualités', 'news', 'nouveau', 'nouveauté', 'info',
        ],
        'title': 'Actualités SARCI',
        'content': (
            "Suivez l'actualité de SARCI SA sur le site https://sarci.ci "
            "(section Entreprise > Actualités) et inscrivez-vous à la newsletter "
            "pour être informé en priorité."
        ),
    },
]

WELCOME_MESSAGE = (
    "Bonjour ! 👋 Je suis l'**Assistant SARCI**, votre guide sur SARCI SA "
    "et ses produits.\n\n"
    "Je peux vous renseigner sur :\n"
    "• Nos **huiles** (Aya, Bonor)\n"
    "• Nos **savons** (Magico, Maya, Armonia, UNO…)\n"
    "• Nos **chocolats** et **margarines**\n"
    "• L'application **Mon univers AYA** et les points\n"
    "• Nos **coordonnées** et le site sarci.ci\n\n"
    "Posez-moi votre question !"
)

OFF_TOPIC_MESSAGE = (
    "Je suis l'assistant SARCI et je réponds uniquement aux questions "
    "concernant **SARCI SA**, ses produits (Aya, Magico, Maya, Bonor…) "
    "et l'application **Mon univers AYA**.\n\n"
    "Pour d'autres sujets, contactez-nous :\n"
    "📧 sarci@sarci.ci\n"
    "📞 +225 27 23 46 71 39\n"
    "🌐 https://sarci.ci"
)

NO_MATCH_MESSAGE = (
    "Je n'ai pas trouvé de réponse précise à votre question dans ma base "
    "SARCI. Voici ce que je peux vous dire :\n\n"
    "• Visitez **https://sarci.ci** pour le catalogue complet\n"
    "• Contactez-nous : **sarci@sarci.ci** ou **+225 27 23 46 71 39**\n\n"
    "Reformulez votre question (ex : « Quels savons SARCI propose ? », "
    "« Comment gagner des points AYA ? »)"
)
