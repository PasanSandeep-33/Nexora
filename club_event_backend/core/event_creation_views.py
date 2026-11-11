"""Nexora event submission and admin review endpoints."""
from django.db import transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status

from .models import Clubs, ClubMemberships, Events, EventApprovals, PresidentApplication, Users
from .serializers import EventCreateSerializer, EventSerializer


def _owned_clubs(user):
    return Clubs.objects.filter(
        Q(user_id=user.user_id) |
        Q(clubmemberships__user_id=user.user_id, clubmemberships__member_role__iexact='president')
    ).distinct()


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_president_clubs(request):
    approved = PresidentApplication.objects.filter(applicant_id=request.user.user_id, status='approved').exists()
    if not approved:
        return Response({'clubs': []})
    clubs = _owned_clubs(request.user).order_by('club_name')
    return Response({'clubs': [{'club_id': c.club_id, 'club_name': c.club_name} for c in clubs]})


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def submit_event(request):
    if str(request.user.role).lower() != 'club_admin' or not PresidentApplication.objects.filter(
        applicant_id=request.user.user_id, status='approved'
    ).exists():
        return Response({'detail': 'Approved Club President status is required.'}, status=403)

    serializer = EventCreateSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    club = serializer.validated_data['club']
    if not _owned_clubs(request.user).filter(pk=club.pk).exists():
        return Response({'detail': 'You may create events only for a club you lead.'}, status=403)

    event = serializer.save(created_by=Users.objects.get(pk=request.user.user_id), approval_status='pending')
    return Response(EventSerializer(event).data, status=status.HTTP_201_CREATED)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def pending_events(request):
    if str(request.user.role).lower() != 'admin':
        return Response({'detail': 'Administrator access required.'}, status=403)
    events = Events.objects.filter(approval_status='pending').select_related('club', 'created_by').order_by('event_date')
    data = EventSerializer(events, many=True).data
    for item, event in zip(data, events):
        item['club_name'] = event.club.club_name if event.club else ''
        item['organizer'] = event.created_by.full_name if event.created_by else ''
    return Response(data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def approved_events_admin(request):
    if str(request.user.role).lower() != 'admin':
        return Response({'detail': 'Administrator access required.'}, status=403)
    events = Events.objects.filter(approval_status='approved').select_related('club', 'created_by').order_by('-event_date')
    data = EventSerializer(events, many=True).data
    for item, event in zip(data, events):
        item['club_name'] = event.club.club_name if event.club else ''
        item['organizer'] = event.created_by.full_name if event.created_by else ''
    return Response(data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def review_event(request, event_id):
    if str(request.user.role).lower() != 'admin':
        return Response({'detail': 'Administrator access required.'}, status=403)
    decision = request.data.get('decision')
    if decision not in ('approved', 'rejected'):
        return Response({'decision': ['Use approved or rejected.']}, status=400)
    comments = str(request.data.get('comments', '')).strip()
    if decision == 'rejected' and not comments:
        return Response({'comments': ['Provide a rejection reason.']}, status=400)
    with transaction.atomic():
        event = Events.objects.select_for_update().filter(pk=event_id).first()
        if event is None:
            return Response({'detail': 'Event not found.'}, status=404)
        if event.approval_status != 'pending':
            return Response({'detail': 'Event already reviewed.'}, status=409)
        event.approval_status = decision
        event.save(update_fields=['approval_status'])
        EventApprovals.objects.create(event=event, admin=Users.objects.get(pk=request.user.user_id),
                                      decision=decision, reviewed_at=timezone.now(), comments=comments)
    return Response(EventSerializer(event).data)


def _is_approved_president(user):
    return (str(user.role).lower() == 'club_admin' and
            PresidentApplication.objects.filter(applicant_id=user.user_id, status='approved').exists())


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_president_events(request):
    if not _is_approved_president(request.user):
        return Response({'detail': 'Approved Club President status is required.'}, status=403)
    clubs = _owned_clubs(request.user)
    events = Events.objects.filter(club__in=clubs).order_by('-event_id')
    result = EventSerializer(events, many=True).data
    names = {club.club_id: club.club_name for club in clubs}
    for item in result:
        item['club_name'] = names.get(item.get('club'), '')
    return Response(result)


@api_view(['PATCH', 'DELETE'])
@permission_classes([IsAuthenticated])
def president_event_detail(request, event_id):
    if not _is_approved_president(request.user):
        return Response({'detail': 'Approved Club President status is required.'}, status=403)
    event = Events.objects.filter(pk=event_id, club__in=_owned_clubs(request.user)).first()
    if event is None:
        return Response({'detail': 'Event not found or not managed by you.'}, status=404)
    if event.approval_status == 'approved':
        return Response({'detail': 'Approved events cannot be changed or deleted without administrator review.'}, status=409)
    if request.method == 'DELETE':
        # Existing RSVPs/tickets may restrict deletion depending on database FK rules.
        event.delete()
        return Response(status=204)
    # Do not allow changing club, creator or approval status from the client.
    allowed = ('title', 'category', 'description', 'event_date', 'location', 'capacity')
    payload = {key: request.data[key] for key in allowed if key in request.data}
    serializer = EventCreateSerializer(event, data=payload, partial=True)
    serializer.is_valid(raise_exception=True)
    updated = serializer.save()
    return Response(EventSerializer(updated).data)
