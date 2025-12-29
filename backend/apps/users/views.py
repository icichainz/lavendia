from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth import get_user_model
from .models import PasswordResetToken
from .serializers import (
    UserSerializer,
    UserCreateSerializer,
    UserProfileSerializer,
    ChangePasswordSerializer,
    RequestPasswordResetSerializer,
    VerifyResetTokenSerializer,
    ResetPasswordSerializer
)

User = get_user_model()


class UserViewSet(viewsets.ModelViewSet):
    """ViewSet for User model"""
    queryset = User.objects.all()
    serializer_class = UserSerializer
    filterset_fields = ['role', 'is_active', 'laundromat']
    search_fields = ['username', 'email', 'phone', 'first_name', 'last_name']

    def get_serializer_class(self):
        if self.action == 'create':
            return UserCreateSerializer
        elif self.action in ['me', 'update_profile']:
            return UserProfileSerializer
        return UserSerializer

    def get_permissions(self):
        if self.action in ['create', 'request_password_reset', 'verify_reset_token', 'reset_password']:
            return [AllowAny()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['get'])
    def me(self, request):
        """Get current user profile"""
        serializer = self.get_serializer(request.user)
        return Response(serializer.data)

    @action(detail=False, methods=['put', 'patch'])
    def update_profile(self, request):
        """Update current user profile"""
        serializer = self.get_serializer(
            request.user,
            data=request.data,
            partial=True
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def change_password(self, request):
        """Change password for current user"""
        serializer = ChangePasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        user = request.user

        # Check old password
        if not user.check_password(serializer.validated_data['old_password']):
            return Response(
                {'old_password': 'Wrong password.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Set new password
        user.set_password(serializer.validated_data['new_password'])
        user.save()

        return Response({'message': 'Password updated successfully.'})

    @action(detail=False, methods=['post'])
    def upload_profile_picture(self, request):
        """Upload profile picture for current user"""
        if 'profile_picture' not in request.FILES:
            return Response(
                {'error': 'No file provided.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = request.user
        user.profile_picture = request.FILES['profile_picture']
        user.save()

        serializer = UserProfileSerializer(user, context={'request': request})
        return Response({
            'message': 'Profile picture uploaded successfully.',
            'user': serializer.data
        })

    @action(detail=False, methods=['get'])
    def customers(self, request):
        """Get all customers"""
        customers = User.objects.filter(role='customer')
        serializer = self.get_serializer(customers, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def staff(self, request):
        """Get all staff members"""
        staff = User.objects.filter(role='staff')
        serializer = self.get_serializer(staff, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['post'])
    def request_password_reset(self, request):
        """Request password reset - sends OTP to user"""
        serializer = RequestPasswordResetSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email_or_phone = serializer.validated_data['email_or_phone']
        user = User.objects.filter(email=email_or_phone).first() or User.objects.filter(phone=email_or_phone).first()

        if user:
            # Create reset token
            reset_token = PasswordResetToken.create_for_user(user)

            # In production, send OTP via email/SMS
            # For development, return the token in response
            return Response({
                'message': 'Password reset code has been sent.',
                'debug_token': reset_token.token  # Remove in production
            })

        return Response(
            {'error': 'No account found with this email or phone number.'},
            status=status.HTTP_404_NOT_FOUND
        )

    @action(detail=False, methods=['post'])
    def verify_reset_token(self, request):
        """Verify if reset token is valid"""
        serializer = VerifyResetTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email_or_phone = serializer.validated_data['email_or_phone']
        token = serializer.validated_data['token']

        user = User.objects.filter(email=email_or_phone).first() or User.objects.filter(phone=email_or_phone).first()

        if not user:
            return Response(
                {'error': 'No account found with this email or phone number.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Find valid token
        reset_token = PasswordResetToken.objects.filter(
            user=user,
            token=token,
            is_used=False
        ).first()

        if not reset_token or not reset_token.is_valid():
            return Response(
                {'error': 'Invalid or expired reset code.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response({'message': 'Reset code is valid.', 'valid': True})

    @action(detail=False, methods=['post'])
    def reset_password(self, request):
        """Reset password using valid token"""
        serializer = ResetPasswordSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        email_or_phone = serializer.validated_data['email_or_phone']
        token = serializer.validated_data['token']
        new_password = serializer.validated_data['new_password']

        user = User.objects.filter(email=email_or_phone).first() or User.objects.filter(phone=email_or_phone).first()

        if not user:
            return Response(
                {'error': 'No account found with this email or phone number.'},
                status=status.HTTP_404_NOT_FOUND
            )

        # Find valid token
        reset_token = PasswordResetToken.objects.filter(
            user=user,
            token=token,
            is_used=False
        ).first()

        if not reset_token or not reset_token.is_valid():
            return Response(
                {'error': 'Invalid or expired reset code.'},
                status=status.HTTP_400_BAD_REQUEST
            )

        # Reset password
        user.set_password(new_password)
        user.save()

        # Mark token as used
        reset_token.mark_used()

        return Response({'message': 'Password has been reset successfully.'})
