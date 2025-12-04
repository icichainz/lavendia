from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom User model with role-based access
    """
    ROLE_CHOICES = (
        ('customer', 'Customer'),
        ('staff', 'Staff'),
        ('admin', 'Admin'),
    )

    phone = models.CharField(max_length=20, unique=True)
    role = models.CharField(max_length=10, choices=ROLE_CHOICES, default='customer')
    laundromat = models.ForeignKey(
        'laundromats.Laundromat',
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='staff_members',
        help_text='Laundromat where this staff member works (only for staff role)'
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'users'
        ordering = ['-created_at']
        indexes = [
            # single-field index for role lookups
            models.Index(fields=['role'], name='users_role_idx'),
            # compound index for common filters like is_active + role
            models.Index(fields=['is_active', 'role'], name='users_active_role_idx'),
            # compound index for queries by laundromat and active state
            models.Index(fields=['laundromat', 'is_active'], name='users_laundromat_active_idx'),
            # index to support ordering / date range queries
            models.Index(fields=['created_at'], name='users_created_at_idx'),
            # note: phone is unique -> DB already creates an index for it
        ]

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"

    @property
    def is_customer(self):
        return self.role == 'customer'

    @property
    def is_staff_member(self):
        return self.role == 'staff'

    @property
    def is_admin_user(self):
        return self.role == 'admin'
