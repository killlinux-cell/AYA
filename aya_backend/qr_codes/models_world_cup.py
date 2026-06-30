from django.db import models
from django.contrib.auth import get_user_model
from django.utils import timezone
import uuid

User = get_user_model()


class WorldCupMatch(models.Model):
    """Match de la Coupe du Monde pour les pronostics."""

    STATUS_CHOICES = [
        ('scheduled', 'Programmé'),
        ('finished', 'Terminé'),
        ('cancelled', 'Annulé'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    home_team = models.CharField(max_length=100, verbose_name='Équipe domicile')
    away_team = models.CharField(max_length=100, verbose_name='Équipe extérieur')
    home_team_code = models.CharField(max_length=8, blank=True)
    away_team_code = models.CharField(max_length=8, blank=True)
    kickoff_at = models.DateTimeField(verbose_name='Coup d\'envoi')
    stage = models.CharField(max_length=100, default='Phase de groupes')
    group_name = models.CharField(max_length=50, blank=True, verbose_name='Groupe')
    home_score = models.PositiveSmallIntegerField(null=True, blank=True)
    away_score = models.PositiveSmallIntegerField(null=True, blank=True)
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='scheduled')
    predictions_open = models.BooleanField(default=True)
    is_active = models.BooleanField(default=True)
    bracket_match_code = models.CharField(
        max_length=10,
        blank=True,
        null=True,
        unique=True,
        verbose_name='Code tableau (M73…)',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'world_cup_matches'
        verbose_name = 'Match CDM'
        verbose_name_plural = 'Matchs CDM'
        ordering = ['kickoff_at']

    def __str__(self):
        return f'{self.home_team} vs {self.away_team}'

    @property
    def is_finished(self):
        return self.status == 'finished'

    @property
    def can_predict(self):
        if not self.predictions_open or self.is_finished:
            return False
        return timezone.now() < self.kickoff_at

    def finish_match(self, home_score, away_score):
        """Enregistre le résultat et calcule les points des pronostics."""
        self.home_score = home_score
        self.away_score = away_score
        self.status = 'finished'
        self.predictions_open = False
        self.save()

        from .world_cup_scoring import recalculate_match_predictions
        recalculate_match_predictions(self)


class WorldCupBracketMatch(models.Model):
    """Match du tableau d'élimination directe (admin interactif)."""

    ROUND_CHOICES = [
        ('r16', '1/16 de finale'),
        ('r8', '1/8 de finale'),
        ('qf', 'Quarts'),
        ('sf', 'Demies'),
        ('final', 'Finale'),
    ]
    SIDE_CHOICES = [
        ('', '—'),
        ('home', 'Domicile'),
        ('away', 'Extérieur'),
    ]

    code = models.CharField(max_length=10, unique=True, verbose_name='Code match')
    round = models.CharField(max_length=10, choices=ROUND_CHOICES)
    position = models.PositiveSmallIntegerField(default=0)
    home_team = models.CharField(max_length=100, blank=True)
    away_team = models.CharField(max_length=100, blank=True)
    home_team_code = models.CharField(max_length=8, blank=True)
    away_team_code = models.CharField(max_length=8, blank=True)
    home_source_code = models.CharField(max_length=10, blank=True)
    away_source_code = models.CharField(max_length=10, blank=True)
    winner_side = models.CharField(max_length=4, choices=SIDE_CHOICES, blank=True, default='')
    world_cup_match = models.ForeignKey(
        WorldCupMatch,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='bracket_slots',
    )
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'world_cup_bracket_matches'
        ordering = ['round', 'position']
        verbose_name = 'Match tableau CDM'
        verbose_name_plural = 'Matchs tableau CDM'

    def __str__(self):
        return self.code

    @property
    def home_label(self):
        if self.home_team:
            return self.home_team
        if self.home_source_code:
            return f'Vainqueur {self.home_source_code}'
        return '—'

    @property
    def away_label(self):
        if self.away_team:
            return self.away_team
        if self.away_source_code:
            return f'Vainqueur {self.away_source_code}'
        return '—'

    @property
    def winner_team(self):
        if self.winner_side == 'home':
            return self.home_team
        if self.winner_side == 'away':
            return self.away_team
        return ''

    @property
    def winner_code(self):
        if self.winner_side == 'home':
            return self.home_team_code
        if self.winner_side == 'away':
            return self.away_team_code
        return ''


class WorldCupBracketState(models.Model):
    """État du tableau interactif (vainqueurs par numéro de match)."""

    id = models.PositiveSmallIntegerField(primary_key=True, default=1)
    winners = models.JSONField(default=dict, blank=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'world_cup_bracket_state'
        verbose_name = 'État tableau CDM'
        verbose_name_plural = 'États tableau CDM'

    def __str__(self):
        return f'Tableau CDM ({len(self.winners)} vainqueurs)'


class WorldCupPrediction(models.Model):
    """Pronostic d'un utilisateur pour un match."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='world_cup_predictions'
    )
    match = models.ForeignKey(
        WorldCupMatch, on_delete=models.CASCADE, related_name='predictions'
    )
    home_score = models.PositiveSmallIntegerField()
    away_score = models.PositiveSmallIntegerField()
    points_earned = models.PositiveSmallIntegerField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'world_cup_predictions'
        verbose_name = 'Pronostic CDM'
        verbose_name_plural = 'Pronostics CDM'
        unique_together = ['user', 'match']
        ordering = ['-created_at']

    def __str__(self):
        return f'{self.user.email}: {self.home_score}-{self.away_score}'
