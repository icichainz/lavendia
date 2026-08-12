from django.contrib.auth import get_user_model
from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase
from rest_framework_simplejwt.tokens import RefreshToken

User = get_user_model()


class RefreshTokenRotationTests(APITestCase):
    """
    SIMPLE_JWT sets ROTATE_REFRESH_TOKENS and BLACKLIST_AFTER_ROTATION, but
    blacklisting is a no-op unless rest_framework_simplejwt.token_blacklist is
    in INSTALLED_APPS - simplejwt calls RefreshToken.blacklist() inside a
    try/except AttributeError, so a missing app fails silently and rotated
    tokens stay valid for their full lifetime.

    These tests fail if that app is ever removed again.
    """

    def setUp(self):
        self.password = 'test-pass-12345'
        self.user = User.objects.create_user(
            username='rotation_user',
            password=self.password,
            phone='+15550000001',
            role='customer',
        )
        self.refresh_url = reverse('token_refresh')

    def test_blacklist_app_is_installed(self):
        """The blacklist machinery must actually be wired up."""
        from django.apps import apps

        self.assertTrue(
            apps.is_installed('rest_framework_simplejwt.token_blacklist'),
            'token_blacklist missing from INSTALLED_APPS - BLACKLIST_AFTER_ROTATION '
            'silently does nothing without it',
        )

    def test_refresh_token_class_supports_blacklisting(self):
        """RefreshToken gains .blacklist() only when the app is installed."""
        token = RefreshToken.for_user(self.user)
        self.assertTrue(
            hasattr(token, 'blacklist'),
            'RefreshToken has no blacklist() - rotation cannot invalidate old tokens',
        )

    def test_rotation_returns_a_new_refresh_token(self):
        original = str(RefreshToken.for_user(self.user))

        response = self.client.post(
            self.refresh_url, {'refresh': original}, format='json'
        )

        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('access', response.data)
        self.assertIn('refresh', response.data)
        self.assertNotEqual(
            response.data['refresh'],
            original,
            'ROTATE_REFRESH_TOKENS is on, so refresh must return a fresh token',
        )

    def test_old_refresh_token_is_rejected_after_rotation(self):
        """The regression this fix exists for."""
        original = str(RefreshToken.for_user(self.user))

        first = self.client.post(
            self.refresh_url, {'refresh': original}, format='json'
        )
        self.assertEqual(first.status_code, status.HTTP_200_OK)

        # Replaying the now-rotated token must not mint more credentials.
        replay = self.client.post(
            self.refresh_url, {'refresh': original}, format='json'
        )
        self.assertEqual(
            replay.status_code,
            status.HTTP_401_UNAUTHORIZED,
            'Rotated refresh token was accepted again - it was never blacklisted',
        )

    def test_rotated_replacement_token_still_works(self):
        """Blacklisting the old token must not break the new one."""
        original = str(RefreshToken.for_user(self.user))

        first = self.client.post(
            self.refresh_url, {'refresh': original}, format='json'
        )
        rotated = first.data['refresh']

        second = self.client.post(
            self.refresh_url, {'refresh': rotated}, format='json'
        )
        self.assertEqual(second.status_code, status.HTTP_200_OK)
        self.assertIn('access', second.data)
