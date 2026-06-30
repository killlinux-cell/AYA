# Generated manually for World Cup bracket

from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('qr_codes', '0009_world_cup'),
    ]

    operations = [
        migrations.CreateModel(
            name='WorldCupBracketMatch',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('code', models.CharField(max_length=10, unique=True, verbose_name='Code match')),
                ('round', models.CharField(choices=[('r16', '1/16 de finale'), ('r8', '1/8 de finale'), ('qf', 'Quarts'), ('sf', 'Demies'), ('final', 'Finale')], max_length=10)),
                ('position', models.PositiveSmallIntegerField(default=0)),
                ('home_team', models.CharField(blank=True, max_length=100)),
                ('away_team', models.CharField(blank=True, max_length=100)),
                ('home_team_code', models.CharField(blank=True, max_length=8)),
                ('away_team_code', models.CharField(blank=True, max_length=8)),
                ('home_source_code', models.CharField(blank=True, max_length=10)),
                ('away_source_code', models.CharField(blank=True, max_length=10)),
                ('winner_side', models.CharField(blank=True, choices=[('', '—'), ('home', 'Domicile'), ('away', 'Extérieur')], default='', max_length=4)),
                ('updated_at', models.DateTimeField(auto_now=True)),
                ('world_cup_match', models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='bracket_slots', to='qr_codes.worldcupmatch')),
            ],
            options={
                'verbose_name': 'Match tableau CDM',
                'verbose_name_plural': 'Matchs tableau CDM',
                'db_table': 'world_cup_bracket_matches',
                'ordering': ['round', 'position'],
            },
        ),
    ]
