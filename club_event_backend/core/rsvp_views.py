"""Phase 1: database-backed RSVP, ticket and attendance endpoints.
Add as club_event_backend/core/rsvp_views.py.
"""
from uuid import uuid4
from django.db import IntegrityError, transaction
from django.db.models import Q
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Attendance, Clubs, Events, PresidentApplication, Rsvps, Tickets, Users
from .serializers import EventSerializer
import logging

logger = logging.getLogger(__name__)

def _owned_clubs(user):
    return Clubs.objects.filter(
        Q(user_id=user.user_id) |
        Q(clubmemberships__user_id=user.user_id, clubmemberships__member_role__iexact='president')
    ).distinct()


def _president(user):
    return (str(user.role).lower() == 'club_admin' and
            PresidentApplication.objects.filter(applicant_id=user.user_id, status='approved').exists())


def _serialize(rsvp):
    ticket = Tickets.objects.filter(rsvp=rsvp).first()
    attendance = Attendance.objects.filter(ticket=ticket).first() if ticket else None
    return {
        'rsvp_id': rsvp.rsvp_id,
        'status': rsvp.status,
        'registered_at': rsvp.registered_at,
        'event': EventSerializer(rsvp.event).data,
        'ticket': ({'ticket_id': ticket.ticket_id, 'qr_code': ticket.qr_code,
                    'issued_at': ticket.issued_at, 'is_checked_in': attendance is not None,
                    'checked_in_at': attendance.checked_in_at if attendance else None}
                   if ticket else None),
    }



@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def student_rsvps(request):
    if str(request.user.role).lower() != 'student':
        return Response(
            {'detail': 'Student account required.'},
            status=403
        )

    if request.method == 'GET':
        rows = Rsvps.objects.filter(
            user_id=request.user.user_id,
            status='confirmed'
        ).select_related('event').order_by('-registered_at')

        return Response([_serialize(row) for row in rows])

    try:
        event_id = int(request.data.get('event_id'))
    except (TypeError, ValueError):
        return Response(
            {'detail': 'Valid event_id is required.'},
            status=400
        )

    # Added try/except to capture backend errors
    try:
        with transaction.atomic():
            event = Events.objects.select_for_update().filter(
                pk=event_id,
                approval_status='approved'
            ).first()

            if event is None:
                return Response(
                    {'detail': 'Published event not found.'},
                    status=404
                )

            if event.event_date <= timezone.now():
                return Response(
                    {'detail': 'Registration has closed.'},
                    status=400
                )

            existing = Rsvps.objects.filter(
                event=event,
                user_id=request.user.user_id
            ).first()

            if existing and existing.status == 'confirmed':
                return Response(_serialize(existing), status=200)

            confirmed = Rsvps.objects.filter(
                event=event,
                status='confirmed'
            ).count()

            if confirmed >= event.capacity:
                return Response(
                    {'detail': 'Event is full.'},
                    status=409
                )

            if existing:
                existing.status = 'confirmed'
                existing.registered_at = timezone.now()
                existing.save(
                    update_fields=['status', 'registered_at']
                )
                rsvp = existing
            else:
                rsvp = Rsvps.objects.create(
                    user_id=request.user.user_id,
                    event=event,
                    status='confirmed',
                    registered_at=timezone.now()
                )

            Tickets.objects.get_or_create(
                rsvp=rsvp,
                defaults={
                    'qr_code': f'NEXORA-{uuid4().hex}',
                    'issued_at': timezone.now()
                }
            )

            return Response(_serialize(rsvp), status=201)

    except Exception:
        logger.exception("RSVP creation failed")

        return Response(
            {'detail': 'Unable to create RSVP.'},
            status=500
        )


@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def cancel_student_rsvp(request, rsvp_id):
    rsvp = Rsvps.objects.filter(pk=rsvp_id, user_id=request.user.user_id, status='confirmed').first()
    if not rsvp:
        return Response({'detail': 'RSVP not found.'}, status=404)
    with transaction.atomic():
        ticket = Tickets.objects.filter(rsvp=rsvp).first()
        if ticket and Attendance.objects.filter(ticket=ticket).exists():
            return Response({'detail': 'Cannot cancel after check-in.'}, status=409)
        rsvp.status = 'cancelled'
        rsvp.save(update_fields=['status'])
    return Response(status=204)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def president_participants(request):
    if not _president(request.user):
        return Response({'detail': 'Approved Club President required.'}, status=403)
    event_id = request.query_params.get('event_id')
    events = Events.objects.filter(club__in=_owned_clubs(request.user))
    if event_id:
        try:
            events = events.filter(pk=int(event_id))
        except ValueError:
            return Response({'detail': 'Invalid event_id.'}, status=400)
    rows = Rsvps.objects.filter(event__in=events, status='confirmed').select_related('user', 'event').order_by('-registered_at')
    output = []
    for rsvp in rows:
        item = _serialize(rsvp)
        item['student'] = {'user_id': rsvp.user.user_id, 'full_name': rsvp.user.full_name,
                           'email': rsvp.user.email}
        output.append(item)
    return Response(output)


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def president_check_in(request):
    if not _president(request.user):
        return Response({'detail': 'Approved Club President required.'}, status=403)
    qr_code = str(request.data.get('qr_code', '')).strip()
    if not qr_code:
        return Response({'detail': 'qr_code is required.'}, status=400)
    with transaction.atomic():
        ticket = Tickets.objects.select_for_update().select_related('rsvp__event').filter(
            qr_code=qr_code, rsvp__event__club__in=_owned_clubs(request.user),
            rsvp__status='confirmed').first()
        if not ticket:
            return Response({'detail': 'Ticket not found for your club.'}, status=404)
        attendance = Attendance.objects.filter(ticket=ticket).first()
        if request.method == 'DELETE':
            if attendance is None:
                return Response({'detail': 'Ticket is not checked in.'}, status=409)
            attendance.delete()
            return Response({'detail': 'Check-in undone.', 'is_checked_in': False})
        if attendance is not None:
            return Response({'detail': 'Ticket already checked in.'}, status=409)
        try:
            Attendance.objects.create(ticket=ticket, check_in_by_id=request.user.user_id,
                                      checked_in_at=timezone.now())
        except IntegrityError:
            return Response({'detail': 'Ticket already checked in.'}, status=409)
    return Response({'detail': 'Checked in successfully.', 'is_checked_in': True})
