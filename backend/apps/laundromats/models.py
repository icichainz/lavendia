from django.db import models


class Laundromat(models.Model):
    """
    Laundromat location model
    """
    name = models.CharField(max_length=200)
    address = models.TextField()
    phone = models.CharField(max_length=20)
    email = models.EmailField(blank=True, null=True)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'laundromats'
        ordering = ['name']
        indexes = [
            models.Index(fields=['name']),
            models.Index(fields=['is_active']),
            models.Index(fields=['created_at']),
            models.Index(fields=['updated_at']),
        ]

    def __str__(self):
        return self.name

    @property
    def active_receipts_count(self):
        """Count of active receipts (not completed)"""
        return self.receipts.exclude(status='completed').count()

    @property
    def staff_count(self):
        """Count of staff members"""
        return self.staff_members.count()
