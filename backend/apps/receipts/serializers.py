from rest_framework import serializers
from .models import Receipt
from apps.videos.serializers import VideoListSerializer
from apps.users.serializers import UserSerializer
from apps.laundromats.serializers import LaundromatListSerializer


class ReceiptSerializer(serializers.ModelSerializer):
    """Full serializer for Receipt model"""
    videos = VideoListSerializer(many=True, read_only=True)
    customer = UserSerializer(read_only=True)
    staff = UserSerializer(read_only=True)
    laundromat = LaundromatListSerializer(read_only=True)
    is_active = serializers.BooleanField(read_only=True)
    days_since_dropoff = serializers.IntegerField(read_only=True)
    qr_code_url = serializers.SerializerMethodField()

    class Meta:
        model = Receipt
        fields = (
            'id', 'receipt_number', 'laundromat', 'customer', 'staff',
            'status', 'drop_off_date', 'expected_pickup_date', 'actual_pickup_date',
            'items_description', 'items_count', 'special_instructions', 'price',
            'qr_code', 'qr_code_url', 'videos', 'is_active', 'days_since_dropoff',
            'created_at', 'updated_at'
        )
        read_only_fields = (
            'id', 'receipt_number', 'qr_code', 'drop_off_date',
            'created_at', 'updated_at'
        )

    def get_qr_code_url(self, obj):
        """Get full URL for QR code"""
        request = self.context.get('request')
        if obj.qr_code and request:
            return request.build_absolute_uri(obj.qr_code.url)
        return None


class ReceiptCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating receipts"""
    customer_id = serializers.IntegerField(write_only=True)
    staff_id = serializers.IntegerField(write_only=True, required=False)
    laundromat_id = serializers.IntegerField(write_only=True)

    class Meta:
        model = Receipt
        fields = (
            'customer_id', 'staff_id', 'laundromat_id',
            'expected_pickup_date', 'items_description', 'items_count',
            'special_instructions', 'price'
        )

    def create(self, validated_data):
        from apps.users.models import User
        from apps.laundromats.models import Laundromat

        customer_id = validated_data.pop('customer_id')
        staff_id = validated_data.pop('staff_id', None)
        laundromat_id = validated_data.pop('laundromat_id')

        validated_data['customer_id'] = customer_id
        validated_data['laundromat_id'] = laundromat_id

        if staff_id:
            validated_data['staff_id'] = staff_id

        receipt = Receipt.objects.create(**validated_data)
        return receipt


class ReceiptListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing receipts"""
    customer_name = serializers.CharField(source='customer.username', read_only=True)
    laundromat_name = serializers.CharField(source='laundromat.name', read_only=True)

    class Meta:
        model = Receipt
        fields = (
            'id', 'receipt_number', 'customer_name', 'laundromat_name',
            'status', 'drop_off_date', 'expected_pickup_date', 'price',
            'items_count', 'items_description'
        )


class ReceiptUpdateStatusSerializer(serializers.ModelSerializer):
    """Serializer for updating receipt status"""

    class Meta:
        model = Receipt
        fields = ('status',)


class ReceiptCompleteSerializer(serializers.ModelSerializer):
    """Serializer for completing receipt (pickup)"""

    class Meta:
        model = Receipt
        fields = ('actual_pickup_date',)

    def update(self, instance, validated_data):
        instance.status = 'completed'
        instance.actual_pickup_date = validated_data.get('actual_pickup_date')
        instance.save()
        return instance
