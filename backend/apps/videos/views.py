from rest_framework import viewsets, status, parsers
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Video
from .serializers import VideoSerializer, VideoUploadSerializer, VideoListSerializer


class VideoViewSet(viewsets.ModelViewSet):
    """ViewSet for Video model"""
    queryset = Video.objects.select_related('receipt')
    serializer_class = VideoSerializer
    permission_classes = [IsAuthenticated]
    filterset_fields = ['video_type', 'receipt']
    parser_classes = (parsers.MultiPartParser, parsers.FormParser, parsers.JSONParser)

    def get_serializer_class(self):
        if self.action == 'create':
            return VideoUploadSerializer
        elif self.action == 'list':
            return VideoListSerializer
        return VideoSerializer

    def get_queryset(self):
        """Filter videos based on user role"""
        user = self.request.user
        queryset = super().get_queryset()

        if user.is_customer:
            # Customers can only see videos from their receipts
            return queryset.filter(receipt__customer=user)
        elif user.is_staff_member and user.laundromat:
            # Staff can see videos from their laundromat's receipts
            return queryset.filter(receipt__laundromat=user.laundromat)

        # Admins can see all videos
        return queryset

    @action(detail=False, methods=['get'])
    def by_receipt(self, request):
        """Get all videos for a specific receipt"""
        receipt_id = request.query_params.get('receipt_id')
        if not receipt_id:
            return Response(
                {'error': 'receipt_id parameter is required'},
                status=status.HTTP_400_BAD_REQUEST
            )

        videos = self.get_queryset().filter(receipt_id=receipt_id)
        serializer = self.get_serializer(videos, many=True, context={'request': request})
        return Response(serializer.data)
