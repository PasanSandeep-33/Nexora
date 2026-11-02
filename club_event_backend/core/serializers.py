
import re

from django.contrib.auth.hashers import make_password
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.db import IntegrityError, transaction

from rest_framework import serializers
from .models import Events, Users


class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Events
        fields = '__all__'


class SignupSerializer(serializers.ModelSerializer):
    email = serializers.EmailField(max_length=255)

    password = serializers.CharField(
        write_only=True,
        min_length=8,
        trim_whitespace=False
    )

    class Meta:
        model = Users
        fields = ['user_id', 'full_name', 'email', 'password']
        read_only_fields = ['user_id']

    def validate_email(self, value):
        email = value.strip().lower()

        if Users.objects.filter(email__iexact=email).exists():
            raise serializers.ValidationError(
                "This email is already registered."
            )

        return email

    def validate_password(self, value):
        if len(value) < 8:
            raise serializers.ValidationError(
                "Password must contain at least 8 characters."
            )

        if not re.search(r'[A-Z]', value):
            raise serializers.ValidationError(
                "Password must contain at least one uppercase letter."
            )

        if not re.search(r'[a-z]', value):
            raise serializers.ValidationError(
                "Password must contain at least one lowercase letter."
            )

        if not re.search(r'[0-9]', value):
            raise serializers.ValidationError(
                "Password must contain at least one number."
            )

        if not re.search(r'[^A-Za-z0-9]', value):
            raise serializers.ValidationError(
                "Password must contain at least one special character."
            )

        try:
            validate_password(value)
        except DjangoValidationError as error:
            raise serializers.ValidationError(error.messages)

        return value

    def create(self, validated_data):
        password = validated_data.pop('password')

        try:
            with transaction.atomic():
                return Users.objects.create(
                    **validated_data,
                    password_hash=make_password(password),
                    role='student'
                )
        except IntegrityError:
            raise serializers.ValidationError({
                "email": "This email is already registered."
            })


class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()

    password = serializers.CharField(
        write_only=True,
        required=True
    )
