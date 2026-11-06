from rest_framework import serializers

from .models import ClubRegistrationRequest, Clubs


class ClubRegistrationCreateSerializer(serializers.Serializer):
    club_name = serializers.CharField(
        max_length=150,
        allow_blank=False,
        trim_whitespace=True,
    )

    category = serializers.CharField(
        max_length=100,
        allow_blank=False,
        trim_whitespace=True,
    )

    description = serializers.CharField(
        allow_blank=False,
        trim_whitespace=True,
    )

def validate_club_name(self, value):
    name = value.strip()

    # Check already registered clubs
    if Clubs.objects.filter(
        club_name__iexact=name
    ).exists():
        raise serializers.ValidationError(
            "A club with this name is already registered."
        )

    # Check pending registration applications
    if ClubRegistrationRequest.objects.filter(
        club_name__iexact=name,
        status="pending",
    ).exists():
        raise serializers.ValidationError(
            "A registration request for this club name is already pending."
        )

    return name

class ClubRegistrationReadSerializer(serializers.ModelSerializer):
    class Meta:
        model = ClubRegistrationRequest
        fields = [
            "id",
            "club_name",
            "category",
            "description",
            "status",
            "review_reason",
            "created_at",
            "reviewed_at",
            "approved_club",
        ]
        read_only_fields = fields

class ClubRegistrationReviewSerializer(serializers.Serializer):
    review_reason = serializers.CharField(
        required=False,
        allow_blank=True,
        trim_whitespace=True,
        max_length=2000,
    )


class ClubRegistrationRejectSerializer(serializers.Serializer):
    review_reason = serializers.CharField(
        required=True,
        allow_blank=False,
        trim_whitespace=True,
        max_length=2000,
    )
