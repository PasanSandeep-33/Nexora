
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
)
from typing import cast

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
        return Response(
            {'message': 'Image upload failed'},
            status=status.HTTP_502_BAD_GATEWAY,
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
