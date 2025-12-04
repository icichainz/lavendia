"""
URL configuration for Lavendia API
"""
from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

# Import viewsets
from apps.users.views import UserViewSet
from apps.laundromats.views import LaundromatViewSet
from apps.receipts.views import ReceiptViewSet
from apps.videos.views import VideoViewSet

# Create router and register viewsets
router = DefaultRouter()
router.register(r'users', UserViewSet, basename='user')
router.register(r'laundromats', LaundromatViewSet, basename='laundromat')
router.register(r'receipts', ReceiptViewSet, basename='receipt')
router.register(r'videos', VideoViewSet, basename='video')

urlpatterns = [
    # Admin
    path('admin/', admin.site.urls),

    # API Routes
    path('api/', include(router.urls)),

    # Authentication
    path('api/auth/login/', TokenObtainPairView.as_view(), name='token_obtain_pair'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='token_refresh'),

    # API Documentation
    path('api/schema/', SpectacularAPIView.as_view(), name='schema'),
    path('api/docs/', SpectacularSwaggerView.as_view(url_name='schema'), name='swagger-ui'),
]

# Serve media files in development
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
    urlpatterns += static(settings.STATIC_URL, document_root=settings.STATIC_ROOT)
