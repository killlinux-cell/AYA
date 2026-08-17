"""
Vidéos de recettes / astuces (indépendantes des publicités d'accueil).
"""
import uuid

from django.db import models


class RecipeVideo(models.Model):
    CATEGORY_CHOICES = [
        ('recettes', 'Recettes'),
        ('astuces', 'Astuces du quotidien'),
        ('bienetre', 'Bien-être & nature'),
    ]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    title = models.CharField(max_length=200, verbose_name='Titre')
    description = models.TextField(blank=True, verbose_name='Description')
    category = models.CharField(
        max_length=20,
        choices=CATEGORY_CHOICES,
        default='recettes',
        verbose_name='Catégorie',
    )
    video_file = models.FileField(
        upload_to='recipes/videos/',
        verbose_name='Fichier vidéo',
        help_text='Format MP4 recommandé, max 50MB',
    )
    thumbnail = models.ImageField(
        upload_to='recipes/thumbnails/',
        blank=True,
        null=True,
        verbose_name='Miniature',
    )
    is_active = models.BooleanField(default=True, verbose_name='Actif')
    sort_order = models.IntegerField(
        default=0,
        verbose_name='Ordre',
        help_text='Plus le nombre est élevé, plus la vidéo apparaît en haut',
    )
    views_count = models.IntegerField(default=0, verbose_name="Nombre d'affichages")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    created_by = models.ForeignKey(
        'authentication.User',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='created_recipes',
        verbose_name='Créé par',
    )

    class Meta:
        db_table = 'recipe_videos'
        verbose_name = 'Vidéo Recette'
        verbose_name_plural = 'Vidéos Recettes'
        ordering = ['-sort_order', '-created_at']

    def __str__(self):
        return self.title

    def increment_views(self):
        self.views_count += 1
        self.save(update_fields=['views_count'])
