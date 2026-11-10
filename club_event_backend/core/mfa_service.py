import base64
import io
import secrets
import time
import hmac

import pyotp
import qrcode

import qrcode
from qrcode.constants import ERROR_CORRECT_M

from cryptography.fernet import Fernet
from django.conf import settings
from django.contrib.auth.hashers import make_password, check_password
from django.db import transaction

from .models import AdminMFADevice


# --------------------------------------------------
# 1. ENCRYPTION
# --------------------------------------------------

def get_fernet():
    key = settings.MFA_ENCRYPTION_KEY

    if isinstance(key, str):
        key = key.encode("utf-8")

    return Fernet(key)


def encrypt_secret(secret):
    return get_fernet().encrypt(
        secret.encode("utf-8")
    ).decode("utf-8")


def decrypt_secret(encrypted_secret):
    return get_fernet().decrypt(
        encrypted_secret.encode("utf-8")
    ).decode("utf-8")


# --------------------------------------------------
# 2. GENERATE AUTHENTICATOR SECRET
# --------------------------------------------------

def generate_secret():
    return pyotp.random_base32()


def get_provisioning_uri(secret, email):
    totp = pyotp.TOTP(secret)

    return totp.provisioning_uri(
        name=email,
        issuer_name="Nexora"
    )


# --------------------------------------------------
# 3. GENERATE QR CODE
# --------------------------------------------------

def generate_qr_code(provisioning_uri):
    qr = qrcode.QRCode(
        version=None,
        error_correction=ERROR_CORRECT_M,
        box_size=8,
        border=4,
    )

    qr.add_data(provisioning_uri)
    qr.make(fit=True)

    image = qr.make_image(
        fill_color="black",
        back_color="white"
    )

    buffer = io.BytesIO()
    image.save(buffer, "PNG")

    encoded = base64.b64encode(
        buffer.getvalue()
    ).decode("utf-8")

    return f"data:image/png;base64,{encoded}"


# --------------------------------------------------
# 4. START MFA ENROLLMENT
# --------------------------------------------------

def start_mfa_enrollment(user):
    device, _ = AdminMFADevice.objects.get_or_create(
        user=user
    )

    if device.is_enabled:
        raise ValueError("MFA is already enabled.")

    secret = generate_secret()

    device.pending_secret_encrypted = encrypt_secret(secret)

    device.save(update_fields=[
        "pending_secret_encrypted",
        "updated_at",
    ])

    uri = get_provisioning_uri(secret, user.email)

    return {
        "qr_code": generate_qr_code(uri),
        "manual_secret": secret,
        "provisioning_uri": uri,
    }


# --------------------------------------------------
# 5. VERIFY TOTP CODE
# --------------------------------------------------

def match_totp_step(secret, code):
    if not isinstance(code, str):
        return None

    if len(code) != 6 or not code.isdigit():
        return None

    totp = pyotp.TOTP(secret)
    current_step = int(time.time() // totp.interval)

    for step in (current_step - 1, current_step, current_step + 1):
        expected = totp.generate_otp(step)

        if hmac.compare_digest(expected, code):
            return step

    return None


def verify_totp(user, code, use_pending=False):
    with transaction.atomic():
        device = AdminMFADevice.objects.select_for_update().filter(
            user=user
        ).first()

        if device is None:
            return False

        encrypted_secret = (
            device.pending_secret_encrypted
            if use_pending
            else device.secret_encrypted
        )

        if not encrypted_secret:
            return False

        if not use_pending and not device.is_enabled:
            return False

        try:
            secret = decrypt_secret(encrypted_secret)
        except Exception:
            return False

        matched_step = match_totp_step(secret, code)

        if matched_step is None:
            return False

        if (
            device.last_verified_step is not None
            and matched_step <= device.last_verified_step
        ):
            return False

        device.last_verified_step = matched_step

        device.save(update_fields=[
            "last_verified_step",
            "updated_at",
        ])

        return True


# --------------------------------------------------
# 6. COMPLETE MFA ENROLLMENT
# --------------------------------------------------

def complete_mfa_enrollment(user, code):
    with transaction.atomic():
        device = AdminMFADevice.objects.select_for_update().filter(
            user=user
        ).first()

        if device is None or not device.pending_secret_encrypted:
            raise ValueError("MFA enrollment has not been started.")

        secret = decrypt_secret(
            device.pending_secret_encrypted
        )

        matched_step = match_totp_step(secret, code)

        if matched_step is None:
            raise ValueError("Invalid authenticator code.")

        if (
            device.last_verified_step is not None
            and matched_step <= device.last_verified_step
        ):
            raise ValueError("This authenticator code has already been used.")

        # Generate ten one-time recovery codes.
        recovery_codes = [
            secrets.token_hex(6).upper()
            for _ in range(10)
        ]

        # Store password hashes, never plaintext codes.
        recovery_hashes = [
            make_password(code)
            for code in recovery_codes
        ]

        device.secret_encrypted = device.pending_secret_encrypted
        device.pending_secret_encrypted = None
        device.is_enabled = True
        device.recovery_codes = recovery_hashes
        device.last_verified_step = matched_step

        device.save(update_fields=[
            "secret_encrypted",
            "pending_secret_encrypted",
            "is_enabled",
            "recovery_codes",
            "last_verified_step",
            "updated_at",
        ])

        # Show these codes to the administrator only once.
        return recovery_codes


# --------------------------------------------------
# 7. VERIFY AND CONSUME RECOVERY CODE
# --------------------------------------------------

def consume_recovery_code(user, submitted_code):
    if not isinstance(submitted_code, str):
        return False

    submitted_code = submitted_code.strip().upper()

    with transaction.atomic():
        device = AdminMFADevice.objects.select_for_update().filter(
            user=user,
            is_enabled=True,
        ).first()

        if device is None:
            return False

        for index, hashed_code in enumerate(device.recovery_codes):
            if check_password(submitted_code, hashed_code):

                # Remove the used recovery code permanently.
                device.recovery_codes.pop(index)

                device.save(update_fields=[
                    "recovery_codes",
                    "updated_at",
                ])

                return True

    return False


# --------------------------------------------------
# 8. DISABLE MFA
# --------------------------------------------------

def disable_mfa(user):
    with transaction.atomic():
        device = AdminMFADevice.objects.select_for_update().filter(
            user=user
        ).first()

        if device is None:
            return False

        device.secret_encrypted = None
        device.pending_secret_encrypted = None
        device.is_enabled = False
        device.recovery_codes = []
        device.last_verified_step = None

        device.save(update_fields=[
            "secret_encrypted",
            "pending_secret_encrypted",
            "is_enabled",
            "recovery_codes",
            "last_verified_step",
            "updated_at",
        ])

        return True
