import logging
import os
import time
import uuid
from typing import Any, cast

import cloudinary.uploader
import cloudinary.utils
from django.db import IntegrityError, transaction
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, parser_classes, permission_classes
from rest_framework.parsers import FormParser, MultiPartParser
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import PresidentApplication, Users, Clubs, ClubMemberships
from .president_application_serializers import (
    PresidentApplicationCreateSerializer,
    PresidentApplicationReadSerializer,
    PresidentApplicationReviewSerializer,
    PresidentApplicationRejectSerializer,
)
from .club_registration_views import validate_appointment_letter

logger = logging.getLogger(__name__)


def _is_admin(user):
    return str(user.role).strip().lower() == "admin"


def _is_student(user):
    return str(user.role).strip().lower() == "student"


def _upload_private_document(uploaded_file, folder):
    extension = os.path.splitext(uploaded_file.name)[1].lower()
    resource_type = "raw" if extension == ".pdf" else "image"
    public_id = f"nexora/{folder}/{uuid.uuid4().hex}"
    if resource_type == "raw":
        public_id += extension
    uploaded_file.seek(0)
    result = cloudinary.uploader.upload(
        uploaded_file,
        public_id=public_id,
        resource_type=resource_type,
        type="authenticated",
        overwrite=False,
    )
    return result["public_id"], resource_type


@api_view(["POST"])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def submit_president_application(request):
    if not _is_student(request.user):
        return Response({"detail": "Only student accounts may apply to become a Club President."}, status=403)

    if PresidentApplication.objects.filter(
        applicant_id=request.user.user_id, status="pending"
    ).exists():
        return Response({"detail": "You already have a pending President application."}, status=409)

    if PresidentApplication.objects.filter(
        applicant_id=request.user.user_id, status="approved"
    ).exists():
        return Response({"detail": "You have already been approved as a Club President."}, status=409)

    serializer = PresidentApplicationCreateSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)

    uploaded_file = request.FILES.get("supporting_document")
    error = validate_appointment_letter(uploaded_file)
    if error:
        return Response({"supporting_document": [error]}, status=400)

    data = cast(dict[str, Any], serializer.validated_data)
    if Clubs.objects.filter(club_name__iexact=data["club_name"]).exists():
        return Response({"club_name": ["A club with this name already exists."]}, status=409)
    if PresidentApplication.objects.filter(club_name__iexact=data["club_name"], status="pending").exists():
        return Response({"club_name": ["A pending application already uses this name."]}, status=409)

    public_id = None
    resource_type = None
    try:
        public_id, resource_type = _upload_private_document(uploaded_file, "president_applications")
        application = PresidentApplication.objects.create(
            applicant=Users.objects.get(user_id=request.user.user_id),
            reason=data["description"],
            club_name=data["club_name"],
            category=data["category"],
            description=data["description"],
            proof_file_key=public_id,
            status="pending",
        )
        return Response(PresidentApplicationReadSerializer(application).data, status=201)
    except Exception:
        logger.exception("President application submission failed")
        if public_id:
            try:
                cloudinary.uploader.destroy(
                    public_id, resource_type=resource_type,
                    type="authenticated", invalidate=True,
                )
            except Exception:
                logger.exception("Failed to clean up president application document")
        return Response({"detail": "Unable to submit President application."}, status=500)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def my_president_application(request):
    application = PresidentApplication.objects.filter(
        applicant_id=request.user.user_id
    ).order_by("-created_at").first()
    if application is None:
        return Response({"has_application": False, "is_approved_president": False}, status=200)
    return Response({
        "has_application": True,
        "is_approved_president": application.status == "approved",
        "application": PresidentApplicationReadSerializer(application).data,
    }, status=200)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def list_president_applications(request):
    if not _is_admin(request.user):
        return Response({"detail": "Administrator access required."}, status=403)
    requested_status = request.query_params.get("status")
    if requested_status and requested_status not in {"pending", "approved", "rejected"}:
        return Response({"status": ["Invalid application status."]}, status=400)
    queryset = PresidentApplication.objects.select_related("applicant", "reviewed_by").order_by("-created_at")
    if requested_status:
        queryset = queryset.filter(status=requested_status)
    return Response(PresidentApplicationReadSerializer(queryset, many=True).data, status=200)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def view_president_application_document(request, application_id):
    if not _is_admin(request.user):
        return Response({"detail": "Administrator access required."}, status=403)
    application = get_object_or_404(PresidentApplication, pk=application_id)
    public_id = application.proof_file_key
    resource_type = "raw" if os.path.splitext(public_id)[1].lower() == ".pdf" else "image"
    try:
        signed_url = cloudinary.utils.private_download_url(
            public_id, format=None, resource_type=resource_type,
            type="authenticated", expires_at=int(time.time()) + 300,
            attachment=False,
        )
        return Response({"application_id": application.pk, "document_url": signed_url}, status=200)
    except Exception:
        logger.exception("Could not create president application document URL")
        return Response({"detail": "Unable to generate document access URL."}, status=502)


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def approve_president_application(request, application_id):
    if not _is_admin(request.user):
        return Response({"detail": "Administrator access required."}, status=403)
    serializer = PresidentApplicationReviewSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)
    try:
        with transaction.atomic():
            application = PresidentApplication.objects.select_for_update().get(pk=application_id)
            if application.status != "pending":
                return Response({"detail": "This application has already been reviewed."}, status=409)
            if not application.club_name or not application.category or not application.description:
                return Response({"detail": "Legacy application has no club details. Request a new combined application."}, status=409)
            if Clubs.objects.filter(club_name__iexact=application.club_name).exists():
                return Response({"detail": "A club with this name already exists."}, status=409)
            club = Clubs.objects.create(
                club_name=application.club_name,
                category=application.category,
                description=application.description,
                user=application.applicant,
            )
            ClubMemberships.objects.create(
                club=club,
                user=application.applicant,
                member_role="president",
                joined_at=timezone.now(),
            )

            # Change the approved student's account role to President
            application.applicant.role = "club_admin"
            application.applicant.save(update_fields=["role"])

            application.approved_club = club
            application.status = "approved"
            application.reviewed_by = Users.objects.get(user_id=request.user.user_id)
            application.reviewed_at = timezone.now()
            data = cast(dict[str, Any], serializer.validated_data)
            application.review_reason = data.get("review_reason", "")
            application.save(update_fields=["approved_club", "status", "reviewed_by", "reviewed_at", "review_reason"])
        return Response(PresidentApplicationReadSerializer(application).data, status=200)
    except PresidentApplication.DoesNotExist:
        return Response({"detail": "President application not found."}, status=404)
    
    except Exception:
        logger.exception(
            "Failed to approve President application %s",
            application_id,
        )
        return Response(
            {"detail": "Unable to approve President application."},
            status=500,
        )


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def reject_president_application(request, application_id):
    if not _is_admin(request.user):
        return Response({"detail": "Administrator access required."}, status=403)
    serializer = PresidentApplicationRejectSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=400)
    try:
        with transaction.atomic():
            application = PresidentApplication.objects.select_for_update().get(pk=application_id)
            if application.status != "pending":
                return Response({"detail": "This application has already been reviewed."}, status=409)
            application.status = "rejected"
            application.reviewed_by = Users.objects.get(user_id=request.user.user_id)
            application.reviewed_at = timezone.now()
            data = cast(dict[str, Any], serializer.validated_data)
            application.review_reason = data["review_reason"]
            application.save(update_fields=["status", "reviewed_by", "reviewed_at", "review_reason"])
        return Response(PresidentApplicationReadSerializer(application).data, status=200)
    except PresidentApplication.DoesNotExist:
        return Response({"detail": "President application not found."}, status=404)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def public_club_list(request):
    # Approved President applications create clubs immediately.
    clubs = Clubs.objects.all().order_by("club_name")
    data = []
    for club in clubs:
        president = club.user
        data.append({
            "club_id": club.club_id,
            "club_name": club.club_name,
            "category": club.category or "General",
            "description": club.description or "",
            "president_name": president.full_name if president else "Club President",
            "member_count": ClubMemberships.objects.filter(club_id=club.club_id).count(),
        })
    return Response(data, status=200)
