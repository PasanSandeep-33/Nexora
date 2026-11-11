"""Admin-only dashboard counts. Do not expose user totals publicly."""
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Users


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def admin_stats(request):
    if str(request.user.role).lower() != 'admin':
        return Response({'detail': 'Administrator access required.'}, status=403)
    return Response({'students': Users.objects.filter(role__iexact='student').count()})
