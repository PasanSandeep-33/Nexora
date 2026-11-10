from rest_framework import serializers
from .models import PresidentApplication


class PresidentApplicationCreateSerializer(serializers.Serializer):
    club_name = serializers.CharField(max_length=150, trim_whitespace=True)
    category = serializers.CharField(max_length=100, trim_whitespace=True)
    description = serializers.CharField(max_length=2000, trim_whitespace=True)

    def validate_club_name(self, value):
        if not value.strip():
            raise serializers.ValidationError("Club name is required.")
        return value.strip()


class PresidentApplicationReadSerializer(serializers.ModelSerializer):
    applicant_name = serializers.CharField(source="applicant.full_name", read_only=True)
    applicant_email = serializers.CharField(source="applicant.email", read_only=True)
    reviewed_by_name = serializers.CharField(
        source="reviewed_by.full_name", read_only=True, allow_null=True
    )

    class Meta:
        model = PresidentApplication
        fields = [
            "id", "applicant", "applicant_name", "applicant_email",
            "reason", "club_name", "category", "description", "approved_club", "status", "review_reason", "created_at",
            "reviewed_at", "reviewed_by", "reviewed_by_name",
        ]
        read_only_fields = fields


class PresidentApplicationReviewSerializer(serializers.Serializer):
    review_reason = serializers.CharField(
        required=False, allow_blank=True, max_length=2000,
        trim_whitespace=True,
    )


class PresidentApplicationRejectSerializer(serializers.Serializer):
    review_reason = serializers.CharField(
        required=True, allow_blank=False, max_length=2000,
        trim_whitespace=True,
    )
