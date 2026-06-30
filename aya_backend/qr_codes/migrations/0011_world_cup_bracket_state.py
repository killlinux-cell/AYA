from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('qr_codes', '0010_world_cup_bracket'),
    ]

    operations = [
        migrations.CreateModel(
            name='WorldCupBracketState',
            fields=[
                ('id', models.PositiveSmallIntegerField(default=1, primary_key=True, serialize=False)),
                ('winners', models.JSONField(blank=True, default=dict)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'État tableau CDM',
                'verbose_name_plural': 'États tableau CDM',
                'db_table': 'world_cup_bracket_state',
            },
        ),
    ]
