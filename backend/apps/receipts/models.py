from django.db import models
from django.utils.crypto import get_random_string
import qrcode
from io import BytesIO
from django.core.files import File
from PIL import Image


def generate_receipt_number():
    """Generate unique receipt number"""
    return f"LV-{get_random_string(8, allowed_chars='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ')}"


class Receipt(models.Model):
    """
    Receipt/Order model for laundry items
    """
    STATUS_CHOICES = (
        ('pending', 'Pending'),
        ('washing', 'Washing'),
        ('drying', 'Drying'),
        ('ready', 'Ready for Pickup'),
        ('completed', 'Completed'),
        ('cancelled', 'Cancelled'),
    )

    receipt_number = models.CharField(max_length=20, unique=True, default=generate_receipt_number)
    laundromat = models.ForeignKey(
        'laundromats.Laundromat',
        on_delete=models.CASCADE,
        related_name='receipts'
    )
    customer = models.ForeignKey(
        'users.User',
        on_delete=models.CASCADE,
        related_name='customer_receipts'
    )
    staff = models.ForeignKey(
        'users.User',
        on_delete=models.SET_NULL,
        null=True,
        related_name='staff_receipts'
    )

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')

    drop_off_date = models.DateTimeField(auto_now_add=True)
    expected_pickup_date = models.DateTimeField()
    actual_pickup_date = models.DateTimeField(null=True, blank=True)

    items_description = models.TextField(help_text='Description of items')
    items_count = models.IntegerField(default=0, help_text='Number of items')
    special_instructions = models.TextField(blank=True)

    price = models.DecimalField(max_digits=10, decimal_places=2, default=0)

    qr_code = models.ImageField(upload_to='qr_codes/', blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'receipts'
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['receipt_number']),
            models.Index(fields=['status']),
            models.Index(fields=['customer']),
            models.Index(fields=['laundromat']),
        ]

    def __str__(self):
        return f"{self.receipt_number} - {self.customer.username}"

    def save(self, *args, **kwargs):
        # Generate QR code if not exists
        if not self.qr_code:
            qr_img = qrcode.make(self.receipt_number)
            buffer = BytesIO()
            qr_img.save(buffer, format='PNG')
            file_name = f'qr_{self.receipt_number}.png'
            self.qr_code.save(file_name, File(buffer), save=False)
            buffer.close()

        super().save(*args, **kwargs)

    @property
    def is_active(self):
        """Check if receipt is still active (not completed/cancelled)"""
        return self.status not in ['completed', 'cancelled']

    @property
    def days_since_dropoff(self):
        """Calculate days since drop-off"""
        from django.utils import timezone
        delta = timezone.now() - self.drop_off_date
        return delta.days
