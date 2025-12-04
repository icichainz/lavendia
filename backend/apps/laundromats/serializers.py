from rest_framework import serializers
from .models import Laundromat


class LaundromatSerializer(serializers.ModelSerializer):
    """Serializer for Laundromat model"""
    staff_count = serializers.IntegerField(read_only=True)
    active_receipts_count = serializers.IntegerField(read_only=True)

    class Meta:
        model = Laundromat
        fields = (
            'id', 'name', 'address', 'phone', 'email',
            'is_active', 'staff_count', 'active_receipts_count',
            'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'created_at', 'updated_at')


class LaundromatListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing laundromats"""

    class Meta:
        model = Laundromat
        fields = ('id', 'name', 'address', 'phone', 'is_active')
