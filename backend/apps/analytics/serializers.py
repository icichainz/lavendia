from rest_framework import serializers


class OverviewSerializer(serializers.Serializer):
    """Serializer for analytics overview data"""
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_orders = serializers.IntegerField()
    active_orders = serializers.IntegerField()
    completed_orders = serializers.IntegerField()
    cancelled_orders = serializers.IntegerField()
    total_customers = serializers.IntegerField()
    average_order_value = serializers.DecimalField(max_digits=10, decimal_places=2)
    time_range = serializers.CharField()


class RevenueTrendSerializer(serializers.Serializer):
    """Serializer for revenue trend data points"""
    date = serializers.DateField()
    revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    order_count = serializers.IntegerField()


class StatusDistributionSerializer(serializers.Serializer):
    """Serializer for order status distribution"""
    status = serializers.CharField()
    count = serializers.IntegerField()
    percentage = serializers.FloatField()


class TopCustomerSerializer(serializers.Serializer):
    """Serializer for top customers data"""
    customer_id = serializers.IntegerField()
    customer_name = serializers.CharField()
    customer_email = serializers.CharField(allow_null=True)
    customer_phone = serializers.CharField(allow_null=True)
    order_count = serializers.IntegerField()
    total_spent = serializers.DecimalField(max_digits=12, decimal_places=2)


class StaffPerformanceSerializer(serializers.Serializer):
    """Serializer for staff performance metrics"""
    staff_id = serializers.IntegerField()
    staff_name = serializers.CharField()
    order_count = serializers.IntegerField()
    completed_orders = serializers.IntegerField()
    avg_processing_hours = serializers.FloatField(allow_null=True)
    total_revenue = serializers.DecimalField(max_digits=12, decimal_places=2)


class LaundromatComparisonSerializer(serializers.Serializer):
    """Serializer for laundromat comparison (admin only)"""
    laundromat_id = serializers.IntegerField()
    laundromat_name = serializers.CharField()
    revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
    order_count = serializers.IntegerField()
    customer_count = serializers.IntegerField()
    active_orders = serializers.IntegerField()
    avg_order_value = serializers.DecimalField(max_digits=10, decimal_places=2, allow_null=True)


class PeakHoursSerializer(serializers.Serializer):
    """Serializer for peak hours analysis"""
    hour = serializers.IntegerField()
    order_count = serializers.IntegerField()
    revenue = serializers.DecimalField(max_digits=12, decimal_places=2)
