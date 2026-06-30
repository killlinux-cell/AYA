from django.core.management.base import BaseCommand

from qr_codes.world_cup_match_sync import sync_bracket_to_matches


class Command(BaseCommand):
    help = (
        'Crée/met à jour les matchs pronostics depuis le tableau CDM '
        '(visible dans l\'app mobile et « Gérer les matchs »).'
    )

    def handle(self, *args, **options):
        result = sync_bracket_to_matches()
        self.stdout.write(self.style.SUCCESS(
            f'Sync terminée : {result["created"]} créés, '
            f'{result["updated"]} mis à jour, '
            f'{result["skipped"]} inchangés — '
            f'{result["total_active"]} matchs actifs au total.'
        ))
