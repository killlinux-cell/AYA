from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta

from qr_codes.models_world_cup import WorldCupMatch


class Command(BaseCommand):
    help = 'Crée des matchs de démonstration pour les pronostics Coupe du Monde'

    def handle(self, *args, **options):
        if WorldCupMatch.objects.exists():
            self.stdout.write(self.style.WARNING('Des matchs existent déjà, rien à faire.'))
            return

        now = timezone.now()
        matches = [
            {
                'home_team': "Côte d'Ivoire",
                'away_team': 'Maroc',
                'home_team_code': 'CIV',
                'away_team_code': 'MAR',
                'kickoff_at': now + timedelta(days=2, hours=20),
                'stage': 'Phase de groupes',
                'group_name': 'Groupe A',
            },
            {
                'home_team': 'France',
                'away_team': 'Brésil',
                'home_team_code': 'FRA',
                'away_team_code': 'BRA',
                'kickoff_at': now + timedelta(days=5, hours=21),
                'stage': 'Phase de groupes',
                'group_name': 'Groupe B',
            },
            {
                'home_team': 'Sénégal',
                'away_team': 'Allemagne',
                'home_team_code': 'SEN',
                'away_team_code': 'GER',
                'kickoff_at': now + timedelta(days=8, hours=18),
                'stage': 'Phase de groupes',
                'group_name': 'Groupe C',
            },
        ]

        for data in matches:
            WorldCupMatch.objects.create(**data)

        self.stdout.write(
            self.style.SUCCESS(f'{len(matches)} matchs Coupe du Monde créés.')
        )
