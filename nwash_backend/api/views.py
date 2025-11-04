# # api/views.py
# from rest_framework.views import APIView
# from rest_framework.response import Response
# from rest_framework import status
# from rest_framework.permissions import AllowAny
# from django.contrib.auth import get_user_model
# from .serializers import UserSerializer

# User = get_user_model()

# class RegisterView(APIView):
#     permission_classes = [AllowAny]
    
#     def get(self, request, *args, **kwargs):
#         # Return a simple form or instructions for registration
#         return Response({
#             'message': 'Send a POST request with username, email, and password to register',
#             'example': {
#                 'username': 'newuser',
#                 'email': 'user@example.com',
#                 'password': 'securepassword123',
#                 'password2': 'securepassword123'
#             }
#         })
    
#     def post(self, request, *args, **kwargs):
#         serializer = UserSerializer(data=request.data)
#         if serializer.is_valid():
#             user = serializer.save()
#             return Response({
#                 'message': 'User registered successfully',
#                 'user_id': user.id,
#                 'email': user.email
#             }, status=status.HTTP_201_CREATED)
#         return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)




# api/views.py
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, generics, permissions
from rest_framework.parsers import MultiPartParser, FormParser
from django.contrib.auth import get_user_model
from .serializers import (
    UserSerializer,
    SessionSerializer,
    MediaSerializer,
    NoteSerializer,
)
from .models import Session, Media, Note
from rest_framework_simplejwt.views import TokenObtainPairView
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

User = get_user_model()

class RegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    # Explicitly disable authentication to avoid CSRF/session checks
    authentication_classes = []
    
    def get(self, request, *args, **kwargs):
        return Response({
            'message': 'Send a POST request with username, email, and password to register',
            'example': {
                'username': 'newuser',
                'email': 'user@example.com',
                'password': 'securepassword123',
                'password2': 'securepassword123',
                'first_name': 'Test',
                'last_name': 'User'
            }
        })
    
    def post(self, request, *args, **kwargs):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response({
                'message': 'User registered successfully',
                'user_id': user.id,
                'email': user.email
            }, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class ProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

class ServicesView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, *args, **kwargs):
        return Response({
            'services': ['Service 1', 'Service 2', 'Service 3']  # Replace with actual services
        })

class SessionListCreateView(generics.ListCreateAPIView):
    serializer_class = SessionSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        return Session.objects.filter(user=self.request.user).order_by('-created_at')
    
    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class MediaUploadView(generics.CreateAPIView):
    serializer_class = MediaSerializer
    permission_classes = [permissions.IsAuthenticated]
    parser_classes = [MultiPartParser, FormParser]

class NoteCreateView(generics.ListCreateAPIView):
    serializer_class = NoteSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        # Optionally filter by session id if provided
        session_id = self.request.query_params.get('session')
        qs = Note.objects.all().order_by('-created_at')
        if session_id:
            qs = qs.filter(session_id=session_id)
        # Only allow notes for user's own sessions
        return qs.filter(session__user=self.request.user)


class EmailOrUsernameTokenSerializer(TokenObtainPairSerializer):
    def validate(self, attrs):
        supplied_username = attrs.get('username')
        if supplied_username and '@' in supplied_username:
            # Treat the provided username as an email and look up the real username
            user = (
                User.objects.filter(email__iexact=supplied_username)
                .order_by('id')
                .first()
            )
            if user:
                attrs['username'] = user.username
        return super().validate(attrs)


class EmailOrUsernameTokenObtainPairView(TokenObtainPairView):
    serializer_class = EmailOrUsernameTokenSerializer


class PingView(APIView):
    permission_classes = [permissions.AllowAny]
    authentication_classes = []

    def get(self, request, *args, **kwargs):
        return Response({'status': 'ok'}, status=200)