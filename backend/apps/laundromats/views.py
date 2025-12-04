from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Laundromat
from .serializers import LaundromatSerializer, LaundromatListSerializer


class LaundromatViewSet(viewsets.ModelViewSet):
    """ViewSet for Laundromat model"""
    queryset = Laundromat.objects.all()
    serializer_class = LaundromatSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['is_active']
    search_fields = ['name', 'address', 'phone']

    def get_serializer_class(self):
        if self.action == 'list':
            return LaundromatListSerializer
        return LaundromatSerializer

    @action(detail=True, methods=['get'])
    def receipts(self, request, pk=None):
        """Get all receipts for a laundromat"""
        laundromat = self.get_object()
        from apps.receipts.serializers import ReceiptListSerializer
        receipts = laundromat.receipts.all()
        serializer = ReceiptListSerializer(receipts, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def staff(self, request, pk=None):
        """Get all staff members for a laundromat"""
        laundromat = self.get_object()
        from apps.users.serializers import UserSerializer
        staff = laundromat.staff_members.all()
        serializer = UserSerializer(staff, many=True)
        return Response(serializer.data)
