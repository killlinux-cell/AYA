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
        from .world_cup_scoring import calculate_prediction_points

        self.home_score = home_score
        self.away_score = away_score
        self.status = 'finished'
        self.predictions_open = False
        self.save()

        for prediction in self.predictions.select_related('user'):
            points = calculate_prediction_points(
                prediction.home_score,
                prediction.away_score,
                home_score,
                away_score,
            )
            prediction.points_earned = points
            prediction.save(update_fields=['points_earned', 'updated_at'])


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
