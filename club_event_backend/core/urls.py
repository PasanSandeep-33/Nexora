from django.urls import path
from .views import event_list, signup, login, profile

urlpatterns = [
    path('events/', event_list, name='event-list'),
    path('signup/', signup, name='signup'),
    path('login/', login, name='login'),
    path('profile/', profile, name='profile'),
]
