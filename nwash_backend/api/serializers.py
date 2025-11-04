# from rest_framework import serializers
# from .models import Session, Media, Note
# from .models import UserProfile

# class MediaSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Media
#         fields = ['id', 'file', 'media_type', 'uploaded_at']

# class NoteSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = Note
#         fields = ['id', 'text', 'created_at']

# class SessionSerializer(serializers.ModelSerializer):
#     media = MediaSerializer(many=True, read_only=True)
#     notes = NoteSerializer(many=True, read_only=True)

#     class Meta:
#         model = Session
#         fields = ['id', 'user', 'created_at', 'location', 'media', 'notes']
#         read_only_fields = ['user', 'created_at', 'media', 'notes']

# # UserProfile serializer
# class UserProfileSerializer(serializers.ModelSerializer):
#     class Meta:
#         model = UserProfile
#         fields = ['name', 'phone', 'custom_id']
#         read_only_fields = ['custom_id'] 


# api/serializers.py
# api/serializers.py
from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password
from .models import Session, Media, Note, UserProfile

User = get_user_model()


class UserProfileSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserProfile
        fields = ['name', 'phone', 'custom_id']
        read_only_fields = ['custom_id']


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    # Accept either first/last name or a full name field from the app
    name = serializers.CharField(write_only=True, required=False, allow_blank=True)
    phone = serializers.CharField(write_only=True, required=False, allow_blank=True)
    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = (
            'id', 'username', 'email', 'password',
            'first_name', 'last_name',
            'name', 'phone',
            'profile',
        )
        extra_kwargs = {
            'first_name': {'required': False},
            'last_name': {'required': False},
        }

    def create(self, validated_data):
        name = validated_data.pop('name', '') or ''
        phone = validated_data.pop('phone', '') or ''

        # If only a full name is provided, try to split into first/last
        first_name = validated_data.get('first_name') or (name.split(' ')[0] if name else '')
        last_name = validated_data.get('last_name') or (' '.join(name.split(' ')[1:]) if name and len(name.split(' ')) > 1 else '')

        # Ensure username is unique; if taken, append a numeric suffix
        base_username = validated_data['username']
        unique_username = base_username
        suffix = 1
        while User.objects.filter(username__iexact=unique_username).exists():
            unique_username = f"{base_username}{suffix}"
            suffix += 1

        user = User.objects.create_user(
            username=unique_username,
            email=validated_data.get('email', ''),
            first_name=first_name,
            last_name=last_name,
            is_active=True,
        )
        user.set_password(validated_data['password'])
        user.save()

        # Ensure profile exists and set fields
        profile, _ = UserProfile.objects.get_or_create(user=user)
        if name and not profile.name:
            profile.name = name
        if phone and not profile.phone:
            profile.phone = phone
        profile.save()
        return user


class MediaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Media
        fields = ['id', 'file', 'media_type', 'uploaded_at', 'session']
        read_only_fields = ['uploaded_at']


class NoteSerializer(serializers.ModelSerializer):
    class Meta:
        model = Note
        fields = ['id', 'session', 'text', 'created_at']
        read_only_fields = ['created_at']


class SessionSerializer(serializers.ModelSerializer):
    media = MediaSerializer(many=True, read_only=True)
    notes = NoteSerializer(many=True, read_only=True)

    class Meta:
        model = Session
        fields = ['id', 'user', 'created_at', 'location', 'media', 'notes']
        read_only_fields = ['user', 'created_at', 'media', 'notes']