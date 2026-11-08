
from django.urls import path
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

urlpatterns = [
    path("events/", event_list, name="event-list"),
    path("signup/", signup, name="signup"),
    path("login/", login, name="login"),
    path("profile/", profile, name="profile"),
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
]
