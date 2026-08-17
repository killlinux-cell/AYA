from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion
import uuid


class Migration(migrations.Migration):

    dependencies = [
        migrations.swappable_dependency(settings.AUTH_USER_MODEL),
        ('dashboard', '0003_homebanner'),
    ]

    operations = [
        migrations.CreateModel(
            name='RecipeVideo',
            fields=[
                ('id', models.UUIDField(default=uuid.uuid4, editable=False, primary_key=True, serialize=False)),
                ('title', models.CharField(max_length=200, verbose_name='Titre')),
                ('description', models.TextField(blank=True, verbose_name='Description')),
                ('category', models.CharField(choices=[('recettes', 'Recettes'), ('astuces', 'Astuces du quotidien'), ('bienetre', 'Bien-être & nature')], default='recettes', max_length=20, verbose_name='Catégorie')),
                ('video_file', models.FileField(help_text='Format MP4 recommandé, max 50MB', upload_to='recipes/videos/', verbose_name='Fichier vidéo')),
                ('thumbnail', models.ImageField(blank=True, null=True, upload_to='recipes/thumbnails/', verbose_name='Miniature')),
                ('is_active', models.BooleanField(default=True, verbose_name='Actif')),
                ('sort_order', models.IntegerField(default=0, help_text='Plus le nombre est élevé, plus la vidéo apparaît en haut', verbose_name='Ordre')),
                ('views_count', models.IntegerField(default=0, verbose_name="Nombre d'affichages")),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('created_by', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='created_recipes', to=settings.AUTH_USER_MODEL, verbose_name='Créé par')),
            ],
            options={
                'verbose_name': 'Vidéo Recette',
                'verbose_name_plural': 'Vidéos Recettes',
                'db_table': 'recipe_videos',
                'ordering': ['-sort_order', '-created_at'],
            },
        ),
    ]
