
from django.urls import path
from .admin_stats_views import admin_stats
from .views import (
    event_list,
    signup,
    login,
    profile,
    upload_profile_image,
    refresh_token,
    logout,
    admin_mfa_setup,
    admin_mfa_verify_setup,
    admin_mfa_verify_login,
    admin_mfa_recovery,
)
from .club_registration_views import (
    submit_club_registration,
    list_club_registration_requests,
    approve_club_registration,
    reject_club_registration,
    view_club_registration_document,
)
from .president_application_views import (
    submit_president_application,
    my_president_application,
    list_president_applications,
    view_president_application_document,
    approve_president_application,
    reject_president_application,
    public_club_list,
)

from .event_creation_views import my_president_clubs, submit_event, pending_events, review_event, approved_events_admin,  my_president_events, president_event_detail, event_proposal_document

from .rsvp_views import student_rsvps, cancel_student_rsvp, president_participants, president_check_in

urlpatterns = [
    path("admin/stats/", admin_stats, name="admin-stats"),
    path("rsvps/", student_rsvps, name="student-rsvps"),
    path("rsvps/<int:rsvp_id>/", cancel_student_rsvp, name="cancel-rsvp"),
    path("president/participants/", president_participants, name="president-participants"),
    path("president/check-in/", president_check_in, name="president-check-in"),
    path("events/", event_list, name="event-list"),
    path("events/create/", submit_event, name="event-create"),
    path("president/clubs/", my_president_clubs, name="president-clubs"),
    path("admin/events/pending/", pending_events, name="admin-pending-events"),
    path("admin/events/<int:event_id>/review/", review_event, name="admin-review-event"),
    path("admin/events/<int:event_id>/proposal/", event_proposal_document, name="admin-event-proposal"),
    path("signup/", signup, name="signup"),
    path("login/", login, name="login"),
    path("profile/", profile, name="profile"),
    path('admin/events/approved/', approved_events_admin, name='admin-approved-events'),
    path(
        "profile/image/",
        upload_profile_image,
        name="profile-image-upload",
    ),
    path("token/refresh/", refresh_token, name="token-refresh"),
    path("logout/", logout, name="logout"),
    path(
    "club-registration/",
    submit_club_registration,
    name="club-registration-submit",
    ),
    path(
    "admin/club-registrations/",
    list_club_registration_requests,
    name="admin-club-registration-list",
    ),
    path(
    "admin/club-registrations/<int:registration_id>/approve/",
    approve_club_registration,
    name="admin-club-registration-approve",
    ),
    path(
    "admin/club-registrations/<int:registration_id>/reject/",
    reject_club_registration,
    name="admin-club-registration-reject",
    ),
    path(
    "admin/club-registrations/<int:registration_id>/document/",
    view_club_registration_document,
    name="view-club-registration-document",
    ),
    path(
    "admin/mfa/setup/",
    admin_mfa_setup,
    name="admin-mfa-setup",
    ),
    path(
        "admin/mfa/verify-setup/",
        admin_mfa_verify_setup,
        name="admin-mfa-verify-setup",
    ),

    path(
        "admin/mfa/verify-login/",
        admin_mfa_verify_login,
        name="admin-mfa-verify-login",
    ),

    path(
        "admin/mfa/recovery/",
        admin_mfa_recovery,
        name="admin-mfa-recovery",
    ),
    path("president-applications/", submit_president_application, name="president-application-submit"),
    path("president-applications/me/", my_president_application, name="president-application-me"),
    path("admin/president-applications/", list_president_applications, name="admin-president-application-list"),
    path("admin/president-applications/<int:application_id>/document/", view_president_application_document, name="admin-president-application-document"),
    path("admin/president-applications/<int:application_id>/approve/", approve_president_application, name="admin-president-application-approve"),
    path("admin/president-applications/<int:application_id>/reject/", reject_president_application, name="admin-president-application-reject"),
    path("clubs/", public_club_list, name="club-list"),

    path(
        "president/events/",
        my_president_events,
        name="president-events",
    ),

    path(
        "president/events/<int:event_id>/",
        president_event_detail,
        name="president-event-detail",
    ),

]
