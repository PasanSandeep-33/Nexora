import hashlib

from django.db import transaction

from .models import (
    Users,
    Events,
    RefreshSession,
    AdminMFADevice,
    AdminMFAChallenge,
)

from .mfa_service import (
    start_mfa_enrollment,
    complete_mfa_enrollment,
    verify_totp,
    consume_recovery_code,
)
from rest_framework.decorators import api_view, permission_classes, parser_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.exceptions import AuthenticationFailed
from rest_framework.parsers import MultiPartParser
from PIL import Image, UnidentifiedImageError
import cloudinary.uploader

from .serializers import EventSerializer, SignupSerializer
from django.contrib.auth.hashers import check_password
from django.utils import timezone as django_timezone
from .models import Users, Events, RefreshSession
from .serializers import LoginSerializer
from .authentication import (
    create_access_token,
    create_refresh_session,
    decode_refresh_token,
    rotate_refresh_token,
    hash_refresh_jti,
    create_mfa_challenge,
    decode_mfa_challenge,
)
from typing import cast
import logging

logger = logging.getLogger(__name__)


def _is_admin(user):
    return str(user.role).strip().lower() == "admin"


def _create_stored_mfa_challenge(user, purpose):
    token = create_mfa_challenge(user, purpose)

    payload = decode_mfa_challenge(token, purpose)

    jti_hash = hashlib.sha256(
        payload["jti"].encode("utf-8")
    ).hexdigest()

    expires_at = django_timezone.datetime.fromtimestamp(
        payload["exp"],
        tz=django_timezone.get_current_timezone(),
    )

    AdminMFAChallenge.objects.create(
        user=user,
        jti_hash=jti_hash,
        purpose=purpose,
        expires_at=expires_at,
    )

    return token


def _get_locked_challenge(token, purpose):
    payload = decode_mfa_challenge(token, purpose)

    jti_hash = hashlib.sha256(
        payload["jti"].encode("utf-8")
    ).hexdigest()

    challenge = (
        AdminMFAChallenge.objects
        .select_for_update()
        .filter(
            user_id=payload["sub"],
            jti_hash=jti_hash,
            purpose=purpose,
            consumed_at__isnull=True,
            expires_at__gt=django_timezone.now(),
        )
        .first()
    )

    if challenge is None:
        raise ValueError("Invalid, expired or already used MFA challenge.")

    return challenge


def _issue_admin_tokens(user):
    if not AdminMFADevice.objects.filter(
        user=user,
        is_enabled=True,
    ).exists():
        raise ValueError("Administrator MFA is not enabled.")

    access_token = create_access_token(
        user,
        mfa_verified=True,
    )

    refresh_token = create_refresh_session(
        user,
        mfa_verified=True,
    )

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "Bearer",
        "expires_in": 1800,
        "refresh_expires_in": 604800,
        "user": {
            "user_id": user.user_id,
            "full_name": user.full_name,
            "email": user.email,
            "role": user.role,
            "profile_image_url": user.profile_image_url,
        },
    }


@api_view(['GET'])
@permission_classes([AllowAny])
def event_list(request):
    events = Events.objects.filter(
        approval_status='approved'
    ).order_by('event_date')

    serializer = EventSerializer(events, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    serializer = SignupSerializer(data=request.data)

    if serializer.is_valid():
        user = cast(Users, serializer.save())

        return Response(
            {
                'message': 'Account created successfully',
                'user_id': user.user_id,
                'email': user.email,
                'role': user.role,
                'profile_image_url': user.profile_image_url,
            },
            status=status.HTTP_201_CREATED
        )

    return Response(
        serializer.errors,
        status=status.HTTP_400_BAD_REQUEST
    )



@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    serializer = LoginSerializer(data=request.data)

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    validated_data = serializer.validated_data

    if validated_data is None:
        return Response(
            {"message": "Invalid login data"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    validated_data = serializer.validated_data

    if validated_data is None:
        return Response(
            {"message": "Invalid login data"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    validated_data = cast(dict, validated_data)

    email = str(validated_data["email"]).strip().lower()
    password = str(validated_data["password"])

    user = Users.objects.filter(
        email__iexact=email
    ).first()

    if user is None or not check_password(
        password, user.password_hash
    ):
        return Response(
            {'message': 'Invalid email or password'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    # STUDENT LOGIN: Keep the existing flow.
    if not _is_admin(user):
        access_token = create_access_token(user)
        refresh_token = create_refresh_session(user)

        return Response({
            'message': 'Login successful',
            'access_token': access_token,
            'refresh_token': refresh_token,
            'token_type': 'Bearer',
            'expires_in': 1800,
            'refresh_expires_in': 604800,
            'user': {
                'user_id': user.user_id,
                'full_name': user.full_name,
                'email': user.email,
                'role': user.role,
                'profile_image_url': user.profile_image_url,
            }
        }, status=status.HTTP_200_OK)

    # ADMIN LOGIN: MFA is mandatory.
    device = AdminMFADevice.objects.filter(
        user=user
    ).first()

    if device is None or not device.is_enabled:
        challenge = _create_stored_mfa_challenge(
            user,
            "setup",
        )

        return Response({
            "mfa_required": True,
            "mfa_setup_required": True,
            "challenge_token": challenge,
            "message": "Administrator MFA setup required.",
        }, status=status.HTTP_200_OK)

    challenge = _create_stored_mfa_challenge(
        user,
        "login",
    )

    return Response({
        "mfa_required": True,
        "mfa_setup_required": False,
        "challenge_token": challenge,
        "message": "Enter your authenticator code.",
    }, status=status.HTTP_200_OK)


# Protected User Profile API
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile(request):
    try:
        user = Users.objects.get(
            user_id=request.user.user_id
        )
    except Users.DoesNotExist:
        return Response(
            {'message': 'User not found'},
            status=status.HTTP_404_NOT_FOUND,
        )

    return Response({
        'user_id': user.user_id,
        'full_name': user.full_name,
        'email': user.email,
        'role': user.role,
        'profile_image_url': user.profile_image_url,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser])
def upload_profile_image(request):
    image = request.FILES.get('image')
    if image is None:
        return Response(
            {'message': 'Image is required'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if image.size > 2 * 1024 * 1024:
        return Response(
            {'message': 'Image must be 2 MB or smaller'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        image.seek(0)
        with Image.open(image) as img:
            if img.format not in ('JPEG', 'PNG', 'WEBP'):
                raise ValueError('Unsupported image format')
            img.verify()
        image.seek(0)
    except (UnidentifiedImageError, ValueError, OSError):
        return Response(
            {'message': 'Invalid image. Use JPG, PNG, or WebP'},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        result = cloudinary.uploader.upload(
            image,
            folder='nexora/profile_images',
            resource_type='image',
        )
    except Exception:
        logger.exception("CLOUDINARY PROFILE IMAGE UPLOAD FAILED")
        return Response(
            {"message": "Image upload failed"},
            status=502,
        )

    # Get the authenticated user's database record
    user = Users.objects.get(
        user_id=request.user.user_id
    )

    # Save Cloudinary URL to PostgreSQL
    user.profile_image_url = result['secure_url']
    user.save(update_fields=['profile_image_url'])

    return Response({
        'message': 'Profile image updated successfully',
        'profile_image_url': user.profile_image_url,
    })


@api_view(["POST"])
@permission_classes([AllowAny])
def refresh_token(request):
    token = request.data.get("refresh_token")

    if not isinstance(token, str) or not token:
        return Response(
            {"message": "Refresh token is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        access_token, new_refresh_token = rotate_refresh_token(token)
    except (AuthenticationFailed, Users.DoesNotExist):
        return Response(
            {"message": "Invalid or expired refresh token"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    return Response(
        {
            "access_token": access_token,
            "refresh_token": new_refresh_token,
            "token_type": "Bearer",
            "expires_in": 1800,
        },
        status=status.HTTP_200_OK,
    )

@api_view(["POST"])
@permission_classes([AllowAny])
def logout(request):
    token = request.data.get("refresh_token")

    if not isinstance(token, str) or not token:
        return Response(
            {"message": "Refresh token is required"},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        payload = decode_refresh_token(token)
    except AuthenticationFailed:
        return Response(
            {"message": "Invalid refresh token"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    updated = RefreshSession.objects.filter(
        token_jti_hash=hash_refresh_jti(payload["jti"]),
        user_id=payload["sub"],
        revoked_at__isnull=True,
    ).update(revoked_at=django_timezone.now())

    if not updated:
        return Response(
            {"message": "Session already invalid"},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    return Response({"message": "Logged out successfully"})


@api_view(["POST"])
@permission_classes([AllowAny])
def admin_mfa_setup(request):
    token = request.data.get("challenge_token")

    if not isinstance(token, str) or not token:
        return Response(
            {"message": "MFA challenge token is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        with transaction.atomic():
            challenge = _get_locked_challenge(token, "setup")
            user = challenge.user

            if not _is_admin(user):
                raise ValueError("Administrator account required.")

            device = AdminMFADevice.objects.filter(
                user=user,
                is_enabled=True,
            ).first()

            if device:
                raise ValueError("MFA is already enabled.")

            enrollment = start_mfa_enrollment(user)

            challenge.consumed_at = django_timezone.now()
            challenge.save(update_fields=["consumed_at"])

            enrollment_token = _create_stored_mfa_challenge(
                user,
                "enroll",
            )

        return Response({
            "message": "Scan the QR code with your authenticator app.",
            "qr_code": enrollment["qr_code"],
            "manual_secret": enrollment["manual_secret"],
            "enrollment_token": enrollment_token,
        }, status=status.HTTP_200_OK)

    except Exception as error:
        logger.exception("MFA setup failed")

        return Response(
            {"message": str(error) if isinstance(error, ValueError)
             else "Unable to start MFA setup."},
            status=status.HTTP_400_BAD_REQUEST,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def admin_mfa_verify_setup(request):
    token = request.data.get("enrollment_token")
    code = request.data.get("code")

    if not isinstance(token, str) or not isinstance(code, str):
        return Response(
            {"message": "Enrollment token and code are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        with transaction.atomic():
            challenge = _get_locked_challenge(token, "enroll")
            user = challenge.user

            if not _is_admin(user):
                raise ValueError("Administrator account required.")

            recovery_codes = complete_mfa_enrollment(
                user,
                code,
            )

            challenge.consumed_at = django_timezone.now()
            challenge.save(update_fields=["consumed_at"])

            tokens = _issue_admin_tokens(user)

        return Response({
            "message": "Administrator MFA enabled successfully.",
            **tokens,
            "recovery_codes": recovery_codes,
        }, status=status.HTTP_200_OK)

    except ValueError as error:
        return Response(
            {"message": str(error)},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    except Exception:
        logger.exception("MFA enrollment verification failed")
        return Response(
            {"message": "Unable to verify MFA enrollment."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def admin_mfa_verify_login(request):
    token = request.data.get("challenge_token")
    code = request.data.get("code")

    if not isinstance(token, str) or not isinstance(code, str):
        return Response(
            {"message": "Challenge token and authenticator code are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        with transaction.atomic():
            challenge = _get_locked_challenge(token, "login")
            user = challenge.user

            if not _is_admin(user):
                raise ValueError("Administrator account required.")

            if not verify_totp(user, code):
                raise ValueError("Invalid or already used authenticator code.")

            challenge.consumed_at = django_timezone.now()
            challenge.save(update_fields=["consumed_at"])

            tokens = _issue_admin_tokens(user)

        return Response({
            "message": "Administrator login successful.",
            **tokens,
        }, status=status.HTTP_200_OK)

    except ValueError as error:
        return Response(
            {"message": str(error)},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    except Exception:
        logger.exception("Administrator MFA login failed")
        return Response(
            {"message": "Unable to verify administrator login."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


@api_view(["POST"])
@permission_classes([AllowAny])
def admin_mfa_recovery(request):
    token = request.data.get("challenge_token")
    recovery_code = request.data.get("recovery_code")

    if not isinstance(token, str) or not isinstance(recovery_code, str):
        return Response(
            {"message": "Challenge token and recovery code are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        with transaction.atomic():
            challenge = _get_locked_challenge(token, "login")
            user = challenge.user

            if not _is_admin(user):
                raise ValueError("Administrator account required.")

            if not consume_recovery_code(user, recovery_code):
                raise ValueError("Invalid or already used recovery code.")

            challenge.consumed_at = django_timezone.now()
            challenge.save(update_fields=["consumed_at"])

            tokens = _issue_admin_tokens(user)

        return Response({
            "message": "Administrator login successful using recovery code.",
            **tokens,
        }, status=status.HTTP_200_OK)

    except ValueError as error:
        return Response(
            {"message": str(error)},
            status=status.HTTP_401_UNAUTHORIZED,
        )

    except Exception:
        logger.exception("MFA recovery failed")
        return Response(
            {"message": "Unable to verify recovery code."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )
