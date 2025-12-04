from django.contrib import admin
from .models import Receipt


@admin.register(Receipt)
class ReceiptAdmin(admin.ModelAdmin):
    list_display = ('receipt_number', 'customer', 'laundromat', 'status', 'price', 'drop_off_date', 'expected_pickup_date')
    list_filter = ('status', 'laundromat', 'drop_off_date')
    search_fields = ('receipt_number', 'customer__username', 'customer__phone')
    readonly_fields = ('receipt_number', 'qr_code', 'created_at', 'updated_at', 'drop_off_date')

    fieldsets = (
        ('Receipt Information', {
            'fields': ('receipt_number', 'laundromat', 'customer', 'staff')
        }),
        ('Status & Dates', {
            'fields': ('status', 'drop_off_date', 'expected_pickup_date', 'actual_pickup_date')
        }),
        ('Items', {
            'fields': ('items_description', 'items_count', 'special_instructions', 'price')
        }),
        ('QR Code', {
            'fields': ('qr_code',),
            'classes': ('collapse',)
        }),
        ('Timestamps', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
