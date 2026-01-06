# Generated migration for analytics indexes

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('receipts', '0002_initial'),
    ]

    operations = [
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['created_at'], name='receipts_created_at_idx'),
        ),
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['drop_off_date'], name='receipts_drop_off_idx'),
        ),
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['actual_pickup_date'], name='receipts_pickup_idx'),
        ),
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['laundromat', 'created_at'], name='receipts_laundromat_date_idx'),
        ),
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['laundromat', 'status'], name='receipts_laundromat_status_idx'),
        ),
        migrations.AddIndex(
            model_name='receipt',
            index=models.Index(fields=['staff', 'created_at'], name='receipts_staff_date_idx'),
        ),
    ]
