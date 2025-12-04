from django.db import models
from django.core.exceptions import ValidationError


def validate_video_file_extension(value):
    """Validate that uploaded file is a video"""
    import os
    ext = os.path.splitext(value.name)[1]
    valid_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.webm']
    if ext.lower() not in valid_extensions:
        raise ValidationError(f'Unsupported file extension. Allowed: {", ".join(valid_extensions)}')


class Video(models.Model):
    """
    Video model for storing receipt videos (intake and completion)
    """
    VIDEO_TYPE_CHOICES = (
        ('intake', 'Intake Video'),
        ('completion', 'Completion Video'),
    )

    receipt = models.ForeignKey(
        'receipts.Receipt',
        on_delete=models.CASCADE,
        related_name='videos'
    )
    video_type = models.CharField(max_length=20, choices=VIDEO_TYPE_CHOICES)
    video_file = models.FileField(
        upload_to='videos/%Y/%m/%d/',
        validators=[validate_video_file_extension],
        help_text='Video file (max 50MB)'
    )
    thumbnail = models.ImageField(upload_to='thumbnails/%Y/%m/%d/', blank=True, null=True)
    duration = models.IntegerField(null=True, blank=True, help_text='Duration in seconds')
    file_size = models.BigIntegerField(null=True, blank=True, help_text='File size in bytes')

    uploaded_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'videos'
        ordering = ['-uploaded_at']
        indexes = [
            # index for fast foreign-key lookups
            models.Index(fields=['receipt']),
            # index to speed up listing videos for a receipt ordered by time
            models.Index(fields=['receipt', 'uploaded_at']),
            # index to speed up filtering by video_type
            models.Index(fields=['video_type']),
            # index to speed up global ordering/filtering by upload time
            models.Index(fields=['uploaded_at']),
        ]
        constraints = [
            # ensure one video type per receipt
            models.UniqueConstraint(fields=['receipt', 'video_type'], name='unique_receipt_video_type'),
        ]

    def __str__(self):
        return f"{self.get_video_type_display()} - {self.receipt.receipt_number}"

    def save(self, *args, **kwargs):
        if self.video_file:
            self.file_size = self.video_file.size
        super().save(*args, **kwargs)

    @property
    def file_size_mb(self):
        """Get file size in MB"""
        if self.file_size:
            return round(self.file_size / (1024 * 1024), 2)
        return 0
