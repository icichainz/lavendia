from rest_framework import serializers
from .models import Video


class VideoSerializer(serializers.ModelSerializer):
    """Serializer for Video model"""
    file_size_mb = serializers.FloatField(read_only=True)
    video_url = serializers.SerializerMethodField()

    class Meta:
        model = Video
        fields = (
            'id', 'receipt', 'video_type', 'video_file', 'video_url',
            'thumbnail', 'duration', 'file_size', 'file_size_mb',
            'uploaded_at', 'updated_at'
        )
        read_only_fields = ('id', 'file_size', 'uploaded_at', 'updated_at')

    def get_video_url(self, obj):
        """Get full URL for video file"""
        request = self.context.get('request')
        if obj.video_file and request:
            return request.build_absolute_uri(obj.video_file.url)
        return None


class VideoUploadSerializer(serializers.ModelSerializer):
    """Serializer for uploading videos"""

    class Meta:
        model = Video
        fields = ('receipt', 'video_type', 'video_file', 'thumbnail', 'duration')


class VideoListSerializer(serializers.ModelSerializer):
    """Lightweight serializer for listing videos"""

    class Meta:
        model = Video
        fields = ('id', 'video_type', 'thumbnail', 'duration', 'file_size_mb', 'uploaded_at')
