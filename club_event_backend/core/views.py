from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Events
from .serializers import EventSerializer

@api_view(['GET'])
def event_list(request):
    events = Events.objects.filter(
        approval_status='approved'
    ).order_by('event_date')

    serializer = EventSerializer(events, many=True)
    return Response(serializer.data)


