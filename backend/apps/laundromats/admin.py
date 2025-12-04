from django.contrib import admin
from .models import Laundromat


@admin.register(Laundromat)
class LaundromatAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'is_active', 'staff_count', 'active_receipts_count', 'created_at')
    list_filter = ('is_active', 'created_at')
    search_fields = ('name', 'address', 'phone', 'email')
    readonly_fields = ('created_at', 'updated_at')

    fieldsets = (
        ('Basic Information', {
            'fields': ('name', 'address', 'phone', 'email')
        }),
        ('Status', {
            'fields': ('is_active',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
