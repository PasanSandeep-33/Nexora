# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models
from django.db.models import deletion

DB_CASCADE = deletion.DB_CASCADE  # type: ignore[attr-defined]


class Users(models.Model):
    user_id = models.BigAutoField(primary_key=True)
    full_name = models.CharField(max_length=100)
    email = models.CharField(unique=True, max_length=255)
    password_hash = models.TextField()
    role = models.CharField(max_length=20)

    class Meta:
        managed = False
        db_table = 'users'


class Clubs(models.Model):
    club_id = models.BigAutoField(primary_key=True)
    club_name = models.CharField(unique=True, max_length=150)
    description = models.TextField(blank=True, null=True)
    user = models.ForeignKey(Users, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'clubs'


class ClubMemberships(models.Model):
    membership_id = models.BigAutoField(primary_key=True)
    member_role = models.CharField(max_length=30)
    joined_at = models.DateTimeField()
    user = models.ForeignKey(Users, models.DO_NOTHING)
    club = models.ForeignKey(Clubs, models.DO_NOTHING)

    class Meta:
        managed = False
        db_table = 'club_memberships'
        unique_together = (('user', 'club'),)


class Events(models.Model):
    event_id = models.BigAutoField(primary_key=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    category = models.CharField(max_length=100, blank=True, null=True)
    event_date = models.DateTimeField()
    location = models.CharField(max_length=255)
    capacity = models.IntegerField()
    approval_status = models.CharField(max_length=20)
    created_by = models.ForeignKey(Users, models.DO_NOTHING, db_column='created_by')
    club = models.ForeignKey(Clubs, models.DO_NOTHING, blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'events'


class EventApprovals(models.Model):
    approval_id = models.BigAutoField(primary_key=True)
    decision = models.CharField(max_length=20)
    reviewed_at = models.DateTimeField()
    comments = models.TextField(blank=True, null=True)
    admin = models.ForeignKey(Users, models.DO_NOTHING)
    event = models.ForeignKey(Events, on_delete=DB_CASCADE)

    class Meta:
        managed = False
        db_table = 'event_approvals'


class Rsvps(models.Model):
    rsvp_id = models.BigAutoField(primary_key=True)
    registered_at = models.DateTimeField()
    status = models.CharField(max_length=20)
    user = models.ForeignKey(Users, models.DO_NOTHING)
    event = models.ForeignKey(Events, on_delete=DB_CASCADE)

    class Meta:
        managed = False
        db_table = 'rsvps'
        unique_together = (('user', 'event'),)


class Tickets(models.Model):
    ticket_id = models.BigAutoField(primary_key=True)
    qr_code = models.TextField(unique=True)
    issued_at = models.DateTimeField()
    rsvp = models.OneToOneField(Rsvps, on_delete=DB_CASCADE)

    class Meta:
        managed = False
        db_table = 'tickets'


class Attendance(models.Model):
    attendance_id = models.BigAutoField(primary_key=True)
    checked_in_at = models.DateTimeField()
    check_in_by = models.ForeignKey(Users, models.DO_NOTHING, db_column='check_in_by', blank=True, null=True)
    ticket = models.OneToOneField(Tickets, on_delete=DB_CASCADE)

    class Meta:
        managed = False
        db_table = 'attendance'


class RefreshSession(models.Model):
    session_id = models.BigAutoField(primary_key=True)

    user = models.ForeignKey(
        Users,
        on_delete=models.DO_NOTHING,
        related_name='refresh_sessions',
    )

    token_jti_hash = models.CharField(
        max_length=64,
        unique=True,
    )

    created_at = models.DateTimeField(auto_now_add=True)

    expires_at = models.DateTimeField()

    revoked_at = models.DateTimeField(
        null=True,
        blank=True,
    )

    class Meta:
        db_table = 'refresh_sessions'
        indexes = [
            models.Index(fields=['user', 'expires_at']),
        ]
