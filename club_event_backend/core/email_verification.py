from django.conf import settings
from django.core.mail import send_mail
from urllib.parse import urlencode
import hashlib
import secrets
from datetime import timedelta

from django.db import transaction
from django.utils import timezone

from .models import EmailVerificationToken


TOKEN_EXPIRY_HOURS = 1


def hash_verification_token(token):
    return hashlib.sha256(
        token.encode("utf-8")
    ).hexdigest()


def create_verification_token(user):
    raw_token = secrets.token_urlsafe(32)
    token_hash = hash_verification_token(raw_token)

    with transaction.atomic():
        EmailVerificationToken.objects.filter(
            user=user,
            used_at__isnull=True,
        ).update(used_at=timezone.now())

        EmailVerificationToken.objects.create(
            user=user,
            token_hash=token_hash,
            expires_at=timezone.now() + timedelta(
                hours=TOKEN_EXPIRY_HOURS
            ),
        )

    return raw_token


def send_verification_email(user):
    raw_token = create_verification_token(user)

    base_url = getattr(
        settings,
        "EMAIL_VERIFY_URL",
        "http://localhost:8000/api/email/verify/",
    )

    verification_url = (
        f"{base_url}?{urlencode({'token': raw_token})}"
    )

    subject = "Verify your Nexora account"

    message = (
        f"Hello {user.full_name},\n\n"
        "Welcome to Nexora!\n\n"
        "Please verify your email address using this link:\n\n"
        f"{verification_url}\n\n"
        "This link expires in 1 hour.\n\n"
        "If you did not create this account, ignore this email."
    )

    send_mail(
        subject,
        message,
        settings.DEFAULT_FROM_EMAIL,
        [user.email],
        fail_silently=False,
    )
