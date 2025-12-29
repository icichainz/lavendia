from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Serializer for User model"""
    profile_picture_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'phone', 'role',
            'first_name', 'last_name', 'profile_picture', 'profile_picture_url',
            'laundromat', 'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'profile_picture_url', 'created_at', 'updated_at')

    def get_profile_picture_url(self, obj):
        """Get full URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None


class UserCreateSerializer(serializers.ModelSerializer):
    """Serializer for creating new users"""
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password_confirm = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = (
            'username', 'email', 'phone', 'password', 'password_confirm',
            'role', 'first_name', 'last_name', 'laundromat'
        )

    def validate(self, attrs):
        if attrs['password'] != attrs['password_confirm']:
            raise serializers.ValidationError({"password": "Password fields didn't match."})
        return attrs

    def create(self, validated_data):
        validated_data.pop('password_confirm')
        user = User.objects.create_user(**validated_data)
        return user


class UserProfileSerializer(serializers.ModelSerializer):
    """Detailed serializer for user profile"""
    laundromat_name = serializers.CharField(source='laundromat.name', read_only=True)
    profile_picture_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'phone', 'role',
            'first_name', 'last_name', 'profile_picture', 'profile_picture_url',
            'laundromat', 'laundromat_name',
            'is_active', 'created_at', 'updated_at'
        )
        read_only_fields = ('id', 'role', 'profile_picture_url', 'created_at', 'updated_at')

    def get_profile_picture_url(self, obj):
        """Get full URL for profile picture"""
        if obj.profile_picture:
            request = self.context.get('request')
            if request:
                return request.build_absolute_uri(obj.profile_picture.url)
            return obj.profile_picture.url
        return None


class ChangePasswordSerializer(serializers.Serializer):
    """Serializer for changing password"""
    old_password = serializers.CharField(required=True)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs


class RequestPasswordResetSerializer(serializers.Serializer):
    """Serializer for requesting password reset"""
    email_or_phone = serializers.CharField(required=True)

    def validate_email_or_phone(self, value):
        # Check if user exists with this email or phone
        user = User.objects.filter(email=value).first() or User.objects.filter(phone=value).first()
        if not user:
            raise serializers.ValidationError("No account found with this email or phone number.")
        return value


class VerifyResetTokenSerializer(serializers.Serializer):
    """Serializer for verifying reset token"""
    email_or_phone = serializers.CharField(required=True)
    token = serializers.CharField(required=True, max_length=6, min_length=6)


class ResetPasswordSerializer(serializers.Serializer):
    """Serializer for resetting password with token"""
    email_or_phone = serializers.CharField(required=True)
    token = serializers.CharField(required=True, max_length=6, min_length=6)
    new_password = serializers.CharField(required=True, validators=[validate_password])
    new_password_confirm = serializers.CharField(required=True)

    def validate(self, attrs):
        if attrs['new_password'] != attrs['new_password_confirm']:
            raise serializers.ValidationError({"new_password": "Password fields didn't match."})
        return attrs
