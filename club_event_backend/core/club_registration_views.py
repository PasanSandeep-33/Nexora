import logging
import uuid

import cloudinary.uploader

from django.db import transaction, IntegrityError
from PIL import Image, UnidentifiedImageError

from rest_framework import status
from rest_framework.decorators import (
    api_view,
    permission_classes,
    parser_classes,
)
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Users, ClubRegistrationRequest, Clubs, ClubMemberships
from .club_registration_serializers import (
    ClubRegistrationCreateSerializer,
    ClubRegistrationReadSerializer,
    ClubRegistrationReviewSerializer,
    ClubRegistrationRejectSerializer,
)

import os
from typing import Any, cast
from pypdf import PdfReader
from pypdf.errors import PdfReadError
from django.utils import timezone

def validate_appointment_letter(uploaded_file):
    MAX_FILE_SIZE = 5 * 1024 * 1024

    allowed_extensions = {".pdf", ".jpg", ".jpeg", ".png"}

    if uploaded_file is None:
        return "Appointment letter is required."

    if uploaded_file.size == 0:
        return "The uploaded file is empty."

    if uploaded_file.size > MAX_FILE_SIZE:
        return "Appointment letter must not exceed 5 MB."

    extension = os.path.splitext(uploaded_file.name)[1].lower()

    if extension not in allowed_extensions:
        return "Only PDF, JPG, JPEG, and PNG files are allowed."

    try:
        uploaded_file.seek(0)


        if extension == ".pdf":
            header = uploaded_file.read(5)

            if header != b"%PDF-":
                return "The uploaded file is not a valid PDF."

            uploaded_file.seek(0)

            try:
                reader = PdfReader(uploaded_file, strict=True)

                if reader.is_encrypted:
                    return "Password-protected PDFs are not allowed."

                if len(reader.pages) == 0:
                    return "The PDF must contain at least one page."

            except (PdfReadError, OSError, ValueError, KeyError):
                return "The PDF is invalid or corrupted."

        else:
            with Image.open(uploaded_file) as image:
                image.verify()
                actual_format = image.format

            expected_formats = {
                ".jpg": "JPEG",
                ".jpeg": "JPEG",
                ".png": "PNG",
            }

            if actual_format != expected_formats[extension]:
                return "The image content does not match its file extension."

    except (
        UnidentifiedImageError,
        OSError,
        ValueError,
    ):
        return "The uploaded file is invalid or corrupted."

    finally:
        uploaded_file.seek(0)

    return None


@api_view(["POST"])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def submit_club_registration(request):

    # Only students can submit club registration requests
    if request.user.role != "student":
        return Response(
            {
                "detail": (
                    "Only students can submit "
                    "club registration requests."
                )
            },
            status=status.HTTP_403_FORBIDDEN,
        )

    # Validate club details
    serializer = ClubRegistrationCreateSerializer(
        data=request.data
    )

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Validate appointment letter
    uploaded_file = request.FILES.get("appointment_letter")

    error = validate_appointment_letter(uploaded_file)

    if error:
        return Response(
            {"appointment_letter": [error]},
            status=status.HTTP_400_BAD_REQUEST,
        )

    # Get the authenticated student
    applicant = Users.objects.get(
        user_id=request.user.user_id
    )

    # Generate a unique Cloudinary file identifier
    file_extension = os.path.splitext(
        uploaded_file.name
    )[1].lower()

    resource_type = (
        "raw" if file_extension == ".pdf" else "image"
    )

    public_id = f"nexora/club_documents/{uuid.uuid4().hex}"

    if resource_type == "raw":
        public_id += ".pdf"

    uploaded_public_id = None

    try:
        # Upload appointment letter privately
        uploaded_file.seek(0)

        upload_result = cloudinary.uploader.upload(
            uploaded_file,
            public_id=public_id,
            resource_type=resource_type,
            type="authenticated",
            overwrite=False,
        )

        uploaded_public_id = upload_result["public_id"]


        # Get validated fields
        validated_data = cast(dict[str, Any], serializer.validated_data)

        # Save pending registration request
        with transaction.atomic():
            registration = ClubRegistrationRequest.objects.create(
                applicant=applicant,
                club_name=validated_data["club_name"],
                category=validated_data["category"],
                description=validated_data["description"],
                proof_file_key=uploaded_public_id,
                status="pending",
            )


        return Response(
            ClubRegistrationReadSerializer(registration).data,
            status=status.HTTP_201_CREATED,
        )

    except IntegrityError:
        logger.warning(
            "Club registration failed due to a database constraint."
        )

        if uploaded_public_id:
            try:
                cloudinary.uploader.destroy(
                    uploaded_public_id,
                    resource_type=resource_type,
                    type="authenticated",
                    invalidate=True,
                )
            except Exception:
                logger.exception(
                    "Failed to clean up club document"
                )

        return Response(
            {
                "detail": (
                    "Registration could not be completed "
                    "because of a database constraint. "
                    "Please check the club name and try again."
                )
            },
            status=status.HTTP_409_CONFLICT,
        )

    except Exception:
        logger.exception("Club registration submission failed")

        # Remove uploaded file if database saving fails
        if uploaded_public_id:
            try:
                cloudinary.uploader.destroy(
                    uploaded_public_id,
                    resource_type=resource_type,
                    type="authenticated",
                    invalidate=True,
                )
            except Exception:
                logger.exception(
                    "Failed to clean up uploaded club document"
                )

        return Response(
            {"detail": "Unable to submit club registration."},
            status=status.HTTP_500_INTERNAL_SERVER_ERROR,
        )


logger = logging.getLogger(__name__)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def list_club_registration_requests(request):

    # Only administrators may view registration requests
    if request.user.role != "admin":
        return Response(
            {"detail": "Administrator access required."},
            status=status.HTTP_403_FORBIDDEN,
        )

    # Optional status filter
    requested_status = request.query_params.get("status")

    valid_statuses = {"pending", "approved", "rejected"}

    if requested_status and requested_status not in valid_statuses:
        return Response(
            {"status": ["Invalid registration status."]},
            status=status.HTTP_400_BAD_REQUEST,
        )

    registrations = ClubRegistrationRequest.objects.all()

    if requested_status:
        registrations = registrations.filter(status=requested_status)

    registrations = registrations.order_by("-created_at")

    serializer = ClubRegistrationReadSerializer(
        registrations,
        many=True,
    )

    return Response(
        serializer.data,
        status=status.HTTP_200_OK,
    )

@api_view(["POST"])
@permission_classes([IsAuthenticated])
def approve_club_registration(request, registration_id):

    if request.user.role != "admin":
        return Response(
            {"detail": "Administrator access required."},
            status=status.HTTP_403_FORBIDDEN,
        )

    serializer = ClubRegistrationReviewSerializer(
        data=request.data
    )

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        with transaction.atomic():

            registration = (
                ClubRegistrationRequest.objects
                .select_for_update()
                .get(pk=registration_id)
            )

            if registration.status != "pending":
                return Response(
                    {"detail": "This request has already been reviewed."},
                    status=status.HTTP_409_CONFLICT,
                )

            if Clubs.objects.filter(
                club_name__iexact=registration.club_name
            ).exists():
                return Response(
                    {"detail": "A club with this name already exists."},
                    status=status.HTTP_409_CONFLICT,
                )

            admin = Users.objects.get(
                user_id=request.user.user_id
            )

            club = Clubs.objects.create(
                club_name=registration.club_name,
                category=registration.category,
                description=registration.description,
                user=registration.applicant,
            )

            ClubMemberships.objects.create(
                club=club,
                user=registration.applicant,
                member_role="president",
                joined_at=timezone.now(),
            )

            registration.status = "approved"
            registration.reviewed_by = admin
            registration.reviewed_at = timezone.now()
            validated_data = cast(dict[str, Any], serializer.validated_data)

            registration.review_reason = validated_data.get(
                "review_reason", ""
            )
            registration.approved_club = club

            registration.save(
                update_fields=[
                    "status",
                    "reviewed_by",
                    "reviewed_at",
                    "review_reason",
                    "approved_club",
                ]
            )

            response_data = ClubRegistrationReadSerializer(
                registration
            ).data

        return Response(
            response_data,
            status=status.HTTP_200_OK,
        )

    except ClubRegistrationRequest.DoesNotExist:
        return Response(
            {"detail": "Registration request not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    except Users.DoesNotExist:
        return Response(
            {"detail": "Administrator account not found."},
            status=status.HTTP_403_FORBIDDEN,
        )

    except IntegrityError:
        logger.exception("Club approval database constraint failure")
        return Response(
            {"detail": "Club approval could not be completed."},
            status=status.HTTP_409_CONFLICT,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def reject_club_registration(request, registration_id):

    if request.user.role != "admin":
        return Response(
            {"detail": "Administrator access required."},
            status=status.HTTP_403_FORBIDDEN,
        )

    serializer = ClubRegistrationRejectSerializer(
        data=request.data
    )

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST,
        )

    validated_data = cast(
        dict[str, Any],
        serializer.validated_data,
    )

    try:
        with transaction.atomic():

            registration = (
                ClubRegistrationRequest.objects
                .select_for_update()
                .get(pk=registration_id)
            )

            if registration.status != "pending":
                return Response(
                    {"detail": "This request has already been reviewed."},
                    status=status.HTTP_409_CONFLICT,
                )

            admin = Users.objects.get(
                user_id=request.user.user_id,
                role="admin",
            )

            registration.status = "rejected"
            registration.reviewed_by = admin
            registration.reviewed_at = timezone.now()
            registration.review_reason = validated_data["review_reason"]

            registration.save(
                update_fields=[
                    "status",
                    "reviewed_by",
                    "reviewed_at",
                    "review_reason",
                ]
            )

            response_data = ClubRegistrationReadSerializer(
                registration
            ).data

        return Response(
            response_data,
            status=status.HTTP_200_OK,
        )

    except ClubRegistrationRequest.DoesNotExist:
        return Response(
            {"detail": "Registration request not found."},
            status=status.HTTP_404_NOT_FOUND,
        )

    except Users.DoesNotExist:
        return Response(
            {"detail": "Administrator account not found."},
            status=status.HTTP_403_FORBIDDEN,
        )
