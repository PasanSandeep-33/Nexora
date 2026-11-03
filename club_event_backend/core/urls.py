
from django.urls import path
from .views import event_list, signup, login, profile, upload_profile_image, refresh_token, logout
from .club_registration_views import (
    submit_club_registration,
    list_club_registration_requests,
    approve_club_registration,
    reject_club_registration
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
]
