from django.contrib import admin
from .models import Video


@admin.register(Video)
class VideoAdmin(admin.ModelAdmin):
    list_display = ('receipt', 'video_type', 'file_size_mb', 'duration', 'uploaded_at')
    list_filter = ('video_type', 'uploaded_at')
    search_fields = ('receipt__receipt_number',)
    readonly_fields = ('uploaded_at', 'updated_at', 'file_size', 'file_size_mb')

    fieldsets = (
        ('Video Information', {
            'fields': ('receipt', 'video_type', 'video_file', 'thumbnail')
        }),
        ('Metadata', {
            'fields': ('duration', 'file_size', 'file_size_mb')
        }),
        ('Timestamps', {
            'fields': ('uploaded_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
