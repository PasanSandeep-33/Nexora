
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework import status

from .models import Events
from .serializers import EventSerializer, SignupSerializer
from django.contrib.auth.hashers import check_password
from .models import Users
from .serializers import LoginSerializer

@api_view(['GET'])
def event_list(request):
    events = Events.objects.filter(
        approval_status='approved'
    ).order_by('event_date')

    serializer = EventSerializer(events, many=True)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([AllowAny])
def signup(request):
    serializer = SignupSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()

        return Response(
            {
                'message': 'Account created successfully',
                'user_id': user.user_id,
                'email': user.email,
                'role': user.role
            },
            status=status.HTTP_201_CREATED
        )

    return Response(
        serializer.errors,
        status=status.HTTP_400_BAD_REQUEST
    )

@api_view(['POST'])
@permission_classes([AllowAny])
def login(request):
    serializer = LoginSerializer(data=request.data)

    if not serializer.is_valid():
        return Response(
            serializer.errors,
            status=status.HTTP_400_BAD_REQUEST
        )

    email = serializer.validated_data['email'].strip().lower()
    password = serializer.validated_data['password']

    user = Users.objects.filter(
        email__iexact=email
    ).first()

    if user is None or not check_password(
        password, user.password_hash
    ):
        return Response(
            {'message': 'Invalid email or password'},
            status=status.HTTP_401_UNAUTHORIZED
        )

    return Response(
        {
            'message': 'Login credentials verified successfully',
            'user': {
                'user_id': user.user_id,
                'full_name': user.full_name,
                'email': user.email,
                'role': user.role
            }
        },
        status=status.HTTP_200_OK
    )