
from .email_verification import send_verification_email
from django.db import transaction
from django.utils import timezone
from .models import EmailVerificationToken
from .email_verification import hash_verification_token

from rest_framework.decorators import (
    api_view,
    permission_classes,
    parser_classes,
    throttle_classes,
)
import hashlib
from django.core.cache import cache
from rest_framework.throttling import AnonRateThrottle
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
)
from typing import cast
import logging

logger = logging.getLogger(__name__)

@api_view(['GET'])
@permission_classes([AllowAny])
def event_list(request):
    events = Events.objects.filter(
        approval_status='approved'
    ).order_by('event_date')

    serializer = EventSerializer(events, many=True)
    return Response(serializer.data)



@api_view(["POST"])
@permission_classes([AllowAny])
def signup(request):
    serializer = SignupSerializer(data=request.data)

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST,
        )

    user = cast(Users, serializer.save())

    email_sent = False

    try:
        send_verification_email(user)
        email_sent = True
    except Exception:
        # Keep signup successful if email delivery fails.
        # A resend endpoint will be added later.
        import logging
        logging.getLogger(__name__).exception(
            "Verification email delivery failed for user_id=%s",
            user.user_id,
        )

    return Response(
        {
            "message": (
                "Account created successfully. "
                "Please verify your email address."
            ),
            "user_id": user.user_id,
            "email": user.email,
            "role": user.role,
            "profile_image_url": user.profile_image_url,
            "email_verified": False,
            "verification_email_sent": email_sent,
        },
        status=status.HTTP_201_CREATED,
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

    validated_data = cast(dict, serializer.validated_data)

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

    access_token = create_access_token(user)
    refresh_token = create_refresh_session(user)

    return Response(
        {
            'message': 'Login credentials verified successfully',
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
        },
        status=status.HTTP_200_OK
    )

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
def verify_email(request):
    token = request.data.get("token")

    if not isinstance(token, str) or not token:
        return Response(
            {"error": "Verification token is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    token_hash = hash_verification_token(token)

    with transaction.atomic():
        verification = (
            EmailVerificationToken.objects
            .select_for_update()
            .filter(token_hash=token_hash)
            .first()
        )

        if verification is None:
            return Response(
                {"error": "Invalid verification token."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if verification.used_at is not None:
            return Response(
                {"error": "This verification token has already been used."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        if verification.expires_at <= timezone.now():
            return Response(
                {"error": "Verification token has expired."},
                status=status.HTTP_400_BAD_REQUEST,
            )

        user = verification.user

        user.email_verified = True
        user.email_verified_at = timezone.now()
        user.save(
            update_fields=["email_verified", "email_verified_at"]
        )

        verification.used_at = timezone.now()
        verification.save(update_fields=["used_at"])

        EmailVerificationToken.objects.filter(
            user=user,
            used_at__isnull=True,
        ).update(used_at=timezone.now())

    return Response(
        {"message": "Email verified successfully."},
        status=status.HTTP_200_OK,
    )


class ResendVerificationThrottle(AnonRateThrottle):
    scope = "resend_verification"


@api_view(["POST"])
@permission_classes([AllowAny])
@throttle_classes([ResendVerificationThrottle])
def resend_verification_email(request):
    generic_message = (
        "If this email belongs to an unverified account, "
        "a verification email will be sent."
    )

    email = request.data.get("email")

    if not isinstance(email, str) or not email.strip():
        return Response(
            {"error": "A valid email is required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    email = email.strip().lower()

    if len(email) > 255:
        return Response(
            {"error": "Invalid email."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    cooldown_key = "resend_email:" + hashlib.sha256(
        email.encode("utf-8")
    ).hexdigest()

    if not cache.add(cooldown_key, "1", timeout=60):
        return Response(
            {"message": generic_message},
            status=status.HTTP_200_OK,
        )

    user = Users.objects.filter(
        email__iexact=email
    ).first()

    if user is not None and not user.email_verified:
        try:
            send_verification_email(user)
        except Exception:
            logger.exception(
                "Verification email resend failed"
            )

    return Response(
        {"message": generic_message},
        status=status.HTTP_200_OK,
    )
