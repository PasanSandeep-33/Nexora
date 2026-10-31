import jwt
import secrets
import hashlib

from datetime import datetime, timedelta, timezone

from django.db import transaction
from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from .models import Users, RefreshSession

from django.utils import timezone as django_timezone


class JWTUser:
    def __init__(self, user):
        self.user_id = user.user_id
        self.email = user.email
        self.role = user.role
        self.is_authenticated = True


def create_access_token(user):
    now = datetime.now(timezone.utc)

    payload = {
        "sub": str(user.user_id),
        "iat": now,
        "exp": now + timedelta(minutes=30),
        "type": "access",
    }

    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm="HS256",
    )

def hash_refresh_jti(jti):
    return hashlib.sha256(jti.encode("utf-8")).hexdigest()

def create_refresh_token(user):
    now = datetime.now(timezone.utc)

    payload = {
        "sub": str(user.user_id),
        "iat": now,
        "exp": now + timedelta(days=7),
        "type": "refresh",
        "jti": secrets.token_hex(32),
    }

    return jwt.encode(
        payload,
        settings.SECRET_KEY,
        algorithm="HS256",
    )

class JWTAuthentication(BaseAuthentication):

    def authenticate(self, request):
        header = request.headers.get("Authorization", "")

        if not header:
            return None

        parts = header.split()

        if len(parts) != 2 or parts[0].lower() != "bearer":
            raise AuthenticationFailed(
                "Invalid authorization header."
            )

        token = parts[1]

        try:
            payload = jwt.decode(
                token,
                settings.SECRET_KEY,
                algorithms=["HS256"],
                options={"require": ["sub", "iat", "exp", "type"]},
            )

            if payload.get("type") != "access":
                raise AuthenticationFailed("Invalid token type.")

            user = Users.objects.get(
                user_id=payload["sub"]
            )

        except jwt.ExpiredSignatureError:
            raise AuthenticationFailed("Token has expired.")

        except jwt.InvalidTokenError:
            raise AuthenticationFailed("Invalid token.")

        except (Users.DoesNotExist, ValueError, TypeError):
            raise AuthenticationFailed("User not found.")

        return JWTUser(user), token

    def authenticate_header(self, request):
        return "Bearer"

def decode_refresh_token(token):
    try:
        payload = jwt.decode(
            token,
            settings.SECRET_KEY,
            algorithms=["HS256"],
            options={"require": ["sub", "iat", "exp", "type", "jti"]},
        )

        if payload.get("type") != "refresh":
            raise AuthenticationFailed("Invalid token type.")

        return payload

    except jwt.ExpiredSignatureError:
        raise AuthenticationFailed("Refresh token has expired.")

    except jwt.InvalidTokenError:
        raise AuthenticationFailed("Invalid refresh token.")


def create_refresh_session(user):
    token = create_refresh_token(user)

    payload = decode_refresh_token(token)

    RefreshSession.objects.create(
        user=user,
        token_jti_hash=hash_refresh_jti(payload["jti"]),
        expires_at=datetime.fromtimestamp(
            payload["exp"],
            tz=timezone.utc,
        ),
    )

    return token

def rotate_refresh_token(token):
    payload = decode_refresh_token(token)
    jti_hash = hash_refresh_jti(payload["jti"])

    with transaction.atomic():
        session = (
            RefreshSession.objects
            .select_for_update()
            .filter(token_jti_hash=jti_hash)
            .first()
        )

        if session is None:
            raise AuthenticationFailed("Refresh session not found.")

        if session.revoked_at is not None:
            raise AuthenticationFailed("Refresh token already used or revoked.")

        if session.expires_at <= django_timezone.now():
            raise AuthenticationFailed("Refresh session expired.")

        if str(session.user.pk) != str(payload["sub"]):
         raise AuthenticationFailed("Invalid refresh token owner.")

        user = session.user

        session.revoked_at = django_timezone.now()
        session.save(update_fields=["revoked_at"])

        new_token = create_refresh_token(user)
        new_payload = decode_refresh_token(new_token)

        RefreshSession.objects.create(
            user=user,
            token_jti_hash=hash_refresh_jti(new_payload["jti"]),
            expires_at=min(
                session.expires_at,
                datetime.fromtimestamp(
                    new_payload["exp"],
                    tz=timezone.utc,
                ),
            ),
        )

        return create_access_token(user), new_token
