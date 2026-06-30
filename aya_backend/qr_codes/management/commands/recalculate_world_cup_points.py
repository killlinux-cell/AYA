from django.core.management.base import BaseCommand

from qr_codes.models_world_cup import WorldCupMatch
from qr_codes.world_cup_scoring import recalculate_match_predictions


class Command(BaseCommand):
    help = 'Recalcule les points CDM (barème 10/5/1) et crédite les utilisateurs'

    def handle(self, *args, **options):
        matches = WorldCupMatch.objects.filter(status='finished')
        total = 0
        for match in matches:
            total += recalculate_match_predictions(match)
        self.stdout.write(self.style.SUCCESS(
            f'{total} pronostic(s) recalculé(s) sur {matches.count()} match(s).'
        ))
