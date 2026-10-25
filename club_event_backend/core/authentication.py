import jwt

from datetime import datetime, timedelta, timezone

from django.conf import settings
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed

from .models import Users


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