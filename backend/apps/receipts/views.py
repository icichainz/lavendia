from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Receipt
from .serializers import (
    ReceiptSerializer,
    ReceiptCreateSerializer,
    ReceiptListSerializer,
    ReceiptUpdateStatusSerializer,
    ReceiptCompleteSerializer
)


class ReceiptViewSet(viewsets.ModelViewSet):
    """ViewSet for Receipt model"""
    queryset = Receipt.objects.select_related(
        'customer', 'staff', 'laundromat'
    ).prefetch_related('videos')
    serializer_class = ReceiptSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['status', 'laundromat', 'customer', 'staff']
    search_fields = ['receipt_number', 'customer__username', 'customer__phone']
    ordering_fields = ['created_at', 'drop_off_date', 'expected_pickup_date']

    def get_serializer_class(self):
        if self.action == 'create':
            return ReceiptCreateSerializer
        elif self.action == 'list':
            return ReceiptListSerializer
        elif self.action == 'update_status':
            return ReceiptUpdateStatusSerializer
        elif self.action == 'complete':
            return ReceiptCompleteSerializer
        return ReceiptSerializer

    def get_queryset(self):
        """Filter receipts based on user role"""
        user = self.request.user
        queryset = super().get_queryset()

        if user.is_customer:
            # Customers can only see their own receipts
            return queryset.filter(customer=user)
        elif user.is_staff_member and user.laundromat:
            # Staff can see receipts from their laundromat
            return queryset.filter(laundromat=user.laundromat)

        # Admins can see all receipts
        return queryset

    def create(self, request, *args, **kwargs):
        """Create receipt and return full receipt data"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        receipt = serializer.save()
        # Return full receipt data using ReceiptSerializer
        response_serializer = ReceiptSerializer(receipt, context={'request': request})
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)

    @action(detail=False, methods=['get'])
    def active(self, request):
        """Get all active receipts (not completed/cancelled)"""
        receipts = self.get_queryset().exclude(status__in=['completed', 'cancelled'])
        page = self.paginate_queryset(receipts)
        if page is not None:
            serializer = ReceiptListSerializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = ReceiptListSerializer(receipts, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def my_receipts(self, request):
        """Get current user's receipts"""
        receipts = Receipt.objects.filter(customer=request.user)
        serializer = ReceiptListSerializer(receipts, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['patch'])
    def update_status(self, request, pk=None):
        """Update receipt status"""
        receipt = self.get_object()
        serializer = self.get_serializer(receipt, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ReceiptSerializer(receipt, context={'request': request}).data)

    @action(detail=True, methods=['post'])
    def complete(self, request, pk=None):
        """Mark receipt as completed (customer picked up)"""
        receipt = self.get_object()

        if receipt.status == 'completed':
            return Response(
                {'error': 'Receipt already completed'},
                status=status.HTTP_400_BAD_REQUEST
            )

        serializer = self.get_serializer(
            receipt,
            data={'actual_pickup_date': timezone.now()},
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()

        return Response(ReceiptSerializer(receipt, context={'request': request}).data)

    @action(detail=True, methods=['get'])
    def qr_code(self, request, pk=None):
        """Get QR code for receipt"""
        receipt = self.get_object()
        if receipt.qr_code:
            return Response({
                'qr_code_url': request.build_absolute_uri(receipt.qr_code.url),
                'receipt_number': receipt.receipt_number
            })
        return Response(
            {'error': 'QR code not found'},
            status=status.HTTP_404_NOT_FOUND
        )
