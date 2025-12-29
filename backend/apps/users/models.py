from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils import timezone
import random
import string


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
    profile_picture = models.ImageField(
        upload_to='profile_pictures/',
        null=True,
        blank=True,
        help_text='User profile picture'
    )
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


class PasswordResetToken(models.Model):
    """
    Model for storing password reset tokens (OTP)
    """
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='reset_tokens')
    token = models.CharField(max_length=6)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()
    is_used = models.BooleanField(default=False)

    class Meta:
        db_table = 'password_reset_tokens'
        ordering = ['-created_at']

    def __str__(self):
        return f"Reset token for {self.user.username}"

    @classmethod
    def generate_token(cls):
        """Generate a 6-digit OTP token"""
        return ''.join(random.choices(string.digits, k=6))

    @classmethod
    def create_for_user(cls, user):
        """Create a new reset token for a user, invalidating existing ones"""
        # Invalidate existing unused tokens
        cls.objects.filter(user=user, is_used=False).update(is_used=True)

        # Create new token with 15-minute expiry
        token = cls.generate_token()
        expires_at = timezone.now() + timezone.timedelta(minutes=15)

        return cls.objects.create(
            user=user,
            token=token,
            expires_at=expires_at
        )

    def is_valid(self):
        """Check if token is still valid"""
        return not self.is_used and timezone.now() < self.expires_at

    def mark_used(self):
        """Mark token as used"""
        self.is_used = True
        self.save()
