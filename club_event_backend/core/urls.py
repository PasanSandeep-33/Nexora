
from django.urls import path
from .views import event_list, signup, login, profile, upload_profile_image, refresh_token, logout

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
]
