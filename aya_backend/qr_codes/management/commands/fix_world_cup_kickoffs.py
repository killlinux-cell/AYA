from datetime import timedelta

from django.core.management.base import BaseCommand
from django.db import transaction

from qr_codes.models_world_cup import WorldCupMatch


class Command(BaseCommand):
    help = (
        "Corrige les heures de coup d'envoi enregistrées avec l'ancien fuseau Europe/Paris "
        "(ajoute 2 h pour aligner sur l'heure Abidjan GMT+0)."
    )

    def add_arguments(self, parser):
        parser.add_argument(
            '--hours',
            type=int,
            default=2,
            help='Nombre d\'heures à ajouter (défaut: 2).',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Affiche les changements sans modifier la base.',
        )

    def handle(self, *args, **options):
        hours = options['hours']
        dry_run = options['dry_run']
        delta = timedelta(hours=hours)
        matches = WorldCupMatch.objects.order_by('kickoff_at')

        if not matches.exists():
            self.stdout.write(self.style.WARNING('Aucun match à corriger.'))
            return

        self.stdout.write(f'{matches.count()} match(s) — décalage +{hours}h')
        for match in matches:
            old = match.kickoff_at
            new = old + delta
            self.stdout.write(f'  {match.home_team} vs {match.away_team}: {old} → {new}')

        if dry_run:
            self.stdout.write(self.style.WARNING('Dry-run : aucune modification.'))
            return

        with transaction.atomic():
            for match in matches:
                match.kickoff_at += delta
                match.save(update_fields=['kickoff_at'])

        self.stdout.write(self.style.SUCCESS(f'{matches.count()} match(s) corrigé(s).'))
