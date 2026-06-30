from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('qr_codes', '0011_world_cup_bracket_state'),
    ]

    operations = [
        migrations.AddField(
            model_name='worldcupmatch',
            name='bracket_match_code',
            field=models.CharField(
                blank=True,
                max_length=10,
                null=True,
                unique=True,
                verbose_name='Code tableau (M73…)',
            ),
        ),
    ]
