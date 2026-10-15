
from django.contrib.auth.hashers import make_password
from rest_framework import serializers
from .models import Events, Users


class EventSerializer(serializers.ModelSerializer):
    class Meta:
        model = Events
        fields = '__all__'


class SignupSerializer(serializers.ModelSerializer):
    password = serializers.CharField(
        write_only=True,
        min_length=8
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

    def create(self, validated_data):
        password = validated_data.pop('password')

        return Users.objects.create(
            **validated_data,
            password_hash=make_password(password),
            role='student'
        )

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(
        write_only=True,
        required=True
    )