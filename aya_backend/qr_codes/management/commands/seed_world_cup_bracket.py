from django.core.management.base import BaseCommand

from qr_codes.models_world_cup import WorldCupBracketMatch


BRACKET = [
    # 1/16 de finale
    {'code': 'M73', 'round': 'r16', 'position': 1,
     'home_team': 'Afrique du Sud', 'home_team_code': 'AFS',
     'away_team': 'Canada', 'away_team_code': 'CAN'},
    {'code': 'M74', 'round': 'r16', 'position': 2,
     'home_team': 'Allemagne', 'home_team_code': 'GER',
     'away_team': 'Paraguay', 'away_team_code': 'PAR'},
    {'code': 'M75', 'round': 'r16', 'position': 3,
     'home_team': 'Pays-Bas', 'home_team_code': 'NED',
     'away_team': 'Maroc', 'away_team_code': 'MAR'},
    {'code': 'M77', 'round': 'r16', 'position': 4,
     'home_team': 'France', 'home_team_code': 'FRA',
     'away_team': 'Suède', 'away_team_code': 'SWE'},
    {'code': 'M76', 'round': 'r16', 'position': 5,
     'home_team': 'Brésil', 'home_team_code': 'BRA',
     'away_team': 'Japon', 'away_team_code': 'JPN'},
    {'code': 'M78', 'round': 'r16', 'position': 6,
     "home_team": "Côte d'Ivoire", 'home_team_code': 'CIV',
     'away_team': 'Sénégal', 'away_team_code': 'SEN'},
    # 1/8 de finale
    {'code': 'M89', 'round': 'r8', 'position': 1,
     'home_source_code': 'M74', 'away_source_code': 'M77'},
    {'code': 'M90', 'round': 'r8', 'position': 2,
     'home_source_code': 'M73', 'away_source_code': 'M75'},
    {'code': 'M91', 'round': 'r8', 'position': 3,
     'home_source_code': 'M76', 'away_source_code': 'M78'},
    # Quarts
    {'code': 'M97', 'round': 'qf', 'position': 1,
     'home_source_code': 'M89', 'away_source_code': 'M90'},
    {'code': 'M98', 'round': 'qf', 'position': 2,
     'home_source_code': 'M91'},
    # Demies
    {'code': 'M101', 'round': 'sf', 'position': 1,
     'home_source_code': 'M97', 'away_source_code': 'M98'},
    # Finale
    {'code': 'M104', 'round': 'final', 'position': 1,
     'home_source_code': 'M101'},
]


class Command(BaseCommand):
    help = 'Initialise le tableau d\'élimination Coupe du Monde 2026'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset',
            action='store_true',
            help='Réinitialise le tableau (efface les vainqueurs)',
        )

    def handle(self, *args, **options):
        if options['reset']:
            WorldCupBracketMatch.objects.all().delete()
            self.stdout.write('Tableau réinitialisé.')

        for item in BRACKET:
            defaults = {k: v for k, v in item.items() if k != 'code'}
            WorldCupBracketMatch.objects.update_or_create(
                code=item['code'],
                defaults=defaults,
            )

        self.stdout.write(self.style.SUCCESS(
            f'{len(BRACKET)} slots tableau créés/mis à jour.'
        ))
